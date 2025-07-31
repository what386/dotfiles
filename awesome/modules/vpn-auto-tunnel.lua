local awful = require("awful")
local naughty = require("naughty")
local icons = require("theme.icons")

local vpn_connected = false

local trusted_networks = {
	"acapron",
}

local vpn_notify = function(message, title, app_name, icon)
	naughty.notification({
		message = message,
		title = title,
		app_name = app_name,
		icon = icon,
	})
end

local notify_vpn_connected = function()
	local message = "VPN tunnel has been enabled"
	local title = "Connected to untrusted network"
	local app_name = "System Notification"
	local icon = icons.widgets.wifi.wifi_on
	vpn_notify(message, title, app_name, icon)
end

local notify_vpn_disconnected = function()
	local message = "VPN tunnel has been disabled"
	local title = "Connected to trusted network"
	local app_name = "System Notification"
	local icon = icons.widgets.wifi.wifi_on
	vpn_notify(message, title, app_name, icon)
end

local function is_trusted_network(network)
	for _, trusted_network in ipairs(trusted_networks) do
		if network == trusted_network then
			return true
		end
	end

	return false
end

awesome.connect_signal("widget::network:ssid", function(ssid)
	if is_trusted_network(ssid) then
		if vpn_connected then
			awful.spawn("sudo /usr/bin/wg-quick down thinkpad-t480s")
			vpn_connected = false
			notify_vpn_disconnected()
		end
	elseif not vpn_connected then
		awful.spawn("sudo /usr/bin/wg-quick up thinkpad-t480s")
		vpn_connected = true
		notify_vpn_connected()
	end
end)
