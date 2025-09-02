-- If LuaRocks is installed, make sure that packages installed through it are
-- found (e.g. lgi). If LuaRocks is not installed, do nothing.
pcall(require, "luarocks.loader")

require("error-handling")

require("awful.autofocus")

local awful = require("awful")
local gfs = require("gears.filesystem")

local config_dir = gfs.get_configuration_dir()
local script_dir = config_dir .. "scripts/"

awful.spawn.with_shell(script_dir .. "preferences.sh")
awful.spawn.with_shell(script_dir .. "autorun.sh")
awful.spawn.with_shell(script_dir .. "screenlock.sh start")

require("ui.misc.notifications")

require("config.keymaps.global-keys")
require("config.keymaps.client-keys")
require("config.keymaps.mouse")
require("config.tags")

require("config.signals")
require("config.rules")

require("theme")

require("ui")

require("modules.dynamic-wallpaper")
require("modules.auto-hibernate")
require("modules.vpn-auto-tunnel")
require("modules.session-mgr")
require("modules.window-swallowing")
