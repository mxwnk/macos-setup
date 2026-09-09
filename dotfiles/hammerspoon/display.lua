-- Menu bar toggle for display sleep. A wake assertion overrides `pmset displaysleep`
-- outright, so this holds an assertion instead of touching the setting.
--
-- The state is drawn into the glyph rather than shown as a title beside it, because a
-- title changes the item's width and shifts every icon to its left.

local M = {}

local iconPoints = 18

-- Drawn at 2x and scaled back down, so the glyph stays crisp on retina.
local renderScale = 2

local tints = {
    idle = { white = 1, alpha = 1 },
    awake = { red = 1.0, green = 0.72, blue = 0.15, alpha = 1 },
    blocked = { red = 1.0, green = 0.33, blue = 0.28, alpha = 1 },
}

-- Only idle is templated, so macOS tints it for the current appearance. Templating the
-- other two would discard their colour.
local templateStates = {
    idle = true,
    awake = false,
    blocked = false,
}

local function addBezel(canvas, tint)
    canvas[#canvas + 1] = {
        type = "rectangle",
        action = "stroke",
        strokeColor = tint,
        strokeWidth = 1.5 * renderScale,
        roundedRectRadii = { xRadius = 2.5 * renderScale, yRadius = 2.5 * renderScale },
        frame = { x = 1.6 * renderScale, y = 2.2 * renderScale, w = 14.8 * renderScale, h = 10.4 * renderScale },
    }
end

local function addStand(canvas, tint)
    canvas[#canvas + 1] = {
        type = "rectangle",
        action = "fill",
        fillColor = tint,
        frame = { x = 8.1 * renderScale, y = 12.4 * renderScale, w = 1.8 * renderScale, h = 2.1 * renderScale },
    }
    canvas[#canvas + 1] = {
        type = "rectangle",
        action = "fill",
        fillColor = tint,
        roundedRectRadii = { xRadius = 0.7 * renderScale, yRadius = 0.7 * renderScale },
        frame = { x = 5.2 * renderScale, y = 14.2 * renderScale, w = 7.6 * renderScale, h = 1.5 * renderScale },
    }
end

local function addLitScreen(canvas, tint)
    canvas[#canvas + 1] = {
        type = "rectangle",
        action = "fill",
        fillColor = tint,
        roundedRectRadii = { xRadius = 1 * renderScale, yRadius = 1 * renderScale },
        frame = { x = 4.1 * renderScale, y = 4.7 * renderScale, w = 9.8 * renderScale, h = 5.4 * renderScale },
    }
end

local function monitorIcon(tint, isScreenLit)
    local canvas = hs.canvas.new({
        x = 0,
        y = 0,
        w = iconPoints * renderScale,
        h = iconPoints * renderScale,
    })

    addBezel(canvas, tint)
    addStand(canvas, tint)
    if isScreenLit then addLitScreen(canvas, tint) end

    local image = canvas:imageFromCanvas()
    canvas:delete()

    -- setSize returns a resized copy rather than mutating.
    return image:setSize({ w = iconPoints, h = iconPoints })
end

local icons = {
    idle = monitorIcon(tints.idle, false),
    awake = monitorIcon(tints.awake, true),
    blocked = monitorIcon(tints.blocked, true),
}

local menuItem = hs.menubar.new()

M.menuItem = menuItem

-- powerd's InternalPreventDisplaySleep is left out on purpose: it is a short-lived
-- proxy and would report a permanent blocker.
local displaySleepBlockers = {
    PreventUserIdleDisplaySleep = true,
    NoDisplaySleepAssertion = true,
}

local ownProcessId = hs.processInfo.processID

local function findBlockerName(assertions)
    for _, assertion in ipairs(assertions) do
        if displaySleepBlockers[assertion.AssertType] then
            return assertion["Process Name"]
        end
    end

    return nil
end

-- hs.caffeinate.get already covers our own assertion, so only foreign ones matter here.
local function blockingProcessName()
    for processId, assertions in pairs(hs.caffeinate.currentAssertions()) do
        if processId ~= ownProcessId then
            local name = findBlockerName(assertions)
            if name then return name end
        end
    end

    return nil
end

-- hs.menubar has no tooltip getter, so this doubles as the way to read the state back:
-- hs -c "select(2, require('display').status())"
function M.status()
    if hs.caffeinate.get("displayIdle") then
        return "awake", "Display kept awake — click to let it sleep"
    end

    local blocker = blockingProcessName()
    if blocker then
        return "blocked", string.format("Kept awake by %s", blocker)
    end

    return "idle", "Display sleeps normally — click to keep it awake"
end

-- The description changes with the blocking app too, so it works as the cache key.
local renderedDescription = nil

local function update()
    if not menuItem then return end

    local state, description = M.status()
    if description == renderedDescription then return end

    renderedDescription = description
    menuItem:setIcon(icons[state], templateStates[state])
    menuItem:setTooltip(description)
end

function M.toggle()
    hs.caffeinate.toggle("displayIdle")
    update()
end

-- Only foreign assertions need polling; our own changes arrive through the click.
M.pollTimer = hs.timer.doEvery(5, update)

if menuItem then
    menuItem:setClickCallback(M.toggle)
end

update()

return M
