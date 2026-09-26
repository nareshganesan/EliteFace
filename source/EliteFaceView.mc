import Toybox.Activity;
import Toybox.ActivityMonitor;
import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.WatchUi;

class EliteFaceView extends WatchUi.WatchFace {

    function initialize() {
        WatchFace.initialize();
    }

    // Load your resources here
    function onLayout(dc as Dc) as Void {
        // Direct Dc rendering — no XML layout.
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() as Void {
    }

    // Update the view
    function onUpdate(dc as Dc) as Void {
        var width = dc.getWidth();
        var height = dc.getHeight();
        var centerX = width / 2;

        // Black background
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        // --- Time (upper-middle, large, centered) ---
        var timeString = formatTime();
        var timeY = (height * 28) / 100;
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            centerX,
            timeY,
            Graphics.FONT_NUMBER_HOT,
            timeString,
            Graphics.TEXT_JUSTIFY_CENTER
        );

        // --- Date (FRI 26), centered below time ---
        var dateString = formatDate();
        var dateY = timeY + Graphics.getFontHeight(Graphics.FONT_NUMBER_HOT) + 4;
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            centerX,
            dateY,
            Graphics.FONT_MEDIUM,
            dateString,
            Graphics.TEXT_JUSTIFY_CENTER
        );

        // --- Lower metrics row ---
        var metricsY = (height * 68) / 100;
        var sideMargin = (width * 18) / 100;

        // Heart rate — lower-left
        var hrString = formatHeartRate();
        dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            sideMargin,
            metricsY,
            Graphics.FONT_TINY,
            "HR",
            Graphics.TEXT_JUSTIFY_LEFT
        );
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            sideMargin,
            metricsY + Graphics.getFontHeight(Graphics.FONT_TINY),
            Graphics.FONT_SMALL,
            hrString,
            Graphics.TEXT_JUSTIFY_LEFT
        );

        // Battery — lower-right ("84% BAT")
        var batteryString = formatBattery();
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            width - sideMargin,
            metricsY + Graphics.getFontHeight(Graphics.FONT_TINY),
            Graphics.FONT_SMALL,
            batteryString,
            Graphics.TEXT_JUSTIFY_RIGHT
        );

        // Steps — centered below HR / Battery
        var stepsY = metricsY + Graphics.getFontHeight(Graphics.FONT_TINY)
            + Graphics.getFontHeight(Graphics.FONT_SMALL) + 10;
        var stepsString = formatSteps();
        dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            centerX,
            stepsY,
            Graphics.FONT_TINY,
            "STEPS",
            Graphics.TEXT_JUSTIFY_CENTER
        );
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            centerX,
            stepsY + Graphics.getFontHeight(Graphics.FONT_TINY),
            Graphics.FONT_SMALL,
            stepsString,
            Graphics.TEXT_JUSTIFY_CENTER
        );
    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() as Void {
    }

    // The user has just looked at their watch. Timers and animations may be started here.
    function onExitSleep() as Void {
    }

    // Terminate any active timers and prepare for slow updates.
    function onEnterSleep() as Void {
    }

    // Format clock time, respecting device 12/24h and UseMilitaryFormat.
    private function formatTime() as String {
        var timeFormat = "$1$:$2$";
        var clockTime = System.getClockTime();
        var hours = clockTime.hour;

        if (!System.getDeviceSettings().is24Hour) {
            // 12-hour clock: 0 -> 12, 13-23 -> 1-11, 12 stays 12
            if (hours == 0) {
                hours = 12;
            } else if (hours > 12) {
                hours = hours - 12;
            }
        } else {
            if (Application.Properties.getValue("UseMilitaryFormat")) {
                timeFormat = "$1$$2$";
                hours = hours.format("%02d");
            }
        }

        return Lang.format(timeFormat, [hours, clockTime.min.format("%02d")]);
    }

    // Format date as "FRI 26"
    private function formatDate() as String {
        var info = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);
        var dayOfWeek = (info.day_of_week as String).toUpper();
        return Lang.format("$1$ $2$", [dayOfWeek, info.day]);
    }

    // Current HR from Activity.Info, else most recent ActivityMonitor sample.
    private function formatHeartRate() as String {
        var hrValue = null as Number?;

        var activityInfo = Activity.getActivityInfo();
        if (activityInfo != null) {
            hrValue = activityInfo.currentHeartRate;
        }

        if (hrValue == null) {
            var hrIterator = ActivityMonitor.getHeartRateHistory(1, true);
            if (hrIterator != null) {
                var sample = hrIterator.next();
                if ((sample != null)
                    && (sample.heartRate != ActivityMonitor.INVALID_HR_SAMPLE)) {
                    hrValue = sample.heartRate;
                }
            }
        }

        if (hrValue == null) {
            return "--";
        }
        return hrValue.format("%d");
    }

    // Battery as "84% BAT"
    private function formatBattery() as String {
        var battery = System.getSystemStats().battery;
        var pct = (battery + 0.5).toNumber();
        return pct.format("%d") + "% BAT";
    }

    // Today's step count, or "--" if unavailable
    private function formatSteps() as String {
        var info = ActivityMonitor.getInfo();
        if ((info == null) || (info.steps == null)) {
            return "--";
        }
        return (info.steps as Number).format("%d");
    }

}
