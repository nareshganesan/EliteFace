import Toybox.Lang;
import Toybox.WatchUi;

// Reusable render payload for one metric slot (filled in place each frame).
class MetricRender {

    var metricId as Number;
    var value as String;
    var label as String;   // secondary unit; unused for primary icon complications
    var progress as Float; // primary ring 0..1; unused for secondary
    var icon as BitmapResource?;

    function initialize() {
        metricId = MetricIds.HEART_RATE;
        value = "--";
        label = "";
        progress = 0.0;
        icon = null;
    }

}
