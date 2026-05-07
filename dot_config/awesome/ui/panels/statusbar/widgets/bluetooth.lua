local awful = require("awful")
local wibox = require("wibox")
local gears = require("gears")
local dpi = require("beautiful").xresources.apply_dpi
local clickable_container = require("ui.clickable-container")
local icons = require("theme.icons")
local bluetooth = require("services.bluetooth")

local widget = wibox.widget({ { id = "icon", image = icons.widgets.bluetooth.bluetooth_off, widget = wibox.widget.imagebox, resize = true }, layout = wibox.layout.align.horizontal })
local widget_button = wibox.widget({ { widget, margins = dpi(6), widget = wibox.container.margin }, widget = clickable_container })
local bluetooth_tooltip = awful.tooltip({ objects = { widget_button }, delay_show = 0.15, mode = "outside", align = "right", margin_leftright = dpi(8), margin_topbottom = dpi(8), preferred_positions = { "right", "left", "top", "bottom" } })

local function xml_escape(text)
	return tostring(text or ""):gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"):gsub('"', "&quot;"):gsub("'", "&apos;")
end

local function render(state)
	state = state or bluetooth.get_state()
	if not state.enabled then
		widget.icon:set_image(icons.widgets.bluetooth.bluetooth_off)
		bluetooth_tooltip.markup = "Bluetooth is off"
		return
	end
	local lines = { "Bluetooth is on" }
	if state.details_unavailable then
		widget.icon:set_image(icons.widgets.bluetooth.bluetooth_on)
		table.insert(lines, "Connected devices unavailable")
	elseif #state.devices == 0 then
		widget.icon:set_image(icons.widgets.bluetooth.bluetooth_on)
		table.insert(lines, "No connected devices")
	else
		widget.icon:set_image(icons.widgets.bluetooth.bluetooth_connected)
		table.insert(lines, "Connected devices: <b>" .. tostring(#state.devices) .. "</b>")
		for _, device in ipairs(state.devices) do
			local line = "• <b>" .. xml_escape(device.name) .. "</b>"
			if device.battery ~= nil then line = line .. " (" .. tostring(device.battery) .. "%)" end
			table.insert(lines, line)
		end
	end
	bluetooth_tooltip.markup = table.concat(lines, "\n")
end

widget_button:buttons(gears.table.join(awful.button({}, 1, nil, bluetooth.open_manager)))
widget_button:connect_signal("mouse::enter", bluetooth.refresh)
awesome.connect_signal("bluetooth::state", render)
render(bluetooth.get_state())

return widget_button
