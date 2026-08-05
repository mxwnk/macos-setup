-- App hotkeys: Alt plus a key brings the app to the front. Pressing it again
-- while the app is already in front opens the switcher overlay for that app's
-- windows, so one key both reaches an app and walks through its windows.

local switcher = require("switcher")

-- Keyed by bundle ID rather than by name, because name lookups are ambiguous:
-- "Cursor" also matches a macOS text input service, and "Google Chrome" also
-- matches "Google Chrome Dev".
local apps = {
    c = "com.tinyspeck.slackmacgap",                              -- Slack
    e = "com.todesktop.230313mzl4w4u92",                          -- Cursor
    f = "org.yanex.marta",                                        -- Marta
    g = "com.google.Chrome.app.kjgfgldnnfoeklkmfkjfagphfepbbdan", -- Google Meet
    i = "com.jetbrains.intellij",                                 -- IntelliJ IDEA
    j = "dev.zed.Zed",                                            -- Zed
    o = "md.obsidian",                                            -- Obsidian
    q = "org.whispersystems.signal-desktop",                      -- Signal
    s = "com.spotify.client",                                     -- Spotify
    t = "com.mitchellh.ghostty",                                  -- Ghostty
    ["f1"] = "com.mitchellh.ghostty",                             -- Ghostty
    w = "com.microsoft.teams2",                                   -- Microsoft Teams
    ["1"] = "com.google.Chrome",                                  -- Google Chrome
    ["2"] = "com.google.Chrome.dev",                              -- Google Chrome Dev
}

local M = {}

function M.activate(bundleID)
    local frontmost = hs.application.frontmostApplication()

    if frontmost and frontmost:bundleID() == bundleID then
        -- Alt is still held at this point, so the overlay behaves exactly like
        -- Cmd-Tab: keep tapping to walk on, release Alt to pick.
        if switcher.appWindowCount() > 1 then switcher.showAppWindows(1) end
        return
    end

    -- A leftover overlay would focus its own selection once Alt is released and
    -- undo the switch we are about to make.
    switcher.cancel()
    hs.application.launchOrFocusByBundleID(bundleID)
end

for key, bundleID in pairs(apps) do
    hs.hotkey.bind({ "alt" }, key, function() M.activate(bundleID) end)
end

return M
