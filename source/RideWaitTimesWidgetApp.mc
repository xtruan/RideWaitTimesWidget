using Toybox.System;
using Toybox.Application;
using Toybox.Lang;
using Toybox.WatchUi;
using Toybox.Position;
using Toybox.Time;

// dev/prod URLs
//const URL_BASE = "https://qlvln5qtf4.execute-api.us-east-2.amazonaws.com/dev";
const URL_BASE = "https://se82gn6gng.execute-api.us-east-2.amazonaws.com/prod";

const ROUTE_PARKS = "/parks";
const ROUTE_RIDES = "/waits";

const REUSE_POS_STORAGE_KEY = "lastPos";
const REUSE_POS_THRESHOLD_SEC = 3600 * 8; // 8 hours

(:glance)
class RideWaitTimesWidgetApp extends Application.AppBase {

    hidden var mLat = 999;
    hidden var mLon = 999;
    hidden var mPosQuality = Position.QUALITY_LAST_KNOWN;
    hidden var mPosTime = -1;
    
    hidden var mRequestInProgress = false;

    function setLat(lat) {
        mLat = lat;
    }
    
    function getLat() {
        return mLat;
    }
    
    function setLon(lon) {
        mLon = lon;
    }
    
    function getLon() {
        return mLon;
    }
    
    function setPosQuality(posQuality) {
        mPosQuality = posQuality;
    }
    
    function getPosQuality() {
        return mPosQuality;
    }
    
    function setPosTime(posTime) {
        mPosTime = posTime;
    }
    
    function getPosTime() {
        return mPosTime;
    }
    
    function setRequestInProgress(requestInProgress) {
        mRequestInProgress = requestInProgress;
        //System.println("set request: " + mRequestInProgress.toString());
    }
    
    function isRequestInProgress() {
        //System.println("is request: " + mRequestInProgress.toString());
        return mRequestInProgress;
    }
    
    function calculatePosAge() {
        var lastTime = getPosTime();
        // only valid if time is positive
        if (lastTime > 0) {
            return calculateDelta(lastTime);
        } else {
            return lastTime;
        }
    }
    
    function calculateDelta(lastTime) {
        // compare current time with last time, and take abs value
        var now = Time.now().value();
        var delta = now - lastTime;
        if (delta < 0) {
            delta = delta * -1;
        }
        return delta;
    }

    function initialize() {
        AppBase.initialize();
    }

    // onStart() is called on application start up
    function onStart(state as Dictionary?) as Void {
        // check for stored position
        var lastPos = Application.Storage.getValue(REUSE_POS_STORAGE_KEY);
        //System.println(lastPos);
        if (lastPos != null && lastPos[0] != null && lastPos[1] != null && lastPos[2] != null) {
            // compare current time with last time, and take abs value
            var delta = calculateDelta(lastPos[0]);
            // if the time difference is less than threshold, use it
            //System.println(delta);
            if (delta < REUSE_POS_THRESHOLD_SEC) {
                setLat(lastPos[1]);
                setLon(lastPos[2]);
                setPosTime(lastPos[0]);
                // refresh stored position with time == now
                //Application.Storage.setValue(REUSE_POS_STORAGE_KEY, [now, getLat(), getLon()]);
            }
        }
        
        //var deviceSettings = Sys.getDeviceSettings();
        //requestPositionUpdate(deviceSettings);
    }
    
    function requestPositionUpdate(deviceSettings) {
        var ver = deviceSettings.monkeyVersion;
        // custom constellations only in CIQ >= 3.2.0
        if ( ver != null && ver[0] != null && ver[1] != null && 
            ( (ver[0] == 3 && ver[1] >= 2) || ver[0] > 3 ) ) {
            if (enablePositioningWithConstellations([
                    Position.CONSTELLATION_GPS,
                    Position.CONSTELLATION_GLONASS, 
                    Position.CONSTELLATION_GALILEO
            ])) {
                System.println("Constellations: GPS/GLO/GAL");
                return true;
            }
            if (enablePositioningWithConstellations([
                    Position.CONSTELLATION_GPS,
                    Position.CONSTELLATION_GLONASS
            ])) {
                System.println("Constellations: GPS/GLO");
                return true;
            }
            if (enablePositioningWithConstellations([
                    Position.CONSTELLATION_GPS,
                    Position.CONSTELLATION_GALILEO
            ])) {
                System.println("Constellations: GPS/GAL");
                return true;
            }
            if (enablePositioningWithConstellations([
                    Position.CONSTELLATION_GPS
            ])) {
                System.println("Constellation: GPS");
                return true;
            }
        } else {
            Position.enableLocationEvents(Position.LOCATION_ONE_SHOT, method(:onPosition));
            System.println("Constellation: GPS (Legacy Mode)");
        }
        return true;
    }
    
    function enablePositioningWithConstellations(constellations) {
        var success = false;
        try {
            Position.enableLocationEvents({
                    :acquisitionType => Position.LOCATION_ONE_SHOT,
                    :constellations => constellations
                },
                method(:onPosition)
            );
            success = true;
        } catch (ex) {
            System.println(ex.getErrorMessage() + ": " + constellations.toString());
            success = false;
        }
        return success;
    }
    
    // position change callback
    function onPosition(info) {
        // set position info
        var degrees = info.position.toDegrees();
        setLat(degrees[0]);
        setLon(degrees[1]);
        setPosQuality(info.accuracy);
        // set time info
        var now = Time.now().value();
        setPosTime(now);
        // write to storage
        Application.Storage.setValue(REUSE_POS_STORAGE_KEY, [getPosTime(), getLat(), getLon()]);
        // refresh
        WatchUi.requestUpdate();
    }

    // onStop() is called when your application is exiting
    function onStop(state as Dictionary?) as Void {
        Position.enableLocationEvents(Position.LOCATION_DISABLE, method(:onPosition));
    }
    
    function getGlanceView() {
        return [ new RideWaitTimesGlanceView() ];
    }

    // Return the initial view of your application here
    function getInitialView() as Array<Views or InputDelegates>? {
        return [ new RideWaitTimesWidgetView(), new RideWaitTimesParksDelegate() ] as Array<Views or InputDelegates>;
    }
    
    function getFreeMemKb() {
        var freeMem = -1;
        var stats = System.getSystemStats();
        if (stats has :freeMemory) {
            freeMem = stats.freeMemory / 1000;
        }
        return freeMem;
    }
    
    function makeRequestParks(limit, callback) {
        
        if (isRequestInProgress()) {
            //System.println("request in progress!");
            return;
        }
        
        var url = URL_BASE + ROUTE_PARKS;
        var params = { // set the parameters
          "lat" => getLat().toString(),
          "lon" => getLon().toString(),
          "min" => "p", // shorten JSON keys to single character
          //"lmt" => limit.toString(),
          "mem" => getFreeMemKb(),
          "age" => calculatePosAge()
        };
        var options = {
          :method => Communications.HTTP_REQUEST_METHOD_GET,
          :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };

        setRequestInProgress(true);
        Communications.makeWebRequest(url, params, options, callback);
    }
    
    function makeRequestRides(opts, callback) {
        
        if (isRequestInProgress()) {
            //System.println("request in progress!");
            return;
        }
        
        var url = URL_BASE + ROUTE_RIDES;
        var params = { // set the parameters
          "id" => opts[0],
          "srt" => opts[1],
          "min" => "w", // shorten JSON keys to single character
          "mem" => getFreeMemKb()
        };
        var options = {
          :method => Communications.HTTP_REQUEST_METHOD_GET,
          :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };

        setRequestInProgress(true);
        Communications.makeWebRequest(url, params, options, callback);
    }
    
    
    function showErrorView(errorCode) {
        var menu = new WatchUi.Menu2({:title=>"Error"});
        var delegate;
       
        var errorHdg = "Phone";
        var errorMsg = "";
        if (errorCode == Communications.BLE_CONNECTION_UNAVAILABLE) {
            errorMsg = "Not connected";
        } else if (errorCode == Communications.BLE_HOST_TIMEOUT) {
            errorMsg = "Did not respond";
        } else if (errorCode == Communications.BLE_SERVER_TIMEOUT) {
            errorMsg = "Data too slow";
        } else if (errorCode == Communications.NETWORK_REQUEST_TIMED_OUT) {
            errorHdg = "Network";
            errorMsg = "Data too slow";
        } else {
            errorHdg = "Connection";
            errorMsg = "Error code: " + errorCode.toString();
        }
        menu.addItem(
            new WatchUi.MenuItem(
                errorHdg,
                errorMsg,
                errorCode,
                {}
            )
        );
       
        delegate = new DummyMenu2Delegate(); // a WatchUi.Menu2InputDelegate
        WatchUi.pushView(menu, delegate, WatchUi.SLIDE_IMMEDIATE);
    }
}

function getApp() as RideWaitTimesWidgetApp {
    return Application.getApp() as RideWaitTimesWidgetApp;
}

class DummyMenu2Delegate extends WatchUi.Menu2InputDelegate {
    function initialize() {
        Menu2InputDelegate.initialize();
    }

    function onSelect(item) {
        //System.println(item.getId());
    }
}
