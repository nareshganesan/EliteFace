import Toybox.Lang;

// Stable metric identifiers — do not use display strings as IDs.
// Values match Properties / settings listEntry values.
module MetricIds {
    enum {
        HEART_RATE = 0,
        STEPS = 1,
        BATTERY = 2,
        DISTANCE = 3,
        CALORIES = 4
        // Future: FLOORS, ACTIVE_MINUTES, BODY_BATTERY, ...
    }
}

// Slot type compatibility — expand when new metrics are added.
module MetricCompatibility {

    function isPrimaryCompatible(metricId as Number) as Boolean {
        return (metricId == MetricIds.HEART_RATE)
            || (metricId == MetricIds.STEPS)
            || (metricId == MetricIds.BATTERY);
    }

    function isSecondaryCompatible(metricId as Number) as Boolean {
        return (metricId == MetricIds.DISTANCE)
            || (metricId == MetricIds.CALORIES);
    }

    function defaultPrimary(metricId as Number) as Number {
        if (isPrimaryCompatible(metricId)) {
            return metricId;
        }
        return MetricIds.HEART_RATE;
    }

    function defaultSecondary(metricId as Number) as Number {
        if (isSecondaryCompatible(metricId)) {
            return metricId;
        }
        return MetricIds.DISTANCE;
    }

}
