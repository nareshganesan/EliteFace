import Toybox.Lang;

// One-frame snapshot of watch-face metrics. Raw values only — no formatting.
class WatchData {

    var hour as Number;
    var minute as Number;
    var dateText as String;
    var heartRate as Number?;
    var steps as Number?;
    var stepGoal as Number?;
    var battery as Number;
    var distanceCm as Number?;
    var calories as Number?;

    function initialize() {
        hour = 0;
        minute = 0;
        dateText = "";
        heartRate = null;
        steps = null;
        stepGoal = null;
        battery = 0;
        distanceCm = null;
        calories = null;
    }

}
