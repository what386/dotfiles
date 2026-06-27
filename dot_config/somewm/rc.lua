require("awesome")
-- If LuaRocks is installed, make sure that packages installed through it are
-- found (e.g. lgi). If LuaRocks is not installed, do nothing.
pcall(require, "luarocks.loader")

require("error-handling")

require("awful.autofocus")

local awful = require("awful")
local gfs = require("gears.filesystem")
local process = require("utilities.process")

local config_dir = gfs.get_configuration_dir()
local script_dir = config_dir .. "scripts/"

-- Disable built-in snapping/edge tiling; custom snap-layouts module handles this.
awful.mouse.snap.edge_enabled = false
awful.mouse.snap.client_enabled = false

process.spawn(script_dir .. "autorun.sh")

-- TODO: replace with someWM native
--awful.spawn.with_shell(script_dir .. "screenlock.sh start")

if awesome.scenefx then
    awesome.set_blur_data(2, 5, 0.02, 0.9, 0.9, 1.0)
end

require("services")

require("config.input")
require("config.keymaps")

require("config.signals")
require("config.rules")

require("theme")

--local sounds = require("theme.sounds")
--if awesome.startup then
--	sounds.play("login")
--end

require("ui")

--require("modules.dynamic-wallpaper")
