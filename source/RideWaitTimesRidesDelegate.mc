using Toybox.Application as App;
using Toybox.WatchUi as Ui;

class RideWaitTimesRidesDelegate extends Ui.Menu2InputDelegate {

    function initialize() {
        Menu2InputDelegate.initialize();
    }

    function onSelect(item) {
        App.getApp().makeRequestRides(item.getId(), method(:onReceiveRides));
    }
    
    // set up the response callback function
    function onReceiveRides(responseCode, data) {
    
       if (responseCode < 200 || responseCode >= 300) {
   	   	   App.getApp().showErrorView(responseCode);
   	   	   return;
   	   }
    
       //Get only the JSON data we are interested in and call the view class
       var menu = new Ui.Menu2({:title=>"Wait Times"});
       var delegate;
       
       var i;
       for (i = 0; i < data.get("rides").size(); i++) {
       	   //System.println(data.get("rides")[i].get("name"));
       	   
       	   var waitTime = data.get("rides")[i].get("wait_time").toString();
       	   if (waitTime.equals("9999")) {
	                waitTime = "CLOSED";
	           } else {
	           		waitTime = waitTime + " mins";
	           }
	       menu.addItem(
	           new Ui.MenuItem(
	               waitTime,
	               data.get("rides")[i].get("name"),
	               i,
	               {}
	           )
	       );
       }
       
       if (i == 0) {
       	   menu.addItem(
	           new Ui.MenuItem(
	               "No Rides",
	               "Reporting Status",
	               i,
	               {}
	           )
	       );
       }
       
       delegate = new DummyMenu2Delegate(); // a WatchUi.Menu2InputDelegate
       Ui.pushView(menu, delegate, Ui.SLIDE_IMMEDIATE);
       //Ui.switchToView(new GarminJSONWebRequestWidgetView(data.get("park").get("id"),"",data.get("park").get("name")), null, Ui.SLIDE_IMMEDIATE);
   }
}