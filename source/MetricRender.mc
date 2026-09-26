import Toybox.Lang;

// Reusable render payload for one metric slot (filled in place each frame).
class MetricRender {

    var value as String;
    var label as String;   // primary short label, or secondary unit
    var progress as Float; // primary arc 0..1; unused for secondary

    function initialize() {
        value = "--";
        label = "";
        progress = 0.0;
    }

}
