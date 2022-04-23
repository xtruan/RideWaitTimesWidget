using Toybox.Application as App;
using Toybox.WatchUi as Ui;

class RideWaitTimesParksDelegate extends Ui.BehaviorDelegate {

    function initialize() {
        BehaviorDelegate.initialize();
    }

    function onMenu() {
    	var lat = App.getApp().getLat();
    	var lon = App.getApp().getLon();
    	if (lat != 999 && lon != 999) {
        	App.getApp().makeRequestParks(20, method(:onReceiveParks));
        } else {
        	onListRegions();
        }
    }
    
    function onKey(key) {
        if (key.getKey() == Ui.KEY_UP || key.getKey() == Ui.KEY_ENTER) {
            onMenu();
        }
    }
    
    function onSelect() {
    	onMenu();
    }
    
   // Set up the response callback function
   function onReceiveParks(responseCode, data) {
   	   
   	   if (responseCode < 200 || responseCode >= 300) {
   	   	   App.getApp().showErrorView(responseCode);
   	   	   return;
   	   }
   	   
       // Get only the JSON data we are interested in and call the view class
       var menu = new Ui.Menu2({:title=>"Select Park"});
       var delegate;
       
       var i;
       for (i = 0; i < data.get("parks").size(); i++) {
       	   //System.println(data.get("parks")[i].get("name"));
       	   
       	   var firstPart = data.get("parks")[i].get("name");
       	   var secondPart = "";
       	   var index = firstPart.find(" ");
       	   if (index != null) {
       	   	   secondPart = firstPart.substring(index+1, firstPart.length());
       	       firstPart = firstPart.substring(0, index);
       	   }
       	   
       	   if (firstPart.length() < 4) {
       	   	   var thirdPart = "";
       	   	   index = secondPart.find(" ");
       	   	   if (index != null) {
	       	   	   thirdPart = secondPart.substring(index+1, secondPart.length());
	       	       secondPart = secondPart.substring(0, index);
	       	       firstPart = firstPart + " " + secondPart;
	       	       secondPart = thirdPart;
	       	       thirdPart = null;
	       	   }
       	   }
       	   
	       menu.addItem(
	           new Ui.MenuItem(
	               firstPart,
	               secondPart,
	               data.get("parks")[i].get("id"),
	               {}
	           )
	       );
       }
       
       if (i == 0) {
       	   menu.addItem(
	           new Ui.MenuItem(
	               "No Parks",
	               "Reporting Status",
	               i,
	               {}
	           )
	       );
       }
       
       delegate = new RideWaitTimesRidesDelegate(); // a WatchUi.Menu2InputDelegate
       Ui.pushView(menu, delegate, Ui.SLIDE_IMMEDIATE);
   }
   
   function onListRegions() {
       var menu = new Ui.Menu2({:title=>"Select Region"});
       var delegate;
       	   
       menu.addItem(
           new Ui.MenuItem(
               "North America",
               "Florida (East)",
               [28.417663, -81.581212], // Magic Kingdom
               {}
           )
       );
       
       menu.addItem(
           new Ui.MenuItem(
               "North America",
               "California (West)",
               [33.8104856, -117.9190001], // Disneyland
               {}
           )
       );
       
       menu.addItem(
           new Ui.MenuItem(
               "North America",
               "Illinois (North)",
               [42.369997, -87.935794], // Six Flags Great America
               {}
           )
       );
       
       menu.addItem(
           new Ui.MenuItem(
               "North America",
               "Texas (South)",
               [32.7557, -97.070222], // Six Flags Over Texas
               {}
           )
       );
       
       menu.addItem(
           new Ui.MenuItem(
               "Europe",
               "England",
               [52.9874651, -1.8864769], // Alton Towers
               {}
           )
       );
       
       menu.addItem(
           new Ui.MenuItem(
               "Europe",
               "Mainland",
               [53.0236683, 9.8781907], // Heide Park
               {}
           )
       );
       
       menu.addItem(
           new Ui.MenuItem(
               "Asia",
               "",
               [35.634848, 139.879295], // Tokyo Disney Magic Kingdom
               {}
           )
       );
       
       delegate = new RegionsListMenu2Delegate(method(:onMenu)); // a WatchUi.Menu2InputDelegate
       Ui.pushView(menu, delegate, Ui.SLIDE_IMMEDIATE);
   }
}

class RegionsListMenu2Delegate extends Ui.Menu2InputDelegate {
    
    hidden var mCallback;
    
    function initialize(callback) {
    	mCallback = callback;
        Menu2InputDelegate.initialize();
    }

    function onSelect(item) {
        //System.println(item.getId());
        App.getApp().setLat(item.getId()[0]);
        App.getApp().setLon(item.getId()[1]);
        
        mCallback.invoke();
    }
}