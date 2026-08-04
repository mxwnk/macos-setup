-- URL Handler: Routes links to Chrome or Chrome Dev based on URL patterns.
-- Hold Alt when clicking a link to force it to open in Chrome Dev.

local CHROME = "com.google.Chrome"
local CHROME_DEV = "com.google.Chrome.dev"

local chromePatterns = {
    "jira%.",
    "confluence%.",
}

local chromeDevPatterns = {
    "localhost",
    "github%.com",
    "linkedin%.com",
}

local function matchesAnyPattern(url, patterns)
    for _, pattern in ipairs(patterns) do
        if string.find(url, pattern) then
            return true
        end
    end
    return false
end

local function determineBrowser(url)
    if matchesAnyPattern(url, chromeDevPatterns) then
        return CHROME_DEV
    end

    if matchesAnyPattern(url, chromePatterns) then
        return CHROME
    end

    return CHROME
end

local function openUrl(url)
    local altPressed = hs.eventtap.checkKeyboardModifiers().alt

    local bundleId
    if altPressed then
        bundleId = CHROME_DEV
        hs.printf("[urlhandler] Alt pressed, forcing Chrome Dev")
    else
        bundleId = determineBrowser(url)
    end

    hs.printf("[urlhandler] Opening URL: %s -> %s", url, bundleId)
    local success = hs.urlevent.openURLWithBundle(url, bundleId)
    hs.printf("[urlhandler] openURLWithBundle returned: %s", tostring(success))
end

hs.urlevent.httpCallback = function(scheme, host, params, fullURL)
    hs.printf("[urlhandler] httpCallback triggered: scheme=%s host=%s fullURL=%s", scheme or "nil", host or "nil", fullURL or "nil")
    openUrl(fullURL)
end

hs.printf("[urlhandler] Module loaded, httpCallback registered")
