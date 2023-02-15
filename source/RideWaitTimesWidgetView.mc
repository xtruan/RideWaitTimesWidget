using Toybox.Application as App;
using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.System as Sys;
using Toybox.Lang as Lang;
using Toybox.Position as Pos;
using Toybox.Timer;

class RideWaitTimesWidgetView extends Ui.View {

    //hidden var posInfo = null;
    hidden var deviceSettings = null;
    hidden var isMono = false;
    hidden var isOcto = false;
    
    hidden var mStringTop = "";
    hidden var mStringBot = "";
    hidden var progressTimer = null;
    hidden var progressDots = ".";
    hidden var msgColor = Gfx.COLOR_BLUE;
    
    function initialize() {
        View.initialize();
    }

    //! Load your resources here
    function onLayout(dc as Gfx.Dc) {
        progressTimer = new Timer.Timer();
        progressTimer.start(method(:updateProgress), 1000, true);
    }
    
    function updateProgress() {
        progressDots = progressDots + ".";
        if (progressDots.length() > 3) {
            progressDots = ".";
        }
        if (progressDots.length() == 1) {
            msgColor = Gfx.COLOR_BLUE;
        } else if (progressDots.length() == 2) {
            msgColor = Gfx.COLOR_PINK;
        } else {
            msgColor = Gfx.COLOR_YELLOW;
        }
        Ui.requestUpdate();
    }

    function onHide() {
        //Pos.enableLocationEvents(Position.LOCATION_DISABLE, method(:onPosition));
    }
    //! Restore the state of the app and prepare the view to be shown
    function onShow() {
        //Pos.enableLocationEvents(Position.LOCATION_ONE_SHOT, method(:onPosition));
        deviceSettings = Sys.getDeviceSettings();
        App.getApp().requestPositionUpdate(deviceSettings);
        var deviceId = Ui.loadResource(Rez.Strings.DeviceId);
        isOcto = deviceId != null && deviceId.equals("octo");
        // only octo watches are mono... at least for now
        isMono = isOcto;
    }

    //! Update the view
    function onUpdate(dc as Gfx.Dc) {
        // Set background color
        dc.setColor( Gfx.COLOR_TRANSPARENT, Gfx.COLOR_BLACK );
        dc.clear();
        
        var pos = 0;
        pos = pos + Gfx.getFontHeight(Gfx.FONT_TINY) - 4;
        if (isOcto) {
            pos = pos + 30;
        }
        
        // Check if position is valid
        if (App.getApp().getLat() != 999 && App.getApp().getLon() != 999) {
            
            if (progressTimer != null) {
                progressTimer.stop();
            }
        
            if (deviceSettings != null && deviceSettings.isTouchScreen) {
                mStringTop = "Tap screen to";
            } else {
                mStringTop = "Press start to";
            }
            mStringBot = "load wait times";

            dc.setColor( Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT );
            
            // display navigation (position) info
            if (mStringBot.length() != 0) {
                pos = pos + Gfx.getFontHeight(Gfx.FONT_SMALL);
                dc.drawText( (dc.getWidth() / 2), pos, Gfx.FONT_MEDIUM, mStringTop, Gfx.TEXT_JUSTIFY_CENTER );
                pos = pos + Gfx.getFontHeight(Gfx.FONT_MEDIUM) - 6;
                dc.drawText( (dc.getWidth() / 2), pos, Gfx.FONT_MEDIUM, mStringBot, Gfx.TEXT_JUSTIFY_CENTER );
            }
            else {
                pos = pos + Gfx.getFontHeight(Gfx.FONT_SMALL);
                dc.drawText( (dc.getWidth() / 2), pos, Gfx.FONT_MEDIUM, mStringTop, Gfx.TEXT_JUSTIFY_CENTER );
                pos = pos + Gfx.getFontHeight(Gfx.FONT_MEDIUM) - 6;
            }
            
            var image = Ui.loadResource(Rez.Drawables.Castle);
            if (isOcto) {
                pos = pos - 75;
                dc.drawBitmap( (dc.getWidth() / 2) - 50, pos, image );
            } else {
                pos = pos + Gfx.getFontHeight(Gfx.FONT_MEDIUM) + 15;
                dc.drawBitmap( (dc.getWidth() / 2) - 30, pos, image );
            }
            
            // show position quality as dot
            //pos = pos + 70;
            pos = 10;
            var posQuality = App.getApp().getPosQuality();
            if (isMono) {
                if (posQuality == Pos.QUALITY_LAST_KNOWN) {
                    dc.setColor( Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT );
                } else {
                    dc.setColor( Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT );
                }
            } else {
                if (posQuality == Pos.QUALITY_GOOD) {
                    dc.setColor( Gfx.COLOR_GREEN, Gfx.COLOR_TRANSPARENT );
                } else if (posQuality == Pos.QUALITY_USABLE) {
                    dc.setColor( Gfx.COLOR_YELLOW, Gfx.COLOR_TRANSPARENT );
                } else if (posQuality == Pos.QUALITY_POOR) {
                    dc.setColor( Gfx.COLOR_RED, Gfx.COLOR_TRANSPARENT );
                } else if (posQuality == Pos.QUALITY_LAST_KNOWN) {
                    dc.setColor( Gfx.COLOR_BLUE, Gfx.COLOR_TRANSPARENT );
                } else {
                    dc.setColor( Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT );
                }
            }
            dc.fillCircle( (dc.getWidth() / 2), pos, 5);
            
          } else {
          
              mStringTop = "Waiting for GPS" + progressDots;
              mStringBot = "Just a sec!  : )";
              
              var offset = 0;
              if (isOcto) {
                  offset = offset + 20;
              }
            
              // display default text for no GPS
              dc.setColor( Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT );
              dc.drawText( (dc.getWidth() / 2), (dc.getHeight() / 2) - Gfx.getFontHeight(Gfx.FONT_SMALL) + offset, Gfx.FONT_SMALL, mStringTop, Gfx.TEXT_JUSTIFY_CENTER );
              dc.setColor( msgColor, Gfx.COLOR_TRANSPARENT );
              dc.drawText( (dc.getWidth() / 2), (dc.getHeight() / 2) + offset, Gfx.FONT_SMALL, mStringBot, Gfx.TEXT_JUSTIFY_CENTER );
        
        }
        
    }
   
}
