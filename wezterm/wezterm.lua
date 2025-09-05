local wezterm = require("wezterm")

local config = wezterm.config_builder()

-- Load configuration modules in order
require("config").apply(config)
require("platform").apply(config)
require("theme").apply(config)
require("modules").apply(config)

return config
