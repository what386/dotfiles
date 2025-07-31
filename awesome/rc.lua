-- If LuaRocks is installed, make sure that packages installed through it are
-- found (e.g. lgi). If LuaRocks is not installed, do nothing.
pcall(require, "luarocks.loader")

local naughty = require("naughty")
-- Error handling
naughty.connect_signal("request::display_error", function(message, startup)
	naughty.notification({
		urgency = "critical",
		title = "Oops, an error happened" .. (startup and " during startup!" or "!"),
		message = message,
		app_name = "System Notification",
		icon = beautiful.awesome_icon,
	})
end)

require("awful.autofocus")

local awful = require("awful")
local gfs = require("gears.filesystem")

local config_dir = gfs.get_configuration_dir()
local script_dir = config_dir .. "/scripts/"

awful.spawn.with_shell(script_dir .. "preferences.sh")
awful.spawn.with_shell(script_dir .. "autorun.sh")

require("config.keymaps.global-keys")
require("config.keymaps.client-keys")
require("config.keymaps.mouse")
require("config.tags")

require("config.signals")
require("config.rules")

require("theme")

require("ui")

-- this module "flashes" newly focused clients
-- i dont like it, but its cool so it stays
--require("modules.flashfocus")

require("modules.dynamic-wallpaper")
require("modules.auto-hibernate")
require("modules.vpn-auto-tunnel")
require("modules.session-mgr")
require("modules.window-swallowing")

-- This uses the camera to determine room brightness
-- so if you have a "camera light" it gets very annoying
-- comment out if unused, or keep it disabled in settings
require("modules.auto-brightness")
