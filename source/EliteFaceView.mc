import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

// EliteFace v0.9.2 — Typography and Icon System
class EliteFaceView extends WatchUi.WatchFace {

    private const TIME_FORMAT_SYSTEM = 0;
    private const TIME_FORMAT_12H = 1;
    private const TIME_FORMAT_24H = 2;

    // -------------------------------------------------------------------------
    // Layout — 454x454 FR965
    // -------------------------------------------------------------------------
    private const BAND_DATE_Y = 40;
    private const ACCENT_GAP = 3;
    private const ACCENT_HALF = 12;
    private const BAND_TIME_Y = 92;

    private const COMP_CY = 280;
    private const COMP_LEFT_CX = 105;
    private const COMP_CENTER_CX = 227;
    private const COMP_RIGHT_CX = 349;
    private const COMP_RADIUS = 47;
    private const COMP_RING_PEN = 1;
    private const COMP_VALUE_MAX_WIDTH = 64;
    private const COMP_ICON_SIZE = 14;
    // Explicit vertical zones inside the circle (relative to cy)
    private const COMP_VALUE_OFFSET_Y = -16;
    private const COMP_ICON_OFFSET_Y = 10;

    private const BAND_BOTTOM_Y = 362;
    private const BOTTOM_LEFT_CX = 135;
    private const BOTTOM_RIGHT_CX = 319;
    private const INLINE_GAP_ICON_VALUE = 4;
    private const INLINE_GAP_VALUE_UNIT = 3;
    private const SECONDARY_ICON_SIZE = 12;

    // Primary font ladder — max is FONT_MEDIUM (one tier below v0.9.1 NUMBER_MILD)
    private const FONT_RANK_MEDIUM = 0;
    private const FONT_RANK_SMALL = 1;
    private const FONT_RANK_TINY = 2;
    private const FONT_RANK_XTINY = 3;

    private var _dataProvider as WatchDataProvider;
    private var _icons as MetricIconCache;
    private var _primaryLeft as MetricRender;
    private var _primaryCenter as MetricRender;
    private var _primaryRight as MetricRender;
    private var _secondaryLeft as MetricRender;
    private var _secondaryRight as MetricRender;

    function initialize() {
        WatchFace.initialize();
        _dataProvider = new WatchDataProvider();
        _icons = new MetricIconCache();
        _primaryLeft = new MetricRender();
        _primaryCenter = new MetricRender();
        _primaryRight = new MetricRender();
        _secondaryLeft = new MetricRender();
        _secondaryRight = new MetricRender();
    }

    function onLayout(dc as Dc) as Void {
        _icons.load();
    }

    function onShow() as Void {
        if (_icons.iconFor(MetricIds.HEART_RATE) == null) {
            _icons.load();
        }
    }

    function onUpdate(dc as Dc) as Void {
        var centerX = dc.getWidth() / 2;
        var theme = ThemeCatalog.resolve(readThemeId());
        var data = _dataProvider.getSnapshot();

        MetricCatalog.fillPrimary(readSlot("PrimaryLeftMetric"), data, _primaryLeft, _icons);
        MetricCatalog.fillPrimary(readSlot("PrimaryCenterMetric"), data, _primaryCenter, _icons);
        MetricCatalog.fillPrimary(readSlot("PrimaryRightMetric"), data, _primaryRight, _icons);
        MetricCatalog.fillSecondary(readSlot("SecondaryLeftMetric"), data, _secondaryLeft, _icons);
        MetricCatalog.fillSecondary(readSlot("SecondaryRightMetric"), data, _secondaryRight, _icons);

        dc.setColor(theme.background, theme.background);
        dc.clear();

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

        drawCenteredText(
            dc,
            centerX,
            BAND_TIME_Y,
            Graphics.FONT_NUMBER_HOT,
            formatTime(data),
            theme.primaryText
        );

        var sharedFont = selectSharedMetricFont(
            dc,
            _primaryLeft.value,
            _primaryCenter.value,
            _primaryRight.value,
            COMP_VALUE_MAX_WIDTH
        );

        drawPrimaryComplication(dc, theme, COMP_LEFT_CX, COMP_CY, _primaryLeft, sharedFont);
        drawPrimaryComplication(dc, theme, COMP_CENTER_CX, COMP_CY, _primaryCenter, sharedFont);
        drawPrimaryComplication(dc, theme, COMP_RIGHT_CX, COMP_CY, _primaryRight, sharedFont);

        drawSecondaryMetric(dc, theme, BOTTOM_LEFT_CX, BAND_BOTTOM_Y, _secondaryLeft);
        drawSecondaryMetric(dc, theme, BOTTOM_RIGHT_CX, BAND_BOTTOM_Y, _secondaryRight);
    }

    function onHide() as Void {
    }

    function onExitSleep() as Void {
    }

    function onEnterSleep() as Void {
    }

    private function readThemeId() as Number {
        return Application.Properties.getValue("Theme") as Number;
    }

    private function readTimeFormat() as Number {
        return Application.Properties.getValue("TimeFormat") as Number;
    }

    private function readSlot(propertyId as String) as Number {
        return Application.Properties.getValue(propertyId) as Number;
    }

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

    // Explicit zones: value in upper half, icon in lower half
    private function drawPrimaryComplication(
        dc as Dc,
        theme as Theme,
        cx as Number,
        cy as Number,
        metric as MetricRender,
        valueFont as FontDefinition
    ) as Void {
        drawProgressRing(dc, theme, cx, cy, COMP_RADIUS, metric.progress);

        var valueHeight = dc.getFontHeight(valueFont);
        var valueY = cy + COMP_VALUE_OFFSET_Y - (valueHeight / 2);
        var iconY = cy + COMP_ICON_OFFSET_Y;

        dc.setColor(theme.primaryText, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            cx,
            valueY,
            valueFont,
            metric.value,
            Graphics.TEXT_JUSTIFY_CENTER
        );

        drawMetricIcon(
            dc,
            metric,
            cx - (COMP_ICON_SIZE / 2),
            iconY,
            COMP_ICON_SIZE
        );
    }

    private function drawProgressRing(
        dc as Dc,
        theme as Theme,
        cx as Number,
        cy as Number,
        radius as Number,
        progress as Float
    ) as Void {
        dc.setPenWidth(COMP_RING_PEN);
        dc.setColor(theme.track, Graphics.COLOR_TRANSPARENT);
        dc.drawArc(cx, cy, radius, Graphics.ARC_CLOCKWISE, 0, 0);

        if (progress > 0.0) {
            var clamped = progress;
            if (clamped > 1.0) {
                clamped = 1.0;
            }
            dc.setColor(theme.accent, Graphics.COLOR_TRANSPARENT);
            if (clamped >= 0.999) {
                dc.drawArc(cx, cy, radius, Graphics.ARC_CLOCKWISE, 90, 90);
            } else {
                var sweep = (360.0 * clamped).toNumber();
                if (sweep > 0) {
                    dc.drawArc(
                        cx,
                        cy,
                        radius,
                        Graphics.ARC_CLOCKWISE,
                        90,
                        90 - sweep
                    );
                }
            }
        }
        dc.setPenWidth(1);
    }

    // [icon] VALUE UNIT — measured group; VALUE > UNIT > ICON hierarchy
    private function drawSecondaryMetric(
        dc as Dc,
        theme as Theme,
        groupCx as Number,
        y as Number,
        metric as MetricRender
    ) as Void {
        var valueFont = Graphics.FONT_TINY;
        var unitFont = Graphics.FONT_XTINY;
        var valueWidth = dc.getTextWidthInPixels(metric.value, valueFont);
        var unitWidth = dc.getTextWidthInPixels(metric.label, unitFont);
        var iconW = 0;
        if (metric.icon != null) {
            iconW = SECONDARY_ICON_SIZE;
        }

        var totalWidth = valueWidth + INLINE_GAP_VALUE_UNIT + unitWidth;
        if (iconW > 0) {
            totalWidth = iconW + INLINE_GAP_ICON_VALUE + valueWidth
                + INLINE_GAP_VALUE_UNIT + unitWidth;
        }
        var left = groupCx - (totalWidth / 2);

        var valueHeight = dc.getFontHeight(valueFont);
        var unitHeight = dc.getFontHeight(unitFont);
        var rowMid = y + (valueHeight / 2);

        var cursor = left;
        if (metric.icon != null) {
            var iconY = rowMid - (SECONDARY_ICON_SIZE / 2);
            drawMetricIcon(dc, metric, cursor, iconY, SECONDARY_ICON_SIZE);
            cursor = cursor + iconW + INLINE_GAP_ICON_VALUE;
        }

        dc.setColor(theme.primaryText, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            cursor,
            y,
            valueFont,
            metric.value,
            Graphics.TEXT_JUSTIFY_LEFT
        );
        cursor = cursor + valueWidth + INLINE_GAP_VALUE_UNIT;

        var unitY = y + (valueHeight - unitHeight);
        dc.setColor(theme.secondaryText, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            cursor,
            unitY,
            unitFont,
            metric.label,
            Graphics.TEXT_JUSTIFY_LEFT
        );
    }

    private function drawMetricIcon(
        dc as Dc,
        metric as MetricRender,
        x as Number,
        y as Number,
        slotSize as Number
    ) as Void {
        var bitmap = metric.icon;
        if (bitmap == null) {
            return;
        }

        var bw = bitmap.getWidth();
        var bh = bitmap.getHeight();
        var drawX = x + ((slotSize - bw) / 2);
        var drawY = y + ((slotSize - bh) / 2);
        dc.drawBitmap(drawX, drawY, bitmap);
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
        if (dc.getTextWidthInPixels(text, Graphics.FONT_MEDIUM) <= maxWidth) {
            return FONT_RANK_MEDIUM;
        }
        if (dc.getTextWidthInPixels(text, Graphics.FONT_SMALL) <= maxWidth) {
            return FONT_RANK_SMALL;
        }
        if (dc.getTextWidthInPixels(text, Graphics.FONT_TINY) <= maxWidth) {
            return FONT_RANK_TINY;
        }
        return FONT_RANK_XTINY;
    }

    private function fontFromRank(rank as Number) as FontDefinition {
        if (rank == FONT_RANK_MEDIUM) {
            return Graphics.FONT_MEDIUM;
        }
        if (rank == FONT_RANK_SMALL) {
            return Graphics.FONT_SMALL;
        }
        if (rank == FONT_RANK_TINY) {
            return Graphics.FONT_TINY;
        }
        return Graphics.FONT_XTINY;
    }

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
