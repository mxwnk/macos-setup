-- Window switching, replaces AltTab.app:
--   Alt-Tab        cycles through all windows on the current space
--   Cmd-Tab        cycles through the windows of the frontmost application
-- Add Shift to either one to cycle backwards. While the overlay is up, the arrow
-- keys move the selection and Escape cancels. Release the modifier to focus the
-- selected window.
--
-- The overlay is drawn here instead of using hs.window.switcher, because that
-- module lays its windows out in a single fixed row and builds on the deprecated
-- hs.drawing.

local M = {}

local ui = {
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

-- Visible standard windows only, and only on the space we are currently on.
local windowRules = {
    visible = true,
    currentSpace = true,
    allowRoles = "AXStandardWindow",
}

local allWindowsFilter = hs.window.filter.new():setDefaultFilter(windowRules)

-- A window filter is bound to a fixed app name, so one is kept per application.
local appFilters = {}

local function allWindows()
    return allWindowsFilter:getWindows(hs.window.filter.sortByFocusedLast)
end

local function frontmostAppWindows()
    local app = hs.application.frontmostApplication()
    if not app then return {} end

    local name = app:name()
    if not appFilters[name] then
        appFilters[name] = hs.window.filter.new(false):setAppFilter(name, windowRules)
    end

    return appFilters[name]:getWindows(hs.window.filter.sortByFocusedLast)
end

-- Snapshots cost roughly 50ms each, so they are scaled down and kept around
-- briefly. Repeatedly switching within a few seconds then needs no new capture.
local snapshotCache = {}
local snapshotTTL = 10

local function snapshotFor(window, size)
    local id = window:id()
    local now = hs.timer.secondsSinceEpoch()
    local cached = id and snapshotCache[id]
    if cached and now - cached.at < snapshotTTL then return cached.image end

    local image = window:snapshot()
    if image then
        image = image:setSize({ w = size.w * 2, h = size.h * 2 }) -- 2x for retina
        if id then snapshotCache[id] = { image = image, at = now } end
    end

    return image
end

-- Rough character-width estimate; canvas has no text measurement of its own.
local function truncate(text, width)
    local maxChars = math.floor(width / (ui.fontSize * 0.55))
    if #text <= maxChars then return text end
    return text:sub(1, math.max(1, maxChars - 1)) .. "…"
end

local function gridShape(count)
    local rows = 1
    if count > ui.rowThresholds[2] then
        rows = 3
    elseif count > ui.rowThresholds[1] then
        rows = 2
    end

    return rows, math.ceil(count / rows)
end

local function layoutFor(count, screenFrame)
    local rows, columns = gridShape(count)

    local usable = screenFrame.w * ui.panelWidthFraction
        - ui.panelPadding * 2
        - ui.tilePadding * (columns - 1)
    local tileWidth = math.min(ui.tileWidth, usable / columns)
    local thumbnailHeight = math.floor(tileWidth * ui.thumbnailRatio)
    local tileHeight = thumbnailHeight + ui.titleHeight

    local panelWidth = columns * tileWidth + ui.tilePadding * (columns - 1) + ui.panelPadding * 2
    local panelHeight = rows * tileHeight + ui.tilePadding * (rows - 1) + ui.panelPadding * 2

    return {
        rows = rows,
        columns = columns,
        tileWidth = tileWidth,
        tileHeight = tileHeight,
        thumbnailHeight = thumbnailHeight,
        panel = {
            x = screenFrame.x + (screenFrame.w - panelWidth) / 2,
            y = screenFrame.y + (screenFrame.h - panelHeight) / 2,
            w = panelWidth,
            h = panelHeight,
        },
    }
end

local state = nil

-- Last resort against a modifier state that never reports itself as released,
-- which would otherwise leave the overlay on screen for good.
local maxOverlayLifetime = 30

local function tileFrame(layout, index)
    local row = math.floor((index - 1) / layout.columns)
    local column = (index - 1) % layout.columns

    return {
        x = layout.panel.x + ui.panelPadding + column * (layout.tileWidth + ui.tilePadding),
        y = layout.panel.y + ui.panelPadding + row * (layout.tileHeight + ui.tilePadding),
        w = layout.tileWidth,
        h = layout.tileHeight,
    }
end

local function build(windows, screenFrame)
    local layout = layoutFor(#windows, screenFrame)
    local canvas = hs.canvas.new(screenFrame)

    canvas:appendElements({
        type = "rectangle",
        action = "fill",
        fillColor = ui.dimColor,
        frame = { x = 0, y = 0, w = screenFrame.w, h = screenFrame.h },
    }, {
        type = "rectangle",
        action = "strokeAndFill",
        fillColor = ui.panelColor,
        strokeColor = ui.panelStrokeColor,
        strokeWidth = 1,
        roundedRectRadii = { xRadius = ui.panelRadius, yRadius = ui.panelRadius },
        frame = {
            x = layout.panel.x - screenFrame.x,
            y = layout.panel.y - screenFrame.y,
            w = layout.panel.w,
            h = layout.panel.h,
        },
    })

    local tiles = {}

    for index, window in ipairs(windows) do
        local frame = tileFrame(layout, index)
        -- Canvas coordinates are relative to the canvas, which covers the screen.
        local x = frame.x - screenFrame.x
        local y = frame.y - screenFrame.y

        local thumbnailFrame = {
            x = x + ui.tilePadding / 2,
            y = y + ui.tilePadding / 2,
            w = frame.w - ui.tilePadding,
            h = layout.thumbnailHeight - ui.tilePadding / 2,
        }

        canvas:appendElements({
            type = "rectangle",
            action = "strokeAndFill",
            fillColor = ui.tileColor,
            strokeColor = ui.transparent,
            strokeWidth = 2,
            roundedRectRadii = { xRadius = ui.tileRadius, yRadius = ui.tileRadius },
            frame = { x = x, y = y, w = frame.w, h = frame.h },
        }, {
            type = "rectangle",
            action = "fill",
            fillColor = ui.thumbnailBackgroundColor,
            roundedRectRadii = { xRadius = 6, yRadius = 6 },
            frame = thumbnailFrame,
        }, {
            type = "image",
            image = nil, -- filled in progressively
            imageScaling = "scaleProportionally",
            imageAlignment = "center",
            frame = thumbnailFrame,
        }, {
            type = "image",
            image = window:application() and window:application():bundleID()
                and hs.image.imageFromAppBundle(window:application():bundleID()) or nil,
            imageScaling = "scaleProportionally",
            frame = {
                x = x + ui.tilePadding / 2,
                y = y + layout.thumbnailHeight + (ui.titleHeight - ui.iconSize) / 2 - 2,
                w = ui.iconSize,
                h = ui.iconSize,
            },
        }, {
            type = "text",
            text = truncate(window:title() or "", frame.w - ui.iconSize - ui.tilePadding * 2),
            textFont = ui.fontName,
            textSize = ui.fontSize,
            textColor = ui.titleColor,
            frame = {
                x = x + ui.tilePadding / 2 + ui.iconSize + 6,
                y = y + layout.thumbnailHeight + (ui.titleHeight - ui.fontSize * 1.4) / 2 - 2,
                w = frame.w - ui.iconSize - ui.tilePadding - 6,
                h = ui.fontSize * 1.6,
            },
        })

        -- Element indices, so selection changes only touch the tile rectangle.
        local base = #canvas - 5
        tiles[index] = { rect = base + 1, thumbnail = base + 3 }
    end

    return canvas, layout, tiles
end

local function highlight()
    for index, tile in ipairs(state.tiles) do
        local selected = index == state.selected
        state.canvas[tile.rect].fillColor = selected and ui.selectedTileColor or ui.tileColor
        state.canvas[tile.rect].strokeColor = selected and ui.selectedStrokeColor or ui.transparent
    end
end

local function fillThumbnails(index)
    if not state or index > #state.windows then return end

    local tile = state.tiles[index]
    local image = snapshotFor(state.windows[index], {
        w = state.layout.tileWidth,
        h = state.layout.thumbnailHeight,
    })
    if image then state.canvas[tile.thumbnail].image = image end

    -- One capture per tick, so key presses stay responsive in between.
    state.thumbnailTimer = hs.timer.doAfter(0, function() fillThumbnails(index + 1) end)
end

local function teardown()
    if not state then return end

    if state.thumbnailTimer then state.thumbnailTimer:stop() end
    if state.modifierTimer then state.modifierTimer:stop() end
    if state.lifetimeTimer then state.lifetimeTimer:stop() end
    state.canvas:delete()

    local selected = state.windows[state.selected]
    state = nil

    return selected
end

local function finish()
    local window = teardown()
    if window then
        window:unminimize()
        window:focus()
    end
end

local function modifiersHeld()
    local raw = hs.eventtap.checkKeyboardModifiers(true)._raw
    return raw > 0 and raw ~= 65536 -- caps lock alone does not count
end

function M.move(delta)
    if not state then return end

    local count = #state.windows
    state.selected = (state.selected - 1 + delta) % count + 1
    highlight()
end

function M.moveRow(delta)
    if state then M.move(delta * state.columns) end
end

function M.cancel()
    teardown()
end

function M.isVisible()
    return state ~= nil
end

function M.show(source, delta)
    if state then
        -- Only keep the existing overlay while a modifier is genuinely still down.
        -- Otherwise it is a leftover, and moving inside its stale window list would
        -- focus something the user never selected.
        if modifiersHeld() then
            M.move(delta)
            return
        end

        M.cancel()
    end

    local windows = source()
    if #windows == 0 then return end

    local screenFrame = (windows[1]:screen() or hs.screen.mainScreen()):frame()
    local canvas, layout, tiles = build(windows, screenFrame)

    state = {
        windows = windows,
        tiles = tiles,
        layout = layout,
        columns = layout.columns,
        canvas = canvas,
        selected = 1,
    }

    M.move(delta)
    canvas:level(hs.canvas.windowLevels.screenSaver)
    canvas:behavior(hs.canvas.windowBehaviors.canJoinAllSpaces | hs.canvas.windowBehaviors.stationary)
    canvas:show()

    -- Icons are up immediately; captures follow so the overlay never feels slow.
    state.thumbnailTimer = hs.timer.doAfter(0.05, function() fillThumbnails(1) end)
    state.modifierTimer = hs.timer.waitWhile(modifiersHeld, finish, 0.01)
    state.lifetimeTimer = hs.timer.doAfter(maxOverlayLifetime, M.cancel)
end

-- Renders the overlay to a PNG without showing or focusing anything, for
-- checking the layout. `count` optionally repeats windows to simulate a fuller
-- grid: require("switcher").previewToFile("/tmp/switcher.png", 15)
function M.previewToFile(path, count)
    local windows = allWindows()
    if #windows == 0 then return false, "no windows" end

    if count then
        local padded = {}
        for i = 1, count do padded[i] = windows[(i - 1) % #windows + 1] end
        windows = padded
    end

    local screenFrame = (windows[1]:screen() or hs.screen.mainScreen()):frame()
    local canvas, layout, tiles = build(windows, screenFrame)

    state = { windows = windows, tiles = tiles, layout = layout, columns = layout.columns,
        canvas = canvas, selected = 2 }
    highlight()

    for index, window in ipairs(windows) do
        local image = snapshotFor(window, { w = layout.tileWidth, h = layout.thumbnailHeight })
        if image then canvas[tiles[index].thumbnail].image = image end
    end

    local written = canvas:imageFromCanvas():saveToFile(path)
    canvas:delete()
    state = nil

    return written
end

hs.hotkey.bind({ "alt" }, "tab", function() M.show(allWindows, 1) end)
hs.hotkey.bind({ "alt", "shift" }, "tab", function() M.show(allWindows, -1) end)

local arrowActions = {
    [hs.keycodes.map.right] = function() M.move(1) end,
    [hs.keycodes.map.left] = function() M.move(-1) end,
    [hs.keycodes.map.down] = function() M.moveRow(1) end,
    [hs.keycodes.map.up] = function() M.moveRow(-1) end,
    [hs.keycodes.map.escape] = M.cancel,
}

-- Arrow keys and Escape are only taken while the overlay is up, so that they
-- keep working normally everywhere else.
local function handleOverlayKey(event)
    local action = arrowActions[event:getKeyCode()]
    if not action or not M.isVisible() then return false end

    action()
    return true
end

-- macOS reserves Cmd-Tab for its own application switcher and refuses to hand it
-- over to hs.hotkey (RegisterEventHotKey fails with -9878), so the key has to be
-- caught one layer down and swallowed before the Dock ever sees it.
local function handleCmdTab(event)
    if event:getKeyCode() ~= hs.keycodes.map.tab then return false end

    local flags = event:getFlags()
    if flags:containExactly({ "cmd" }) then
        M.show(frontmostAppWindows, 1)
    elseif flags:containExactly({ "cmd", "shift" }) then
        M.show(frontmostAppWindows, -1)
    else
        return false
    end

    return true
end

-- Polling the system modifier state can go stale, and a stale "still held" reading
-- would keep the overlay up for good. The release event itself does not go stale,
-- so it closes the overlay too. Caps lock is ignored on purpose.
local function handleFlagsChanged(event)
    if not M.isVisible() then return false end

    local flags = event:getFlags()
    if not (flags.cmd or flags.alt or flags.ctrl or flags.shift or flags.fn) then
        finish()
    end

    return false
end

local function handleEvent(event)
    if event:getType() == hs.eventtap.event.types.flagsChanged then
        return handleFlagsChanged(event)
    end

    return handleOverlayKey(event) or handleCmdTab(event)
end

-- Kept in a global so the tap survives garbage collection, same as the config
-- watcher in config.lua.
switcherTap = hs.eventtap.new({
    hs.eventtap.event.types.keyDown,
    hs.eventtap.event.types.flagsChanged,
}, handleEvent):start()

return M
