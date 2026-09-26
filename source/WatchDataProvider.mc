import Toybox.Activity;
import Toybox.ActivityMonitor;
import Toybox.Lang;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;

// Acquires Garmin metrics once per render cycle into a WatchData snapshot.
class WatchDataProvider {

    function initialize() {
    }

    function getSnapshot() as WatchData {
        var data = new WatchData();

        var clockTime = System.getClockTime();
        data.hour = clockTime.hour;
        data.minute = clockTime.min;
        data.dateText = formatDate();

        data.heartRate = readHeartRate();
        data.battery = (System.getSystemStats().battery + 0.5).toNumber();

        var info = ActivityMonitor.getInfo();
        if (info != null) {
            data.steps = info.steps;
            data.stepGoal = info.stepGoal;
            data.distanceCm = info.distance;
            data.calories = info.calories;
        }

        return data;
    }

    private function formatDate() as String {
        var info = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);
        var dayOfWeek = (info.day_of_week as String).toUpper();
        var month = (info.month as String).toUpper();
        return Lang.format("$1$ $2$ $3$", [dayOfWeek, info.day, month]);
    }

    private function readHeartRate() as Number? {
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

        return hrValue;
    }

}
