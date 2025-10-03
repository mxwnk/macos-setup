-- General Apps:
local apps = {
    c = "Slack",
    e = "Cursor", -- Editor
    f = "Marta",
    g = "Google Meet",
    i = "IntelliJ IDEA",
    o = "Obsidian",
    q = "Signal",
    s = "Spotify",
    t = "iTerm",
    w = "Microsoft Teams",
}

for key, app in pairs(apps) do
    hs.hotkey.bind({ "alt" }, key, function() hs.application.launchOrFocus(app) end)
end

hs.hotkey.bind({ "alt" }, "1", function()
    hs.application.launchOrFocus("Google Chrome")
end)

hs.hotkey.bind({ "alt" }, "2", function()
    hs.application.launchOrFocus("Google Chrome Dev")
end)
