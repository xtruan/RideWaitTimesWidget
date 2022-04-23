import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Position;

// dev/prod URLs
//const URL_BASE = "https://qlvln5qtf4.execute-api.us-east-2.amazonaws.com/dev";
const URL_BASE = "https://se82gn6gng.execute-api.us-east-2.amazonaws.com/prod";

const ROUTE_PARKS = "/parks";
const ROUTE_RIDES = "/waits";

(:glance)
class RideWaitTimesWidgetApp extends Application.AppBase {

//  Magic Kingdom lat/long
//	hidden var mLat = 28.417663;
//	hidden var mLon = -81.581212;

	hidden var mLat = 999;
	hidden var mLon = 999;

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

    function initialize() {
        AppBase.initialize();
    }

    // onStart() is called on application start up
    function onStart(state as Dictionary?) as Void {
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

        Communications.makeWebRequest(url, params, options, callback);
    }
    
    function makeRequestRides(id, callback) {
        var url = URL_BASE + ROUTE_RIDES;
        var params = { // set the parameters
          "id" => id.toString()
        };
        var options = {
          :method => Communications.HTTP_REQUEST_METHOD_GET,
          :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };

        Communications.makeWebRequest(url, params, options, callback);
    }
	
	
	function showErrorView(errorCode) {
	    var menu = new WatchUi.Menu2({:title=>"Error"});
        var delegate;
       
   	    menu.addItem(
            new WatchUi.MenuItem(
                "Check Connection",
                "Code: " + errorCode.toString(),
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