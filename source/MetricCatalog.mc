import Toybox.Lang;
import Toybox.WatchUi;

// Central metric formatting + progress + icon binding from WatchData.
// Adding a metric: extend MetricIds, icons, this catalog, and settings.
module MetricCatalog {

    const HR_GAUGE_MIN = 40;
    const HR_GAUGE_MAX = 190;

    // Fill PRIMARY slot: value, progress, metric-owned icon
    function fillPrimary(
        metricId as Number,
        data as WatchData,
        out as MetricRender,
        icons as MetricIconCache
    ) as Void {
        var id = MetricCompatibility.defaultPrimary(metricId);
        out.metricId = id;
        out.label = "";
        out.icon = icons.iconFor(id);

        if (id == MetricIds.HEART_RATE) {
            if (data.heartRate == null) {
                out.value = "--";
                out.progress = 0.0;
            } else {
                out.value = (data.heartRate as Number).format("%d");
                out.progress = heartRateProgress(data.heartRate as Number);
            }
            return;
        }

        if (id == MetricIds.STEPS) {
            if (data.steps == null) {
                out.value = "--";
                out.progress = 0.0;
            } else {
                out.value = formatThousands(data.steps as Number);
                out.progress = stepsProgress(data);
            }
            return;
        }

        // BATTERY
        out.value = data.battery.format("%d") + "%";
        out.progress = batteryProgress(data.battery);
    }

    // Fill SECONDARY slot: value + unit + metric-owned icon
    function fillSecondary(
        metricId as Number,
        data as WatchData,
        out as MetricRender,
        icons as MetricIconCache
    ) as Void {
        var id = MetricCompatibility.defaultSecondary(metricId);
        out.metricId = id;
        out.progress = 0.0;
        out.icon = icons.iconFor(id);

        if (id == MetricIds.CALORIES) {
            if (data.calories == null) {
                out.value = "--";
            } else {
                out.value = (data.calories as Number).format("%d");
            }
            out.label = "CAL";
            return;
        }

        // DISTANCE
        if (data.distanceCm == null) {
            out.value = "--";
        } else {
            var km = (data.distanceCm as Number).toFloat() / 100000.0;
            out.value = km.format("%.1f");
        }
        out.label = "KM";
    }

    function usesAccentIcon(metricId as Number) as Boolean {
        return metricId == MetricIds.HEART_RATE;
    }

    function heartRateProgress(hrValue as Number) as Float {
        var span = HR_GAUGE_MAX - HR_GAUGE_MIN;
        var ratio = (hrValue - HR_GAUGE_MIN).toFloat() / span.toFloat();
        if (ratio < 0.0) {
            return 0.0;
        }
        if (ratio > 1.0) {
            return 1.0;
        }
        return ratio;
    }

    function stepsProgress(data as WatchData) as Float {
        if ((data.steps == null) || (data.stepGoal == null)) {
            return 0.0;
        }
        var goal = data.stepGoal as Number;
        if (goal <= 0) {
            return 0.0;
        }
        var ratio = (data.steps as Number).toFloat() / goal.toFloat();
        if (ratio > 1.0) {
            return 1.0;
        }
        return ratio;
    }

    function batteryProgress(pct as Number) as Float {
        var ratio = pct.toFloat() / 100.0;
        if (ratio < 0.0) {
            return 0.0;
        }
        if (ratio > 1.0) {
            return 1.0;
        }
        return ratio;
    }

    function formatThousands(value as Number) as String {
        if (value < 1000) {
            return value.format("%d");
        }
        if (value < 1000000) {
            var thousands = value / 1000;
            var remainder = value % 1000;
            return thousands.format("%d") + "," + remainder.format("%03d");
        }
        var millions = value / 1000000;
        var rest = value % 1000000;
        var thousands = rest / 1000;
        var remainder = rest % 1000;
        return millions.format("%d")
            + "," + thousands.format("%03d")
            + "," + remainder.format("%03d");
    }

}
