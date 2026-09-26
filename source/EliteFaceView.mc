import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

// EliteFace v0.7 — Product Foundation
class EliteFaceView extends WatchUi.WatchFace {

    // TimeFormat property values
    private const TIME_FORMAT_SYSTEM = 0;
    private const TIME_FORMAT_12H = 1;
    private const TIME_FORMAT_24H = 2;

    // -------------------------------------------------------------------------
    // Layout bands — 454x454 FR965 (preserved from v0.6 with small cleanup)
    // -------------------------------------------------------------------------
    private const BAND_DATE_Y = 40;
    private const ACCENT_GAP = 3;
    private const ACCENT_HALF = 12;
    private const BAND_TIME_Y = 92;

    private const METRIC_VALUE_Y = 226;
    private const METRIC_LEFT_CX = 105;
    private const METRIC_CENTER_CX = 227;
    private const METRIC_RIGHT_CX = 349;
    private const METRIC_COL_WIDTH = 100;
    private const METRIC_ARC_RADIUS = 28;
    private const METRIC_ARC_GAP = 2;

    private const ARC_START = 210;
    private const ARC_SWEEP = 120;
    private const ARC_PEN_TRACK = 2;
    private const ARC_PEN_PROGRESS = 3;

    // Raised for clearance from bezel / logo (~y=385)
    private const BAND_BOTTOM_Y = 348;
    private const BOTTOM_LEFT_CX = 135;
    private const BOTTOM_RIGHT_CX = 319;
    private const INLINE_GAP = 5;

    private const HR_GAUGE_MIN = 40;
    private const HR_GAUGE_MAX = 190;

    private const FONT_RANK_MILD = 0;
    private const FONT_RANK_MEDIUM = 1;
    private const FONT_RANK_SMALL = 2;
    private const FONT_RANK_TINY = 3;

    private var _dataProvider as WatchDataProvider;

    function initialize() {
        WatchFace.initialize();
        _dataProvider = new WatchDataProvider();
    }

    function onLayout(dc as Dc) as Void {
    }

    function onShow() as Void {
    }

    function onUpdate(dc as Dc) as Void {
        var centerX = dc.getWidth() / 2;
        var theme = ThemeCatalog.resolve(readThemeId());
        var data = _dataProvider.getSnapshot();

        dc.setColor(theme.background, theme.background);
        dc.clear();

        // --- DATE ---
        var dateFont = Graphics.FONT_TINY;
        drawCenteredText(
            dc,
            centerX,
            BAND_DATE_Y,
            dateFont,
            data.dateText,
            theme.primaryText
        );

        // Accent below the full date — never intersects glyphs
        var accentY = BAND_DATE_Y + dc.getFontHeight(dateFont) + ACCENT_GAP;
        drawDateAccent(dc, centerX, accentY, theme);

        // --- PRIMARY TIME ---
        drawCenteredText(
            dc,
            centerX,
            BAND_TIME_Y,
            Graphics.FONT_NUMBER_HOT,
            formatTime(data),
            theme.primaryText
        );

        // --- PRIMARY METRICS ---
        var hrText = (data.heartRate == null)
            ? "--"
            : (data.heartRate as Number).format("%d");
        var stepsText = formatSteps(data);
        var batText = data.battery.format("%d") + "%";

        var sharedFont = selectSharedMetricFont(
            dc,
            hrText,
            stepsText,
            batText,
            METRIC_COL_WIDTH
        );

        drawPrimaryMetric(
            dc,
            theme,
            METRIC_LEFT_CX,
            METRIC_VALUE_Y,
            hrText,
            "HR",
            heartRateProgress(data.heartRate),
            sharedFont
        );
        drawPrimaryMetric(
            dc,
            theme,
            METRIC_CENTER_CX,
            METRIC_VALUE_Y,
            stepsText,
            "STEPS",
            stepsProgressRatio(data),
            sharedFont
        );
        drawPrimaryMetric(
            dc,
            theme,
            METRIC_RIGHT_CX,
            METRIC_VALUE_Y,
            batText,
            "BAT",
            batteryProgress(data.battery),
            sharedFont
        );

        // --- SECONDARY ---
        var distValue = "--";
        if (data.distanceCm != null) {
            var km = (data.distanceCm as Number).toFloat() / 100000.0;
            distValue = km.format("%.1f");
        }
        drawInlineMetric(dc, theme, BOTTOM_LEFT_CX, BAND_BOTTOM_Y, distValue, "KM");

        var calValue = "--";
        if (data.calories != null) {
            calValue = (data.calories as Number).format("%d");
        }
        drawInlineMetric(dc, theme, BOTTOM_RIGHT_CX, BAND_BOTTOM_Y, calValue, "CAL");
    }

    function onHide() as Void {
    }

    function onExitSleep() as Void {
    }

    function onEnterSleep() as Void {
    }

    // -------------------------------------------------------------------------
    // Settings
    // -------------------------------------------------------------------------

    private function readThemeId() as Number {
        return Application.Properties.getValue("Theme") as Number;
    }

    private function readTimeFormat() as Number {
        return Application.Properties.getValue("TimeFormat") as Number;
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

    private function drawDateAccent(
        dc as Dc,
        centerX as Number,
        y as Number,
        theme as Theme
    ) as Void {
        dc.setPenWidth(2);
        dc.setColor(theme.accent, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(centerX - ACCENT_HALF, y, centerX + ACCENT_HALF, y);
        dc.setPenWidth(1);
    }

    private function drawPrimaryMetric(
        dc as Dc,
        theme as Theme,
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
        // Arc center just under the label so VALUE/LABEL/ARC read as one unit
        var arcCy = labelY + labelHeight + METRIC_ARC_GAP;

        dc.setColor(theme.primaryText, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            cx,
            valueY,
            valueFont,
            valueText,
            Graphics.TEXT_JUSTIFY_CENTER
        );

        dc.setColor(theme.secondaryText, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            cx,
            labelY,
            labelFont,
            label,
            Graphics.TEXT_JUSTIFY_CENTER
        );

        drawProgressArc(dc, theme, cx, arcCy, METRIC_ARC_RADIUS, progress);
    }

    private function drawProgressArc(
        dc as Dc,
        theme as Theme,
        cx as Number,
        cy as Number,
        radius as Number,
        progress as Float
    ) as Void {
        var arcEnd = ARC_START + ARC_SWEEP;

        dc.setPenWidth(ARC_PEN_TRACK);
        dc.setColor(theme.track, Graphics.COLOR_TRANSPARENT);
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
                dc.setColor(theme.accent, Graphics.COLOR_TRANSPARENT);
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

    private function drawInlineMetric(
        dc as Dc,
        theme as Theme,
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

        dc.setColor(theme.primaryText, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            left,
            y,
            valueFont,
            valueText,
            Graphics.TEXT_JUSTIFY_LEFT
        );

        dc.setColor(theme.secondaryText, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            left + valueWidth + INLINE_GAP,
            unitY,
            unitFont,
            unitText,
            Graphics.TEXT_JUSTIFY_LEFT
        );
    }

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
    // Formatting (from WatchData snapshot)
    // -------------------------------------------------------------------------

    private function formatTime(data as WatchData) as String {
        var hours = data.hour;
        var use24Hour = false;
        var mode = readTimeFormat();

        if (mode == TIME_FORMAT_SYSTEM) {
            use24Hour = System.getDeviceSettings().is24Hour;
        } else if (mode == TIME_FORMAT_12H) {
            use24Hour = false;
        } else if (mode == TIME_FORMAT_24H) {
            use24Hour = true;
        } else {
            use24Hour = System.getDeviceSettings().is24Hour;
        }

        if (!use24Hour) {
            if (hours == 0) {
                hours = 12;
            } else if (hours > 12) {
                hours = hours - 12;
            }
        }

        return Lang.format("$1$:$2$", [hours, data.minute.format("%02d")]);
    }

    private function formatSteps(data as WatchData) as String {
        if (data.steps == null) {
            return "--";
        }
        return formatThousands(data.steps as Number);
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

    private function stepsProgressRatio(data as WatchData) as Float {
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
