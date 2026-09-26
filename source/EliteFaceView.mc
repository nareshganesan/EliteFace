import Toybox.Activity;
import Toybox.ActivityMonitor;
import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.WatchUi;

// EliteFace Performance v0.6 — Design Foundation
class EliteFaceView extends WatchUi.WatchFace {

    // -------------------------------------------------------------------------
    // Color system
    // -------------------------------------------------------------------------
    private const COLOR_BACKGROUND = Graphics.COLOR_BLACK;
    private const COLOR_PRIMARY_TEXT = Graphics.COLOR_WHITE;
    private const COLOR_SECONDARY_TEXT = Graphics.COLOR_LT_GRAY;
    private const COLOR_TRACK = Graphics.COLOR_DK_GRAY;
    private const COLOR_ACCENT = Graphics.COLOR_RED;

    // -------------------------------------------------------------------------
    // Layout bands — 454x454 FR965 circular safe content
    // -------------------------------------------------------------------------
    private const BAND_DATE_Y = 40;
    private const ACCENT_Y = 64;
    private const ACCENT_HALF = 12;
    private const BAND_TIME_Y = 88;

    // Primary metrics: value/label above short bottom-cup arcs
    private const METRIC_VALUE_Y = 228;
    private const METRIC_LEFT_CX = 105;
    private const METRIC_CENTER_CX = 227;
    private const METRIC_RIGHT_CX = 349;
    private const METRIC_COL_WIDTH = 100;
    private const METRIC_ARC_RADIUS = 34;
    private const METRIC_ARC_GAP = 6;

    // Short cup arc under the metric (not a full / surrounding ring)
    private const ARC_START = 210;
    private const ARC_SWEEP = 120;
    private const ARC_PEN_TRACK = 2;
    private const ARC_PEN_PROGRESS = 3;

    // Secondary metrics — keep above ~y=385
    private const BAND_BOTTOM_Y = 358;
    private const BOTTOM_LEFT_CX = 135;
    private const BOTTOM_RIGHT_CX = 319;
    private const INLINE_GAP = 5;

    // HR arc scale (bpm) — numeric value remains authoritative
    private const HR_GAUGE_MIN = 40;
    private const HR_GAUGE_MAX = 190;

    // Shared metric font ranks (0 = largest allowed, 3 = smallest)
    private const FONT_RANK_MILD = 0;
    private const FONT_RANK_MEDIUM = 1;
    private const FONT_RANK_SMALL = 2;
    private const FONT_RANK_TINY = 3;

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

        dc.setColor(COLOR_BACKGROUND, COLOR_BACKGROUND);
        dc.clear();

        var monitorInfo = ActivityMonitor.getInfo();

        // --- DATE ---
        drawCenteredText(
            dc,
            centerX,
            BAND_DATE_Y,
            Graphics.FONT_TINY,
            formatDate(),
            COLOR_PRIMARY_TEXT
        );

        // --- Signature accent (single restrained mark below date) ---
        drawDateAccent(dc, centerX, ACCENT_Y);

        // --- PRIMARY TIME ---
        drawCenteredText(
            dc,
            centerX,
            BAND_TIME_Y,
            Graphics.FONT_NUMBER_HOT,
            formatTime(),
            COLOR_PRIMARY_TEXT
        );

        // --- PRIMARY METRICS: HR | STEPS | BAT ---
        var hrValue = readHeartRate();
        var hrText = (hrValue == null) ? "--" : (hrValue as Number).format("%d");
        var stepsText = formatSteps(monitorInfo);
        var batPct = readBatteryPercent();
        var batText = batPct.format("%d") + "%";

        var maxWidth = METRIC_COL_WIDTH;
        var sharedFont = selectSharedMetricFont(dc, hrText, stepsText, batText, maxWidth);

        drawPrimaryMetric(
            dc,
            METRIC_LEFT_CX,
            METRIC_VALUE_Y,
            hrText,
            "HR",
            heartRateProgress(hrValue),
            sharedFont
        );
        drawPrimaryMetric(
            dc,
            METRIC_CENTER_CX,
            METRIC_VALUE_Y,
            stepsText,
            "STEPS",
            stepsProgressRatio(monitorInfo),
            sharedFont
        );
        drawPrimaryMetric(
            dc,
            METRIC_RIGHT_CX,
            METRIC_VALUE_Y,
            batText,
            "BAT",
            batteryProgress(batPct),
            sharedFont
        );

        // --- SECONDARY: inline distance / calories ---
        var distValue = "--";
        if ((monitorInfo != null) && (monitorInfo.distance != null)) {
            var km = (monitorInfo.distance as Number).toFloat() / 100000.0;
            distValue = km.format("%.1f");
        }
        drawInlineMetric(dc, BOTTOM_LEFT_CX, BAND_BOTTOM_Y, distValue, "KM");

        var calValue = "--";
        if ((monitorInfo != null) && (monitorInfo.calories != null)) {
            calValue = (monitorInfo.calories as Number).format("%d");
        }
        drawInlineMetric(dc, BOTTOM_RIGHT_CX, BAND_BOTTOM_Y, calValue, "CAL");
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

    private function drawDateAccent(dc as Dc, centerX as Number, y as Number) as Void {
        dc.setPenWidth(2);
        dc.setColor(COLOR_ACCENT, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(centerX - ACCENT_HALF, y, centerX + ACCENT_HALF, y);
        dc.setPenWidth(1);
    }

    // VALUE / LABEL above a short progress arc (identical grammar per column).
    private function drawPrimaryMetric(
        dc as Dc,
        cx as Number,
        valueY as Number,
        valueText as String,
        label as String,
        progress as Float,
        valueFont as FontDefinition
    ) as Void {
        var labelFont = Graphics.FONT_XTINY;
        var valueHeight = dc.getFontHeight(valueFont);
        var labelHeight = dc.getFontHeight(labelFont);

        var labelY = valueY + valueHeight - 2;
        var arcCy = labelY + labelHeight + METRIC_ARC_GAP + METRIC_ARC_RADIUS;

        dc.setColor(COLOR_PRIMARY_TEXT, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            cx,
            valueY,
            valueFont,
            valueText,
            Graphics.TEXT_JUSTIFY_CENTER
        );

        dc.setColor(COLOR_SECONDARY_TEXT, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            cx,
            labelY,
            labelFont,
            label,
            Graphics.TEXT_JUSTIFY_CENTER
        );

        drawProgressArc(dc, cx, arcCy, METRIC_ARC_RADIUS, progress);
    }

    // Bottom-cup arc under the metric — never a full circle.
    private function drawProgressArc(
        dc as Dc,
        cx as Number,
        cy as Number,
        radius as Number,
        progress as Float
    ) as Void {
        var arcEnd = ARC_START + ARC_SWEEP;

        dc.setPenWidth(ARC_PEN_TRACK);
        dc.setColor(COLOR_TRACK, Graphics.COLOR_TRANSPARENT);
        dc.drawArc(
            cx,
            cy,
            radius,
            Graphics.ARC_COUNTER_CLOCKWISE,
            ARC_START,
            arcEnd
        );

        if (progress > 0.0) {
            var clamped = progress;
            if (clamped > 1.0) {
                clamped = 1.0;
            }
            var sweep = (ARC_SWEEP * clamped).toNumber();
            if (sweep > 0) {
                dc.setPenWidth(ARC_PEN_PROGRESS);
                dc.setColor(COLOR_ACCENT, Graphics.COLOR_TRANSPARENT);
                dc.drawArc(
                    cx,
                    cy,
                    radius,
                    Graphics.ARC_COUNTER_CLOCKWISE,
                    ARC_START,
                    ARC_START + sweep
                );
            }
        }
        dc.setPenWidth(1);
    }

    // "0.0 KM" as independently styled value + unit, group-centered via measurement.
    private function drawInlineMetric(
        dc as Dc,
        groupCx as Number,
        y as Number,
        valueText as String,
        unitText as String
    ) as Void {
        var valueFont = Graphics.FONT_TINY;
        var unitFont = Graphics.FONT_XTINY;
        var valueWidth = dc.getTextWidthInPixels(valueText, valueFont);
        var unitWidth = dc.getTextWidthInPixels(unitText, unitFont);
        var totalWidth = valueWidth + INLINE_GAP + unitWidth;
        var left = groupCx - (totalWidth / 2);

        var valueHeight = dc.getFontHeight(valueFont);
        var unitHeight = dc.getFontHeight(unitFont);
        var unitY = y + ((valueHeight - unitHeight) / 2);

        dc.setColor(COLOR_PRIMARY_TEXT, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            left,
            y,
            valueFont,
            valueText,
            Graphics.TEXT_JUSTIFY_LEFT
        );

        dc.setColor(COLOR_SECONDARY_TEXT, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            left + valueWidth + INLINE_GAP,
            unitY,
            unitFont,
            unitText,
            Graphics.TEXT_JUSTIFY_LEFT
        );
    }

    // Shared max font across columns — most constrained value sets size for all.
    private function selectSharedMetricFont(
        dc as Dc,
        textA as String,
        textB as String,
        textC as String,
        maxWidth as Number
    ) as FontDefinition {
        var rankA = metricFontRank(dc, textA, maxWidth);
        var rankB = metricFontRank(dc, textB, maxWidth);
        var rankC = metricFontRank(dc, textC, maxWidth);

        var sharedRank = rankA;
        if (rankB > sharedRank) {
            sharedRank = rankB;
        }
        if (rankC > sharedRank) {
            sharedRank = rankC;
        }
        return fontFromRank(sharedRank);
    }

    private function metricFontRank(
        dc as Dc,
        text as String,
        maxWidth as Number
    ) as Number {
        if (dc.getTextWidthInPixels(text, Graphics.FONT_NUMBER_MILD) <= maxWidth) {
            return FONT_RANK_MILD;
        }
        if (dc.getTextWidthInPixels(text, Graphics.FONT_MEDIUM) <= maxWidth) {
            return FONT_RANK_MEDIUM;
        }
        if (dc.getTextWidthInPixels(text, Graphics.FONT_SMALL) <= maxWidth) {
            return FONT_RANK_SMALL;
        }
        return FONT_RANK_TINY;
    }

    private function fontFromRank(rank as Number) as FontDefinition {
        if (rank == FONT_RANK_MILD) {
            return Graphics.FONT_NUMBER_MILD;
        }
        if (rank == FONT_RANK_MEDIUM) {
            return Graphics.FONT_MEDIUM;
        }
        if (rank == FONT_RANK_SMALL) {
            return Graphics.FONT_SMALL;
        }
        return Graphics.FONT_TINY;
    }

    // -------------------------------------------------------------------------
    // Data acquisition (unchanged)
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

    private function readBatteryPercent() as Number {
        return (System.getSystemStats().battery + 0.5).toNumber();
    }

    private function batteryProgress(pct as Number) as Float {
        var ratio = pct.toFloat() / 100.0;
        if (ratio < 0.0) {
            return 0.0;
        }
        if (ratio > 1.0) {
            return 1.0;
        }
        return ratio;
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
