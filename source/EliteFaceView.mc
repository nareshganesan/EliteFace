import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

// EliteFace v0.8 — Configurable Metric Slots
class EliteFaceView extends WatchUi.WatchFace {

    private const TIME_FORMAT_SYSTEM = 0;
    private const TIME_FORMAT_12H = 1;
    private const TIME_FORMAT_24H = 2;

    // -------------------------------------------------------------------------
    // Layout bands — unchanged from v0.7
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

    private const BAND_BOTTOM_Y = 348;
    private const BOTTOM_LEFT_CX = 135;
    private const BOTTOM_RIGHT_CX = 319;
    private const INLINE_GAP = 5;

    private const FONT_RANK_MILD = 0;
    private const FONT_RANK_MEDIUM = 1;
    private const FONT_RANK_SMALL = 2;
    private const FONT_RANK_TINY = 3;

    private var _dataProvider as WatchDataProvider;
    private var _primaryLeft as MetricRender;
    private var _primaryCenter as MetricRender;
    private var _primaryRight as MetricRender;
    private var _secondaryLeft as MetricRender;
    private var _secondaryRight as MetricRender;

    function initialize() {
        WatchFace.initialize();
        _dataProvider = new WatchDataProvider();
        _primaryLeft = new MetricRender();
        _primaryCenter = new MetricRender();
        _primaryRight = new MetricRender();
        _secondaryLeft = new MetricRender();
        _secondaryRight = new MetricRender();
    }

    function onLayout(dc as Dc) as Void {
    }

    function onShow() as Void {
    }

    function onUpdate(dc as Dc) as Void {
        var centerX = dc.getWidth() / 2;
        var theme = ThemeCatalog.resolve(readThemeId());
        var data = _dataProvider.getSnapshot();

        // Resolve configured slots into reused render payloads
        MetricCatalog.fillPrimary(readSlot("PrimaryLeftMetric"), data, _primaryLeft);
        MetricCatalog.fillPrimary(readSlot("PrimaryCenterMetric"), data, _primaryCenter);
        MetricCatalog.fillPrimary(readSlot("PrimaryRightMetric"), data, _primaryRight);
        MetricCatalog.fillSecondary(readSlot("SecondaryLeftMetric"), data, _secondaryLeft);
        MetricCatalog.fillSecondary(readSlot("SecondaryRightMetric"), data, _secondaryRight);

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

        // --- PRIMARY SLOTS ---
        var sharedFont = selectSharedMetricFont(
            dc,
            _primaryLeft.value,
            _primaryCenter.value,
            _primaryRight.value,
            METRIC_COL_WIDTH
        );

        drawPrimaryMetric(
            dc,
            theme,
            METRIC_LEFT_CX,
            METRIC_VALUE_Y,
            _primaryLeft.value,
            _primaryLeft.label,
            _primaryLeft.progress,
            sharedFont
        );
        drawPrimaryMetric(
            dc,
            theme,
            METRIC_CENTER_CX,
            METRIC_VALUE_Y,
            _primaryCenter.value,
            _primaryCenter.label,
            _primaryCenter.progress,
            sharedFont
        );
        drawPrimaryMetric(
            dc,
            theme,
            METRIC_RIGHT_CX,
            METRIC_VALUE_Y,
            _primaryRight.value,
            _primaryRight.label,
            _primaryRight.progress,
            sharedFont
        );

        // --- SECONDARY SLOTS ---
        drawInlineMetric(
            dc,
            theme,
            BOTTOM_LEFT_CX,
            BAND_BOTTOM_Y,
            _secondaryLeft.value,
            _secondaryLeft.label
        );
        drawInlineMetric(
            dc,
            theme,
            BOTTOM_RIGHT_CX,
            BAND_BOTTOM_Y,
            _secondaryRight.value,
            _secondaryRight.label
        );
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

    private function readSlot(propertyId as String) as Number {
        return Application.Properties.getValue(propertyId) as Number;
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
    // Time formatting
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

}
