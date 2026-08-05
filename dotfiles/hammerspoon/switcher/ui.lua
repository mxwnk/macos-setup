-- Appearance of the switcher overlay. Pure data, no logic.

return {
    -- A row is added once the window count passes these thresholds.
    rowThresholds = { 5, 12 },

    tileWidth = 300,
    thumbnailRatio = 0.58, -- thumbnail height relative to tile width
    titleHeight = 34,
    iconSize = 20,
    tilePadding = 14,
    tileRadius = 10,

    panelPadding = 18,
    panelRadius = 20,
    panelWidthFraction = 0.92, -- of the screen, before tiles are shrunk to fit

    fontName = ".AppleSystemUIFont",
    fontSize = 13,

    dimColor = { white = 0, alpha = 0.30 },
    panelColor = { red = 0.11, green = 0.11, blue = 0.12, alpha = 0.94 },
    panelStrokeColor = { white = 1, alpha = 0.10 },
    tileColor = { white = 1, alpha = 0.05 },
    selectedTileColor = { white = 1, alpha = 0.16 },
    selectedStrokeColor = { red = 0.04, green = 0.52, blue = 1.0, alpha = 0.95 },
    thumbnailBackgroundColor = { white = 0, alpha = 0.25 },
    titleColor = { white = 1, alpha = 0.92 },
    transparent = { white = 0, alpha = 0 },
}
