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
local dashboard_widget = require(widgetdir .. "dashboard-toggle")
local dropdown_widget = require(widgetdir .. "dropdown")
local osk_widget = require(widgetdir .. "osk-toggle")
local update_widget = require(widgetdir .. "update-manager")

local separator = wibox.widget({
	orientation = "vertical",
	forced_height = dpi(1),
	forced_width = dpi(1),
	span_ratio = 0.55,
	widget = wibox.widget.separator,
})

local right_widgets = wibox.widget({
	{
		update_widget,
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

-- Store statusbars for each screen
local statusbars = {}

-- Function to check if current client is fullscreen and update statusbar visibility
local function update_statusbar_visibility(s)
	local statusbar = statusbars[s]
	if not statusbar then
		return
	end

	local c = client.focus
	if c and c.screen == s and c.fullscreen then
		statusbar.visible = false
	else
		statusbar.visible = true
	end
end

-- Function to update all statusbars
local function update_all_statusbars()
	for s in screen do
		update_statusbar_visibility(s)
	end
end

local function statusbar(s)
	local bar = awful.wibar({
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

	bar:setup({
		expand = "none",
		layout = wibox.layout.align.horizontal,
		{ -- left
			dashboard_widget,
			osk_widget,
			separator,
			clock_widget(s),
			spacing = dpi(8),
			layout = wibox.layout.fixed.horizontal,
		},
		-- middle
		tasklist(s),
		{ -- right
			dropdown_widget,
			right_widgets,
			separator,
			layoutbox_widget(s),
			spacing = dpi(8),
			layout = wibox.layout.fixed.horizontal,
		},
	})

	-- Store the statusbar for this screen
	statusbars[s] = bar

	return bar
end

-- Connect signals to handle fullscreen changes
client.connect_signal("focus", update_all_statusbars)
client.connect_signal("unfocus", update_all_statusbars)
client.connect_signal("property::fullscreen", update_all_statusbars)
client.connect_signal("unmanage", update_all_statusbars)

-- Handle screen changes
screen.connect_signal("removed", function(s)
	statusbars[s] = nil
end)

return statusbar
