import Toybox.Graphics;
import Toybox.Lang;

// Color palette for one EliteFace theme.
class Theme {

    var background as Number;
    var primaryText as Number;
    var secondaryText as Number;
    var track as Number;
    var accent as Number;

    function initialize(
        backgroundColor as Number,
        primaryTextColor as Number,
        secondaryTextColor as Number,
        trackColor as Number,
        accentColor as Number
    ) {
        background = backgroundColor;
        primaryText = primaryTextColor;
        secondaryText = secondaryTextColor;
        track = trackColor;
        accent = accentColor;
    }

}

// Theme identifiers — match Properties.Theme list values.
module ThemeIds {
    enum {
        CARBON_RED = 0
        // Future: ICE_BLUE, VOLT, STEALTH, MONO
    }
}

module ThemeCatalog {

    function resolve(themeId as Number) as Theme {
        // Additional themes branch here later.
        if (themeId == ThemeIds.CARBON_RED) {
            return carbonRed();
        }
        return carbonRed();
    }

    function carbonRed() as Theme {
        return new Theme(
            Graphics.COLOR_BLACK,
            Graphics.COLOR_WHITE,
            Graphics.COLOR_LT_GRAY,
            Graphics.COLOR_DK_GRAY,
            Graphics.COLOR_RED
        );
    }

}
