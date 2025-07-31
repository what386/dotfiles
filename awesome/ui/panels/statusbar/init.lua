-- Required libraries
local gears = require("gears")
local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("beautiful")
local xresources = beautiful.xresources
local dpi = xresources.apply_dpi
local widgetdir = "ui.panels.statusbar.widgets."

local tasklist = require("ui.panels.statusbar.applets.tasklist")

local battery_widget = require(widgetdir .. "battery")
local clock_widget = require(widgetdir .. "clock")
local volume_widget = require(widgetdir .. "volume")
local network_widget = require(widgetdir .. "network")
local bluetooth_widget = require(widgetdir .. "bluetooth")

local layoutbox_widget = require(widgetdir .. "layoutbox")
local infopanel_widget = require(widgetdir .. "infopanel-toggle")

local dropdown_widget = require(widgetdir .. "dropdown")

local separator = wibox.widget({
	orientation = "vertical",
	forced_height = dpi(1),
	forced_width = dpi(1),
	span_ratio = 0.55,
	widget = wibox.widget.separator,
})

local right_widgets = wibox.widget({
	{
		bluetooth_widget,
		network_widget,
		volume_widget,
		battery_widget,
		spacing = dpi(8),
		layout = wibox.layout.fixed.horizontal,
	},
	margins = { top = dpi(1), bottom = dpi(1) },
	widget = wibox.container.margin,
})

local function statusbar(s)
	statusbar = awful.wibar({
		screen = s,
		position = "top",
		type = "dock",
		stretch = false,
		visible = true,
		height = dpi(35),
		width = s.geometry.width,
		bg = beautiful.background,
		fg = beautiful.system_white_dark,
		opacity = 1,
	})

	statusbar:setup({
		expand = "none",
		layout = wibox.layout.align.horizontal,
		{ -- left
			layoutbox_widget(s),
			separator,
			tasklist(s),
			spacing = dpi(8),
			layout = wibox.layout.fixed.horizontal,
		},
		-- middle
		clock_widget(s),
		{ -- right
			dropdown_widget,
			right_widgets,
			separator,
			infopanel_widget,
			spacing = dpi(8),
			layout = wibox.layout.fixed.horizontal,
		},
	})
end

return statusbar
