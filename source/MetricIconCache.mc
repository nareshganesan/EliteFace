import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

// Loads metric icons once; maps MetricIds -> BitmapResource.
class MetricIconCache {

    private var _heart as BitmapResource?;
    private var _steps as BitmapResource?;
    private var _battery as BitmapResource?;
    private var _distance as BitmapResource?;
    private var _calories as BitmapResource?;
    private var _loggedSizes as Boolean;

    function initialize() {
        _heart = null;
        _steps = null;
        _battery = null;
        _distance = null;
        _calories = null;
        _loggedSizes = false;
    }

    function load() as Void {
        _heart = WatchUi.loadResource(Rez.Drawables.IconHeart) as BitmapResource;
        _steps = WatchUi.loadResource(Rez.Drawables.IconSteps) as BitmapResource;
        _battery = WatchUi.loadResource(Rez.Drawables.IconBattery) as BitmapResource;
        _distance = WatchUi.loadResource(Rez.Drawables.IconDistance) as BitmapResource;
        _calories = WatchUi.loadResource(Rez.Drawables.IconCalories) as BitmapResource;
        logBitmapSizesOnce();
    }

    function iconFor(metricId as Number) as BitmapResource? {
        if (metricId == MetricIds.HEART_RATE) {
            return _heart;
        }
        if (metricId == MetricIds.STEPS) {
            return _steps;
        }
        if (metricId == MetricIds.BATTERY) {
            return _battery;
        }
        if (metricId == MetricIds.DISTANCE) {
            return _distance;
        }
        if (metricId == MetricIds.CALORIES) {
            return _calories;
        }
        return null;
    }

    private function logBitmapSizesOnce() as Void {
        if (_loggedSizes) {
            return;
        }
        _loggedSizes = true;
        logOne("Heart", _heart);
        logOne("Steps", _steps);
        logOne("Battery", _battery);
        logOne("Distance", _distance);
        logOne("Calories", _calories);
    }

    private function logOne(name as String, bitmap as BitmapResource?) as Void {
        if (bitmap == null) {
            System.println("IconBitmap " + name + ": null");
            return;
        }
        System.println(
            "IconBitmap " + name + ": " + bitmap.getWidth() + "x" + bitmap.getHeight()
        );
    }

}
