-- Window switching, replaces AltTab.app:
--   Alt-Tab        cycles through all windows on the current space
--   Cmd-Tab        cycles through the windows of the frontmost application
-- Add Shift to either one to cycle backwards. While the overlay is up, the arrow
-- keys move the selection and Escape cancels. Release the modifier to focus the
-- selected window.
--
-- This is the only file that binds keys; everything else lives in overlay.lua.

local overlay = require("switcher.overlay")

hs.hotkey.bind({ "alt" }, "tab", function() overlay.showAllWindows(1) end)
hs.hotkey.bind({ "alt", "shift" }, "tab", function() overlay.showAllWindows(-1) end)

local overlayActions = {
    [hs.keycodes.map.right] = function() overlay.move(1) end,
    [hs.keycodes.map.left] = function() overlay.move(-1) end,
    [hs.keycodes.map.down] = function() overlay.moveRow(1) end,
    [hs.keycodes.map.up] = function() overlay.moveRow(-1) end,
    [hs.keycodes.map.escape] = overlay.cancel,
}

-- Arrow keys and Escape are only taken while the overlay is up, so that they
-- keep working normally everywhere else.
local function handleOverlayKey(event)
    local action = overlayActions[event:getKeyCode()]
    if not action or not overlay.isVisible() then return false end

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
        overlay.showAppWindows(1)
    elseif flags:containExactly({ "cmd", "shift" }) then
        overlay.showAppWindows(-1)
    else
        return false
    end

    return true
end

-- Polling the system modifier state can go stale, and a stale "still held" reading
-- would keep the overlay up for good. The release event itself does not go stale,
-- so it closes the overlay too. Caps lock is ignored on purpose.
local function handleFlagsChanged(event)
    if not overlay.isVisible() then return false end

    local flags = event:getFlags()
    if not (flags.cmd or flags.alt or flags.ctrl or flags.shift or flags.fn) then
        overlay.finish()
    end

    return false
end

local function handleEvent(event)
    if event:getType() == hs.eventtap.event.types.flagsChanged then
        return handleFlagsChanged(event)
    end

    return handleOverlayKey(event) or handleCmdTab(event)
end

-- Kept on the module, which require() holds onto, so the tap is not garbage
-- collected. Stopping it restores the system Cmd-Tab:
-- hs -c "require('switcher').tap:stop()"
overlay.tap = hs.eventtap.new({
    hs.eventtap.event.types.keyDown,
    hs.eventtap.event.types.flagsChanged,
}, handleEvent):start()

return overlay
