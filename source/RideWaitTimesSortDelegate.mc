using Toybox.Application as App;
using Toybox.WatchUi as Ui;

class RideWaitTimesSortDelegate extends Ui.Menu2InputDelegate {

    function initialize() {
        Menu2InputDelegate.initialize();
    }

    function onSelect(item) {
       var menu = new Ui.Menu2({:title=>"Sort By"});
       var delegate;
       var id = item.getId().toString();
       
       menu.addItem(
           new Ui.MenuItem(
               "High to Low",
               "Wait Time",
               [id, "l"], // l == long
               {}
           )
       );
       
       menu.addItem(
           new Ui.MenuItem(
               "Low to High",
               "Wait Time",
               [id, "s"], // s == short
               {}
           )
       );
       
       menu.addItem(
           new Ui.MenuItem(
               "A to Z",
               "Attraction Name",
               [id, "a"], // a == letter a first
               {}
           )
       );
       
       menu.addItem(
           new Ui.MenuItem(
               "Z to A",
               "Attraction Name",
               [id, "z"], // z == letter z first
               {}
           )
       );
       
       delegate = new RideWaitTimesRidesDelegate(); // a WatchUi.Menu2InputDelegate
       Ui.pushView(menu, delegate, Ui.SLIDE_IMMEDIATE);
    }
}