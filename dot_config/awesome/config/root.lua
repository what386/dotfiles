local gears = require("gears")
local awful = require("awful")
local audio = require("services.audio")
local brightness = require("services.brightness")

local apps = require("configuration.apps")

root.buttons(gears.table.join(
	awful.button({}, 1, function()
		if mymainmenu then
			mymainmenu:hide()
		end
	end),
	awful.button({}, 3, function()
		if mymainmenu then
			mymainmenu:toggle()
		end
	end),
	awful.button({}, 2, function()
		awful.util.spawn(apps.default.rofi_appmenu)
	end),
	awful.button({ "Control" }, 2, function()
		awesome.emit_signal("module::exit_screen:show")
	end),
	awful.button({ "Shift" }, 2, function()
		awesome.emit_signal("widget::blue_light:toggle")
	end),
	awful.button({}, 4, function()
		brightness.change_level(10)
		awesome.emit_signal("osd::brightness_osd:show", true)
	end),
	awful.button({}, 5, function()
		brightness.change_level(-10)
		awesome.emit_signal("osd::brightness_osd:show", true)
	end),
	awful.button({ "Control" }, 4, function()
		audio.change_output_volume(5)
		awesome.emit_signal("osd::volume_osd:show", true)
	end),
	awful.button({ "Control" }, 5, function()
		audio.change_output_volume(-5)
		awesome.emit_signal("osd::volume_osd:show", true)
	end)
))
