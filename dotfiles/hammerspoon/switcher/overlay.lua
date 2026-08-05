-- The switcher overlay: where the windows come from, how they are laid out and
-- drawn, and which one is selected.
--
-- Drawn here instead of using hs.window.switcher, because that module lays its
-- windows out in a single fixed row and builds on the deprecated hs.drawing.
--
-- Drawing and selection state are deliberately separate: `render` and `highlight`
-- take everything as parameters, so rendering a preview cannot disturb an overlay
-- that is currently on screen.

local ui = require("switcher.ui")

local M = {}

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

local function render(windows, screenFrame)
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

local function highlight(canvas, tiles, selected)
    for index, tile in ipairs(tiles) do
        local isSelected = index == selected
        canvas[tile.rect].fillColor = isSelected and ui.selectedTileColor or ui.tileColor
        canvas[tile.rect].strokeColor = isSelected and ui.selectedStrokeColor or ui.transparent
    end
end

local state = nil

-- Last resort against a modifier state that never reports itself as released,
-- which would otherwise leave the overlay on screen for good.
local maxOverlayLifetime = 30

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

local function modifiersHeld()
    local raw = hs.eventtap.checkKeyboardModifiers(true)._raw
    return raw > 0 and raw ~= 65536 -- caps lock alone does not count
end

function M.move(delta)
    if not state then return end

    local count = #state.windows
    state.selected = (state.selected - 1 + delta) % count + 1
    highlight(state.canvas, state.tiles, state.selected)
end

function M.moveRow(delta)
    if state then M.move(delta * state.columns) end
end

-- Closes the overlay and focuses whatever was selected.
function M.finish()
    local window = teardown()
    if window then
        window:unminimize()
        window:focus()
    end
end

function M.cancel()
    teardown()
end

function M.isVisible()
    return state ~= nil
end

local function show(source, delta)
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
    local canvas, layout, tiles = render(windows, screenFrame)

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
    state.modifierTimer = hs.timer.waitWhile(modifiersHeld, M.finish, 0.01)
    state.lifetimeTimer = hs.timer.doAfter(maxOverlayLifetime, M.cancel)
end

function M.showAllWindows(delta)
    show(allWindows, delta)
end

function M.showAppWindows(delta)
    show(frontmostAppWindows, delta)
end

-- Renders the overlay to a PNG without showing or focusing anything, for checking
-- the layout. `count` optionally repeats windows to simulate a fuller grid:
-- require("switcher").previewToFile("/tmp/switcher.png", 15)
function M.previewToFile(path, count)
    local windows = allWindows()
    if #windows == 0 then return false, "no windows" end

    if count then
        local padded = {}
        for i = 1, count do padded[i] = windows[(i - 1) % #windows + 1] end
        windows = padded
    end

    local screenFrame = (windows[1]:screen() or hs.screen.mainScreen()):frame()
    local canvas, layout, tiles = render(windows, screenFrame)
    highlight(canvas, tiles, 2)

    for index, window in ipairs(windows) do
        local image = snapshotFor(window, { w = layout.tileWidth, h = layout.thumbnailHeight })
        if image then canvas[tiles[index].thumbnail].image = image end
    end

    local written = canvas:imageFromCanvas():saveToFile(path)
    canvas:delete()

    return written
end

return M
