import Toybox.Activity;
import Toybox.ActivityMonitor;
import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.WatchUi;

class EliteFaceView extends WatchUi.WatchFace {

    // -------------------------------------------------------------------------
    // Layout bands — 454x454 FR965 circular safe content
    // -------------------------------------------------------------------------
    private const BAND_STATUS_Y = 32;
    private const BAND_DATE_Y = 58;
    private const BAND_TIME_Y = 92;

    // Separator between time and metrics (safe of circular edges)
    private const SEP_Y = 208;
    private const SEP_INSET = 78;

    // Compact instrument gauges (below separator, clear of time)
    private const BAND_GAUGE_TOP = 222;
    private const BAND_GAUGE_BOTTOM = 338;
    private const GAUGE_LEFT_CX = 135;
    private const GAUGE_RIGHT_CX = 319;

    private const BAND_BOTTOM_Y = 362;
    private const BOTTOM_DIVIDER_HALF = 18;

    // Bottom-cup instrument arc: 210° → 330° counter-clockwise (120° sweep)
    // Does NOT form a complete circle.
    private const GAUGE_ARC_START = 210;
    private const GAUGE_ARC_SWEEP = 120;
    private const GAUGE_PEN_TRACK = 2;
    private const GAUGE_PEN_PROGRESS = 4;
    private const GAUGE_TICK_LEN = 5;

    // HR arc scale (bpm) — numeric value remains authoritative
    private const HR_GAUGE_MIN = 40;
    private const HR_GAUGE_MAX = 190;

    function initialize() {
        WatchFace.initialize();
    }

    function onLayout(dc as Dc) as Void {
    }

    function onShow() as Void {
    }

    function onUpdate(dc as Dc) as Void {
        var width = dc.getWidth();
        var centerX = width / 2;

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        var monitorInfo = ActivityMonitor.getInfo();

        // --- TOP STATUS (subdued) ---
        drawCenteredText(
            dc,
            centerX,
            BAND_STATUS_Y,
            Graphics.FONT_XTINY,
            formatBattery(),
            Graphics.COLOR_DK_GRAY
        );

        // --- DATE (more weight than battery, far less than time) ---
        drawCenteredText(
            dc,
            centerX,
            BAND_DATE_Y,
            Graphics.FONT_SMALL,
            formatDate(),
            Graphics.COLOR_WHITE
        );

        // --- PRIMARY TIME ---
        drawCenteredText(
            dc,
            centerX,
            BAND_TIME_Y,
            Graphics.FONT_NUMBER_HOT,
            formatTime(),
            Graphics.COLOR_WHITE
        );

        // --- TIME / METRICS separator ---
        drawSeparator(dc, centerX, SEP_Y, width);

        // --- INSTRUMENT GAUGES ---
        var gaugeRadius = 44;
        // Arc sits in the lower portion of the gauge cell; text above it
        var textTop = BAND_GAUGE_TOP + 2;
        var arcCy = BAND_GAUGE_BOTTOM - gaugeRadius - 4;

        var hrValue = readHeartRate();
        var hrText = (hrValue == null) ? "--" : (hrValue as Number).format("%d");
        drawInstrumentGauge(
            dc,
            GAUGE_LEFT_CX,
            textTop,
            arcCy,
            gaugeRadius,
            hrText,
            "HR",
            heartRateProgress(hrValue)
        );

        drawInstrumentGauge(
            dc,
            GAUGE_RIGHT_CX,
            textTop,
            arcCy,
            gaugeRadius,
            formatSteps(monitorInfo),
            "STEPS",
            stepsProgressRatio(monitorInfo)
        );

        // --- BOTTOM METRICS with center marker ---
        drawBottomCenterMarker(dc, centerX, BAND_BOTTOM_Y);

        var distValue = "--";
        if ((monitorInfo != null) && (monitorInfo.distance != null)) {
            var km = (monitorInfo.distance as Number).toFloat() / 100000.0;
            distValue = km.format("%.1f");
        }
        drawBottomMetric(dc, GAUGE_LEFT_CX, BAND_BOTTOM_Y, distValue, "KM");

        var calValue = "--";
        if ((monitorInfo != null) && (monitorInfo.calories != null)) {
            calValue = (monitorInfo.calories as Number).format("%d");
        }
        drawBottomMetric(dc, GAUGE_RIGHT_CX, BAND_BOTTOM_Y, calValue, "CAL");
    }

    function onHide() as Void {
    }

    function onExitSleep() as Void {
    }

    function onEnterSleep() as Void {
    }

    // -------------------------------------------------------------------------
    // Drawing helpers
    // -------------------------------------------------------------------------

    private function drawCenteredText(
        dc as Dc,
        x as Number,
        y as Number,
        font as FontDefinition,
        text as String,
        color as Number
    ) as Void {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, y, font, text, Graphics.TEXT_JUSTIFY_CENTER);
    }

    // Thin instrumentation separator with red center accent.
    // Inset keeps the line inside the circular safe region.
    private function drawSeparator(
        dc as Dc,
        centerX as Number,
        y as Number,
        width as Number
    ) as Void {
        var left = SEP_INSET;
        var right = width - SEP_INSET;

        dc.setPenWidth(1);
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(left, y, right, y);

        // Short red accent at center
        var accentHalf = 10;
        dc.setPenWidth(2);
        dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(centerX - accentHalf, y, centerX + accentHalf, y);

        // Small end ticks
        dc.setPenWidth(1);
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(left, y - 3, left, y + 3);
        dc.drawLine(right, y - 3, right, y + 3);
    }

    // Compact instrument dial: value + label grouped above a bottom-cup arc.
    private function drawInstrumentGauge(
        dc as Dc,
        cx as Number,
        textTop as Number,
        arcCy as Number,
        radius as Number,
        valueText as String,
        label as String,
        progress as Float
    ) as Void {
        var maxValueWidth = (radius * 2) + 20;
        var valueFont = selectGaugeValueFont(dc, valueText, maxValueWidth);
        var labelFont = Graphics.FONT_XTINY;
        var valueHeight = dc.getFontHeight(valueFont);
        var labelHeight = dc.getFontHeight(labelFont);

        var valueY = textTop;
        var labelY = valueY + valueHeight - 2;

        // Value
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            cx,
            valueY,
            valueFont,
            valueText,
            Graphics.TEXT_JUSTIFY_CENTER
        );

        // Label
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            cx,
            labelY,
            labelFont,
            label,
            Graphics.TEXT_JUSTIFY_CENTER
        );

        // Short grouping underline under the label
        var underlineHalf = 14;
        var underlineY = labelY + labelHeight + 1;
        dc.setPenWidth(1);
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(cx - underlineHalf, underlineY, cx + underlineHalf, underlineY);

        // Track arc (bottom cup — not a full circle)
        var arcEnd = GAUGE_ARC_START + GAUGE_ARC_SWEEP;
        dc.setPenWidth(GAUGE_PEN_TRACK);
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawArc(
            cx,
            arcCy,
            radius,
            Graphics.ARC_COUNTER_CLOCKWISE,
            GAUGE_ARC_START,
            arcEnd
        );

        // Progress arc
        if (progress > 0.0) {
            var clamped = progress;
            if (clamped > 1.0) {
                clamped = 1.0;
            }
            var sweep = (GAUGE_ARC_SWEEP * clamped).toNumber();
            if (sweep > 0) {
                dc.setPenWidth(GAUGE_PEN_PROGRESS);
                dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
                dc.drawArc(
                    cx,
                    arcCy,
                    radius,
                    Graphics.ARC_COUNTER_CLOCKWISE,
                    GAUGE_ARC_START,
                    GAUGE_ARC_START + sweep
                );
            }
        }
        dc.setPenWidth(1);

        // End / mid tick marks on the track
        drawGaugeTick(dc, cx, arcCy, radius, GAUGE_ARC_START);
        drawGaugeTick(dc, cx, arcCy, radius, GAUGE_ARC_START + (GAUGE_ARC_SWEEP / 2));
        drawGaugeTick(dc, cx, arcCy, radius, arcEnd);
    }

    private function drawGaugeTick(
        dc as Dc,
        cx as Number,
        cy as Number,
        radius as Number,
        angleDeg as Number
    ) as Void {
        var rad = angleDeg.toFloat() * Math.PI / 180.0;
        var cosA = Math.cos(rad);
        var sinA = Math.sin(rad);
        var outer = radius.toFloat() + 1.0;
        var inner = outer - GAUGE_TICK_LEN.toFloat();

        // Garmin angles: 0° = 3 o'clock, CCW; screen Y grows downward
        var x0 = cx + (inner * cosA).toNumber();
        var y0 = cy - (inner * sinA).toNumber();
        var x1 = cx + (outer * cosA).toNumber();
        var y1 = cy - (outer * sinA).toNumber();

        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(x0, y0, x1, y1);
    }

    private function selectGaugeValueFont(
        dc as Dc,
        text as String,
        maxWidth as Number
    ) as FontDefinition {
        if (dc.getTextWidthInPixels(text, Graphics.FONT_NUMBER_MILD) <= maxWidth) {
            return Graphics.FONT_NUMBER_MILD;
        }
        if (dc.getTextWidthInPixels(text, Graphics.FONT_MEDIUM) <= maxWidth) {
            return Graphics.FONT_MEDIUM;
        }
        if (dc.getTextWidthInPixels(text, Graphics.FONT_SMALL) <= maxWidth) {
            return Graphics.FONT_SMALL;
        }
        return Graphics.FONT_TINY;
    }

    private function drawBottomCenterMarker(
        dc as Dc,
        centerX as Number,
        y as Number
    ) as Void {
        var midY = y + 12;

        // Subtle vertical divider between KM / CAL cells
        dc.setPenWidth(1);
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(
            centerX,
            midY - BOTTOM_DIVIDER_HALF,
            centerX,
            midY + BOTTOM_DIVIDER_HALF
        );

        // Small red center accent
        dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(centerX, midY, 2);
    }

    private function drawBottomMetric(
        dc as Dc,
        x as Number,
        y as Number,
        valueText as String,
        unitText as String
    ) as Void {
        var valueFont = Graphics.FONT_TINY;
        var unitFont = Graphics.FONT_XTINY;
        var valueHeight = dc.getFontHeight(valueFont);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            x,
            y,
            valueFont,
            valueText,
            Graphics.TEXT_JUSTIFY_CENTER
        );
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            x,
            y + valueHeight + 1,
            unitFont,
            unitText,
            Graphics.TEXT_JUSTIFY_CENTER
        );
    }

    // -------------------------------------------------------------------------
    // Data formatting (unchanged sources)
    // -------------------------------------------------------------------------

    private function formatTime() as String {
        var timeFormat = "$1$:$2$";
        var clockTime = System.getClockTime();
        var hours = clockTime.hour;

        if (!System.getDeviceSettings().is24Hour) {
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

    private function formatDate() as String {
        var info = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);
        var dayOfWeek = (info.day_of_week as String).toUpper();
        var month = (info.month as String).toUpper();
        return Lang.format("$1$ $2$ $3$", [dayOfWeek, info.day, month]);
    }

    private function formatBattery() as String {
        var pct = (System.getSystemStats().battery + 0.5).toNumber();
        return pct.format("%d") + "% BAT";
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

    private function heartRateProgress(hrValue as Number?) as Float {
        if (hrValue == null) {
            return 0.0;
        }
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

    private function formatSteps(info as ActivityMonitor.Info?) as String {
        if ((info == null) || (info.steps == null)) {
            return "--";
        }
        return formatThousands(info.steps as Number);
    }

    private function stepsProgressRatio(info as ActivityMonitor.Info?) as Float {
        if ((info == null) || (info.steps == null) || (info.stepGoal == null)) {
            return 0.0;
        }
        var goal = info.stepGoal as Number;
        if (goal <= 0) {
            return 0.0;
        }
        var ratio = (info.steps as Number).toFloat() / goal.toFloat();
        if (ratio > 1.0) {
            return 1.0;
        }
        return ratio;
    }

    private function formatThousands(value as Number) as String {
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
