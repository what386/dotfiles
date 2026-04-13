local awful = require("awful")
local wibox = require("wibox")
local gears = require("gears")
local naughty = require("naughty")
local dpi = require("beautiful").xresources.apply_dpi
local clickable_container = require("ui.clickable-container")
local config = require("config.user.machine")
local userprefs = require("config.user.preferences")
local icons = require("theme.icons")

-- Interfaces
local interfaces = {
	wlan_interface = config.network_interface.wireless,
	lan_interface = config.network_interface.wired,
}

-- State
local network_mode = nil
local startup = true
local reconnect_startup = true
local wifi_strength = 0
local internet_healthy = true
local last_health_check = 0
local HEALTH_TTL_SECONDS = 30

-- Widget
local widget = wibox.widget({
	{
		id = "icon",
		image = icons.widgets.wifi.wifi_strength_off,
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
	awful.spawn(userprefs.default.network_manager, false)
end)))

local network_tooltip = awful.tooltip({
	text = "Loading...",
	objects = { widget_button },
	delay_show = 0.15,
})

-- Helpers

local function update_tooltip(message)
	network_tooltip:set_markup(message)
end

local function notify(message, title, icon)
	naughty.notification({
		message = message,
		title = title,
		icon = icon,
	})
end

-- Internet health check
local function check_internet_health_async(callback, force)
	local now = os.time()
	if not force and (now - last_health_check) < HEALTH_TTL_SECONDS then
		callback(internet_healthy)
		return
	end

	awful.spawn.easy_async_with_shell("ping -q -w1 -c1 1.1.1.1 >/dev/null 2>&1 && echo ok || echo no", function(stdout)
		internet_healthy = stdout:match("ok") ~= nil
		last_health_check = os.time()
		callback(internet_healthy)
	end)
end

-- Wireless update (iwd-safe)
local function update_wireless()
	network_mode = "wireless"

	awful.spawn.easy_async_with_shell("iw dev " .. interfaces.wlan_interface .. " link", function(stdout)
		if stdout:match("Not connected") then
			update_disconnected()
			return
		end

		local essid = stdout:match("SSID:%s*(.-)\n") or "N/A"
		local signal_dbm = tonumber(stdout:match("signal:%s*(-?%d+)"))
		local bitrate = stdout:match("tx bitrate:%s*([%d%.]+%s*MBit/s)") or "N/A"

		if not signal_dbm then
			update_disconnected()
			return
		end

		-- Convert dBm → %
		local strength = math.min(100, math.max(0, 2 * (signal_dbm + 100)))
		local rounded = math.floor(strength / 25 + 0.5)

		-- Icon
		local function set_icon(normal, alert)
			check_internet_health_async(function(healthy)
				if healthy then
					widget.icon:set_image(normal)
				else
					widget.icon:set_image(alert)
				end
			end)
		end

		if rounded <= 1 then
			set_icon(icons.widgets.wifi.wifi_strength_1, icons.widgets.wifi.wifi_strength_1_alert)
		elseif rounded == 2 then
			set_icon(icons.widgets.wifi.wifi_strength_2, icons.widgets.wifi.wifi_strength_2_alert)
		elseif rounded == 3 then
			set_icon(icons.widgets.wifi.wifi_strength_3, icons.widgets.wifi.wifi_strength_3_alert)
		else
			set_icon(icons.widgets.wifi.wifi_strength_4, icons.widgets.wifi.wifi_strength_4_alert)
		end

		-- Tooltip
		check_internet_health_async(function(healthy)
			local msg = "SSID: <b>"
				.. essid
				.. "</b>\n"
				.. "Signal: <b>"
				.. signal_dbm
				.. " dBm ("
				.. math.floor(strength)
				.. "%)</b>\n"
				.. "Bitrate: <b>"
				.. bitrate
				.. "</b>"

			if not healthy then
				msg = "<b>Connected but no internet!</b>\n" .. msg
			end

			update_tooltip(msg)
		end)

		-- Notify on connect
		if reconnect_startup or startup then
			notify('Connected to <b>"' .. essid .. '"</b>', "Connection Established", icons.widgets.wifi.wifi_on)
			reconnect_startup = false
			startup = false
			awesome.emit_signal("system::network_connected")
		end

		awesome.emit_signal("widget::network:ssid", essid)
	end)
end

-- Wired update
local function update_wired()
	network_mode = "wired"

	check_internet_health_async(function(healthy)
		if healthy then
			widget.icon:set_image(icons.widgets.ethernet.eth_connected)
			update_tooltip("Ethernet: <b>" .. interfaces.lan_interface .. "</b>")

			if reconnect_startup or startup then
				notify("Ethernet connected", "Connection Established", icons.widgets.ethernet.eth_connected)
				reconnect_startup = false
				startup = false
				awesome.emit_signal("system::network_connected")
			end
		else
			widget.icon:set_image(icons.widgets.ethernet.eth_no_route)
			update_tooltip("<b>No internet!</b>\nEthernet: <b>" .. interfaces.lan_interface .. "</b>")
		end
	end)
end

-- Disconnected
local function update_disconnected()
	widget.icon:set_image(icons.widgets.wifi.wifi_strength_off)
	update_tooltip("Network disconnected")

	if not reconnect_startup then
		reconnect_startup = true
		notify("Network disconnected", "Connection Lost", icons.widgets.wifi.wifi_off)
	end
end

local function read_operstate_async(interface, callback)
	awful.spawn.easy_async({ "cat", "/sys/class/net/" .. interface .. "/operstate" }, function(stdout, _, _, exit_code)
		if exit_code ~= 0 then
			callback(nil)
			return
		end

		local state = stdout and stdout:gsub("%s+$", "")
		if state == "" then
			state = nil
		end

		callback(state)
	end)
end

-- Mode detection
local function check_network_mode()
	local wlan = interfaces.wlan_interface
	local lan = interfaces.lan_interface

	read_operstate_async(lan, function(lan_state)
		read_operstate_async(wlan, function(wlan_state)
			if lan_state == "up" then
				update_wired()
			elseif wlan_state == "up" then
				update_wireless()
			else
				update_disconnected()
			end
		end)
	end)
end

-- React to NM events
awful.spawn.with_line_callback("nmcli monitor", {
	stdout = function()
		last_health_check = 0
		check_network_mode()
	end,
})

check_network_mode()

return widget_button
