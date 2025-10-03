local function reloadConfig()
    hs.reload()
end

hs.pathwatcher.new(hs.configdir, reloadConfig):start()
hs.alert.show("Config update")