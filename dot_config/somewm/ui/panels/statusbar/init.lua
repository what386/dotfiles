-- Required dependencies
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
local vpn_widget = require(widgetdir .. "vpn-status")
--local sd_card_widget = require(widgetdir .. "sd-card")
local layoutbox_widget = require(widgetdir .. "layoutbox")
local infopanel_widget = require(widgetdir .. "infopanel-toggle")
local dropdown_widget = require(widgetdir .. "dropdown")
local osk_widget = require(widgetdir .. "osk-toggle")
local update_widget = require(widgetdir .. "update-manager")

local function separator()
	return wibox.widget({
		orientation = "vertical",
		forced_height = dpi(1),
		forced_width = dpi(1),
		span_ratio = 0.55,
		widget = wibox.widget.separator,
	})
end

local function right_widgets(s)
	local items = wibox.layout.fixed.horizontal()
	items.spacing = dpi(8)
	-- Update checks run once because they invoke several external commands.
	if s == screen.primary then items:add(update_widget) end
	items:add(vpn_widget())
	items:add(bluetooth_widget())
	items:add(network_widget())
	items:add(volume_widget())
	items:add(battery_widget())
	return wibox.widget({
		items,
		margins = { top = dpi(1), bottom = dpi(1) },
		widget = wibox.container.margin,
	})
end

-- Store statusbars for each screen
local statusbars = {}

-- Function to check if current client is fullscreen and update statusbar visibility
local function update_statusbar_visibility(s)
	local statusbar = statusbars[s]
	if not statusbar then
		return
	end

	for _, c in ipairs(client.get()) do
		if c.valid and c.screen == s and c.fullscreen and c:isvisible() then
			statusbar.visible = false
			return
		end
	end
	statusbar.visible = true
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
		stretch = true,
		visible = true,
		height = dpi(35),
		bg = beautiful.background,
		fg = beautiful.system_white_dark,
		opacity = 1,
	})

	bar:setup({
		expand = "none",
		layout = wibox.layout.align.horizontal,
		{ -- left
			layoutbox_widget(s),
			osk_widget(),
			separator(),
			clock_widget(s),
			spacing = dpi(8),
			layout = wibox.layout.fixed.horizontal,
		},
		-- middle
		tasklist(s),
		{ -- right
			s == screen.primary and dropdown_widget() or nil,
			right_widgets(s),
			separator(),
			infopanel_widget(),
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
client.connect_signal("request::unmanage", update_all_statusbars)

-- Handle screen changes
screen.connect_signal("removed", function(s)
	statusbars[s] = nil
end)

return statusbar
