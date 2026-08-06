-- Spoons
hs.loadSpoon("EmmyLua")

-- Message port for the `hs` command line tool
require("hs.ipc")

-- User config
require("config")
require("urlhandler")
require("mic")

-- Window switching and the app hotkeys moved to Flip, a native switcher:
-- https://github.com/mxwnk/flip. Both are off rather than just the switcher,
-- because apps.lua requires switcher and drives its overlay — one without the
-- other does not load. Two event taps grabbing Alt-Tab would fight anyway.
-- require("apps")
-- require("switcher")
