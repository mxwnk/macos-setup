local function reloadConfig(files)
    for _, file in ipairs(files) do
        if file:sub(-4) == ".lua" then
            hs.reload()
            return
        end
    end
end

-- The watcher must be kept in a global variable, otherwise Lua garbage
-- collects it and the config stops reloading on save.
configWatcher = hs.pathwatcher.new(hs.configdir, reloadConfig):start()

hs.alert.show("Config update")
