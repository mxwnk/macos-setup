-- Window switching, replaces AltTab.app:
--   Alt-Tab        cycles through all windows on the current space
--   Cmd-Tab        cycles through the windows of the frontmost application
-- Add Shift to either one to cycle backwards. Hold the modifier to keep the
-- overlay open, use Tab or the left/right arrow keys to move the selection, and
-- release the modifier to focus the selected window.

local ui = {
    textSize = 12,
    showTitles = true,
    showThumbnails = true,
    thumbnailSize = 128,
    showSelectedThumbnail = false,
    backgroundColor = { 0.1, 0.1, 0.1, 0.9 },
    highlightColor = { 0.4, 0.4, 0.5, 0.8 },
}

-- Visible standard windows only, and only on the space we are currently on.
local windowRules = {
    visible = true,
    currentSpace = true,
    allowRoles = "AXStandardWindow",
}

local allWindowsSwitcher = hs.window.switcher.new(
    hs.window.filter.new():setDefaultFilter(windowRules),
    ui
)

hs.hotkey.bind({ "alt" }, "tab", function() allWindowsSwitcher:next() end)
hs.hotkey.bind({ "alt", "shift" }, "tab", function() allWindowsSwitcher:previous() end)

-- One switcher per application, built on first use and then reused, because a
-- window filter is bound to a fixed app name.
local appSwitchers = {}

local function frontmostAppSwitcher()
    local app = hs.application.frontmostApplication()
    if not app then return nil end

    local key = app:bundleID() or app:name()
    if not appSwitchers[key] then
        local filter = hs.window.filter.new(false):setAppFilter(app:name(), windowRules)
        appSwitchers[key] = hs.window.switcher.new(filter, ui)
    end

    return appSwitchers[key]
end

-- Whichever overlay is currently on screen, or nil if none is. `selected` is an
-- internal field of hs.window.switcher, set while the overlay is up and cleared
-- when it closes.
local function visibleSwitcher()
    if allWindowsSwitcher.selected then return allWindowsSwitcher end

    for _, switcher in pairs(appSwitchers) do
        if switcher.selected then return switcher end
    end

    return nil
end

local arrowDirections = {
    [hs.keycodes.map.right] = "next",
    [hs.keycodes.map.left] = "previous",
}

-- Arrow keys move the selection, but only while an overlay is actually open, so
-- that Alt-Left and Alt-Right keep working as word-wise movement everywhere else.
local function handleArrowKey(event)
    local direction = arrowDirections[event:getKeyCode()]
    if not direction then return false end

    local switcher = visibleSwitcher()
    if not switcher then return false end

    switcher[direction](switcher)
    return true
end

-- macOS reserves Cmd-Tab for its own application switcher and refuses to hand it
-- over to hs.hotkey (RegisterEventHotKey fails with -9878), so the key has to be
-- caught one layer down and swallowed before the Dock ever sees it.
local function handleCmdTab(event)
    if event:getKeyCode() ~= hs.keycodes.map.tab then return false end

    local flags = event:getFlags()
    local switcher = frontmostAppSwitcher()

    if flags:containExactly({ "cmd" }) then
        if switcher then switcher:next() end
    elseif flags:containExactly({ "cmd", "shift" }) then
        if switcher then switcher:previous() end
    else
        return false
    end

    return true
end

local function handleKey(event)
    return handleArrowKey(event) or handleCmdTab(event)
end

-- Kept in a global so the tap survives garbage collection, same as the config
-- watcher in config.lua.
switcherTap = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, handleKey):start()
