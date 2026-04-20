local awful = require("awful")
local wibox = require("wibox")
local gears = require("gears")
local dpi = require("beautiful").xresources.apply_dpi

local userprefs = require("config.user.preferences")

local clickable_container = require("ui.clickable-container")

local icons = require("theme.icons")

local widget = wibox.widget({
	{
		id = "icon",
		image = icons.widgets.bluetooth.bluetooth_off,
		widget = wibox.widget.imagebox,
		resize = true,
	},
	layout = wibox.layout.align.horizontal,
})

local widget_button = wibox.widget({
	{
		widget,
		margins = dpi(6),
		widget = wibox.container.margin,
	},
	widget = clickable_container,
})

widget_button:buttons(gears.table.join(awful.button({}, 1, nil, function()
	awful.spawn(userprefs.default.bluetooth_manager, false)
end)))

local bluetooth_tooltip = awful.tooltip({
	objects = { widget_button },
	delay_show = 0.15,
	mode = "outside",
	align = "right",
	margin_leftright = dpi(8),
	margin_topbottom = dpi(8),
	preferred_positions = { "right", "left", "top", "bottom" },
})

local refresh_generation = 0

local function xml_escape(text)
	return (tostring(text or ""):gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"):gsub('"', "&quot;"):gsub("'", "&apos;"))
end

local function parse_connected_devices(stdout)
	local devices = {}

	for line in stdout:gmatch("[^\r\n]+") do
		local address, name = line:match("^Device%s+([%x:]+)%s+(.+)$")
		if address then
			table.insert(devices, {
				address = address,
				name = name or address,
				battery = nil,
			})
		end
	end

	return devices
end

local function parse_battery_percent(stdout)
	for line in stdout:gmatch("[^\r\n]+") do
		local battery_raw = line:match("^%s*Battery Percentage:%s*(.+)$")
		if battery_raw then
			local direct_percent = tonumber(battery_raw:match("(%d+)%%"))
			if direct_percent then
				return math.max(0, math.min(100, direct_percent))
			end

			local bracket_percent = tonumber(battery_raw:match("%((%d+)%)"))
			if bracket_percent then
				return math.max(0, math.min(100, bracket_percent))
			end

			local numeric_percent = tonumber(battery_raw:match("^(%d+)$"))
			if numeric_percent then
				return math.max(0, math.min(100, numeric_percent))
			end

			local hex_percent = battery_raw:match("0x(%x+)")
			if hex_percent then
				local decoded = tonumber(hex_percent, 16)
				if decoded then
					return math.max(0, math.min(100, decoded))
				end
			end
		end
	end

	return nil
end

local function set_off_state()
	widget.icon:set_image(icons.widgets.bluetooth.bluetooth_off)
	bluetooth_tooltip.markup = "Bluetooth is off"
end

local function set_on_state(devices, details_unavailable)
	local lines = { "Bluetooth is on" }

	if details_unavailable then
		widget.icon:set_image(icons.widgets.bluetooth.bluetooth_on)
		table.insert(lines, "Connected devices unavailable")
		bluetooth_tooltip.markup = table.concat(lines, "\n")
		return
	end

	if #devices == 0 then
		widget.icon:set_image(icons.widgets.bluetooth.bluetooth_on)
		table.insert(lines, "No connected devices")
	else
		widget.icon:set_image(icons.widgets.bluetooth.bluetooth_connected)
		table.insert(lines, "Connected devices: <b>" .. #devices .. "</b>")

		for _, device in ipairs(devices) do
			local line = "• <b>" .. xml_escape(device.name) .. "</b>"
			if device.battery ~= nil then
				line = line .. " (" .. tostring(device.battery) .. "%)"
			end
			table.insert(lines, line)
		end
	end

	bluetooth_tooltip.markup = table.concat(lines, "\n")
end

local function refresh_state()
	refresh_generation = refresh_generation + 1
	local generation = refresh_generation

	awful.spawn.easy_async({ "rfkill", "list", "bluetooth" }, function(stdout, _, _, exit_code)
		if generation ~= refresh_generation then
			return
		end

		if exit_code ~= 0 or stdout:match("Soft blocked:%s*yes") then
			set_off_state()
			return
		end

		awful.spawn.easy_async({ "bluetoothctl", "devices", "Connected" }, function(devices_stdout, _, _, devices_exit_code)
			if generation ~= refresh_generation then
				return
			end

			if devices_exit_code ~= 0 then
				set_on_state({}, true)
				return
			end

			local devices = parse_connected_devices(devices_stdout)
			if #devices == 0 then
				set_on_state(devices, false)
				return
			end

			local pending = #devices
			for _, device in ipairs(devices) do
				awful.spawn.easy_async({ "bluetoothctl", "info", device.address }, function(info_stdout, _, _, info_exit_code)
					if generation ~= refresh_generation then
						return
					end

					if info_exit_code == 0 then
						device.battery = parse_battery_percent(info_stdout)
					end

					pending = pending - 1
					if pending == 0 then
						set_on_state(devices, false)
					end
				end)
			end
		end)
	end)
end

awful.spawn.with_line_callback("rfkill event", {
	stdout = function(_)
		refresh_state()
	end,
})

widget_button:connect_signal("mouse::enter", refresh_state)

gears.timer({
	timeout = 45,
	autostart = true,
	call_now = true,
	callback = refresh_state,
})

return widget_button
