using Toybox.Application as App;
using Toybox.WatchUi as Ui;

class RideWaitTimesRidesDelegate extends Ui.Menu2InputDelegate {

    function initialize() {
        Menu2InputDelegate.initialize();
    }

    function onSelect(item) {
        App.getApp().makeRequestRides(item.getId(), method(:onReceiveRides));
        
        var progressBar = new Ui.ProgressBar(
            "Loading waits...",
            null
        );
        Ui.pushView(
            progressBar,
            null,
            Ui.SLIDE_IMMEDIATE
        );
    }
    
    // set up the response callback function
    function onReceiveRides(responseCode, data) {
    
       App.getApp().setRequestInProgress(false);
    
       // check response code
       if (responseCode < 200 || responseCode >= 300) {
                 App.getApp().showErrorView(responseCode);
                 return;
          }
    
       //Get only the JSON data we are interested in and call the view class
       var menu = new Ui.Menu2({:title=>"Wait Times"});
       var delegate;
       
       var i;
       for (i = 0; i < data.size(); i++) {
              //System.println(data[i].get("n"));
              
              var waitTime = data[i].get("w").toString();
              if (waitTime.equals("-1")) {
                    waitTime = "CLOSED";
               } else {
                    waitTime = waitTime + " mins";
               }
           menu.addItem(
               new Ui.MenuItem(
                   waitTime,
                   data[i].get("n"),
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
       
       Ui.popView(Ui.SLIDE_IMMEDIATE); // dismiss progress
       Ui.pushView(menu, delegate, Ui.SLIDE_IMMEDIATE); // show menu
       //Ui.switchToView(new GarminJSONWebRequestWidgetView(data.get("park").get("id"),"",data.get("park").get("name")), null, Ui.SLIDE_IMMEDIATE);
   }
}