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
const REUSE_POS_THRESHOLD_SEC = 60;

(:glance)
class RideWaitTimesWidgetApp extends Application.AppBase {

	hidden var mLat = 999;
	hidden var mLon = 999;
	
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
	
	function setRequestInProgress(requestInProgress) {
		mRequestInProgress = requestInProgress;
		//System.println("set request: " + mRequestInProgress.toString());
	}
	
	function isRequestInProgress() {
	    //System.println("is request: " + mRequestInProgress.toString());
		return mRequestInProgress;
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
    		var now = Time.now().value();
    		var delta = now - lastPos[0];
    		if (delta < 0) {
    			delta = delta * -1;
    		}
    		// if the time difference is less than threshold, use it
    		//System.println(delta);
    		if (delta < REUSE_POS_THRESHOLD_SEC) {
    			setLat(lastPos[1]);
    			setLon(lastPos[2]);
    		}
    	}
    	
    	requestPositionUpdate();
    }
    
    function requestPositionUpdate() {
    	Position.enableLocationEvents(Position.LOCATION_ONE_SHOT, method(:onPosition));
    }
    
    // position change callback
    function onPosition(info) {
        
		var degrees = info.position.toDegrees();
        setLat(degrees[0]);
		setLon(degrees[1]);
		
		var now = Time.now().value();
		Application.Storage.setValue(REUSE_POS_STORAGE_KEY, [now, getLat(), getLon()]);
		
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
    
    function makeRequestParks(limit, callback) {
        
        if (isRequestInProgress()) {
        	//System.println("request in progress!");
    		return;
    	}
    	
        var url = URL_BASE + ROUTE_PARKS;
        var params = { // set the parameters
          "lat" => getLat().toString(),
          "lon" => getLon().toString()
          //"limit" => limit.toString()
        };
        var options = {
          :method => Communications.HTTP_REQUEST_METHOD_GET,
          :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };

		setRequestInProgress(true);
        Communications.makeWebRequest(url, params, options, callback);
    }
    
    function makeRequestRides(id, callback) {
    	
    	if (isRequestInProgress()) {
    	    //System.println("request in progress!");
    		return;
    	}
    	
        var url = URL_BASE + ROUTE_RIDES;
        var params = { // set the parameters
          "id" => id.toString()
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
       
        var errorMsg = "";
        if (errorCode == Communications.BLE_CONNECTION_UNAVAILABLE) {
            errorMsg = "Connection Unavailable";
        } else {
            errorMsg = "Code: " + errorCode.toString();
        }
   	    menu.addItem(
            new WatchUi.MenuItem(
                "Check Connection",
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