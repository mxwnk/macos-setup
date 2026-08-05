-- Microphone mute for the system input device, so it works the same in Teams,
-- Meet and Slack instead of hunting for each app's own mute button.
--
-- Ctrl-Alt-M toggles, and so does clicking the menu bar item. The item is always
-- there and always shows the current state:
--   plain icon          input is idle, nobody is listening
--   icon + green dot    input is open and live
--   icon + red dot      input is open but muted, so nobody hears you
--
-- The app's own mute button stays independent: muting here does not un-press
-- Teams' button, which is exactly why the state is on screen permanently.

local M = {}

local icons = {
    open = hs.image.imageFromName("NSTouchBarAudioInputTemplate"),
    muted = hs.image.imageFromName("NSTouchBarAudioInputMuteTemplate"),
}

local dotFont = { name = ".AppleSystemUIFont", size = 11 }
local dots = {
    live = hs.styledtext.new(" ●", { color = { red = 0.2, green = 0.8, blue = 0.3 }, font = dotFont }),
    muted = hs.styledtext.new(" ●", { color = { red = 1.0, green = 0.25, blue = 0.25 }, font = dotFont }),
    idle = hs.styledtext.new("", { font = dotFont }),
}

local menuItem = hs.menubar.new()

-- Exposed so the state can be read back from the console:
-- hs -c "require('mic').menuItem:title()"
M.menuItem = menuItem

local function inputDevice()
    return hs.audiodevice.defaultInputDevice()
end

local function update()
    if not menuItem then return end

    local device = inputDevice()
    if not device then
        menuItem:setIcon(icons.muted, true)
        menuItem:setTitle(dots.idle)
        menuItem:setTooltip("No input device")
        return
    end

    local muted = device:inputMuted()
    -- Some devices report mute through the volume instead of a mute property.
    if muted == nil then muted = (device:inputVolume() or 0) == 0 end

    local inUse = device:inUse()

    menuItem:setIcon(muted and icons.muted or icons.open, true)
    menuItem:setTitle(inUse and (muted and dots.muted or dots.live) or dots.idle)
    menuItem:setTooltip(string.format("%s — %s%s",
        device:name(),
        muted and "muted" or "live",
        inUse and "" or ", idle"))
end

function M.toggle()
    local device = inputDevice()
    if not device then return end

    local muted = device:inputMuted()
    if muted == nil then
        -- Fall back to the volume for devices without a mute property.
        local volume = device:inputVolume() or 0
        device:setInputVolume(volume == 0 and (M.lastVolume or 50) or 0)
        if volume ~= 0 then M.lastVolume = volume end
    else
        device:setInputMuted(not muted)
    end

    update()
end

-- Mute changes arrive as device events, but whether an app is holding the input
-- open is only readable as a property, so that part is polled.
local watchedDevice = nil

local function watchDevice()
    if watchedDevice then watchedDevice:watcherStop() end

    watchedDevice = inputDevice()
    if not watchedDevice then return end

    watchedDevice:watcherCallback(function() update() end)
    watchedDevice:watcherStart()
end

M.pollTimer = hs.timer.doEvery(1, update)

-- Unplugging the RODE swaps the default input, so the watcher has to follow.
M.deviceWatcher = hs.audiodevice.watcher.setCallback(function()
    watchDevice()
    update()
end)
hs.audiodevice.watcher.start()

menuItem:setClickCallback(M.toggle)
hs.hotkey.bind({ "ctrl", "alt" }, "m", M.toggle)

watchDevice()
update()

return M
