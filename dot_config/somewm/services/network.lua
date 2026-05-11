local gears = require("gears")
local naughty = require("naughty")
local machine = require("config.user.machine")
local prefs = require("config.user.preferences")
local icons = require("theme.icons")
local process = require("services.process")
local settings = require("modules.settings-store")

local network = {}

local interfaces = {
	wlan = machine.network_interface.wireless,
	lan = machine.network_interface.wired,
}

local trusted_networks = { "acapron" }
local state = {
	mode = nil,
	connected = false,
	ssid = "unknown",
	signal_dbm = nil,
	strength = 0,
	bitrate = "N/A",
	internet_healthy = true,
	startup = true,
	reconnect_startup = true,
	last_health_check = 0,
	vpn_connected = false,
	vpn_interface = "happycloud",
	trusted = nil,
	airplane_mode = settings.get_bool("airplane_mode", false),
}

local function is_trusted(ssid)
	for _, trusted in ipairs(trusted_networks) do
		if ssid == trusted then return true end
	end
	return false
end

local function emit_state()
	awesome.emit_signal("network::state", network.get_state())
	if state.connected then awesome.emit_signal("network::connected", network.get_state()) end
	awesome.emit_signal("network::ssid", state.ssid)
	awesome.emit_signal("vpn::status", {
		ssid = state.ssid,
		trusted = state.trusted,
		connected = state.vpn_connected,
		interface = state.vpn_interface,
	})
	awesome.emit_signal("network::airplane-mode", state.airplane_mode)
end

function network.get_state()
	local copy = {}
	for key, value in pairs(state) do copy[key] = value end
	copy.interfaces = interfaces
	return copy
end

function network.open_manager()
	process.spawn(prefs.default.network_manager)
end

local function notify_connected(message, icon)
	if state.reconnect_startup or state.startup then
		naughty.notification({ message = message, title = "Connection Established", icon = icon })
		state.reconnect_startup = false
		state.startup = false
		awesome.emit_signal("system::network_connected")
	end
end

local function notify_disconnected()
	if not state.reconnect_startup then
		state.reconnect_startup = true
		naughty.notification({ message = "Network disconnected", title = "Connection Lost", icon = icons.widgets.wifi.wifi_off })
	end
end

function network.check_internet(callback, force)
	local now = os.time()
	if not force and (now - state.last_health_check) < 30 then
		callback(state.internet_healthy)
		return
	end
	process.run_shell("ping -q -w1 -c1 1.1.1.1 >/dev/null 2>&1 && echo ok || echo no", function(stdout)
		state.internet_healthy = tostring(stdout):match("ok") ~= nil
		state.last_health_check = os.time()
		callback(state.internet_healthy)
	end)
end

local function update_vpn_for_ssid()
	state.trusted = is_trusted(state.ssid)
	if state.trusted then
		if state.vpn_connected then network.set_vpn(false) end
	elseif state.connected and not state.vpn_connected then
		network.set_vpn(true)
	end
end

local function update_disconnected()
	state.mode = nil
	state.connected = false
	state.ssid = "unknown"
	state.signal_dbm = nil
	state.strength = 0
	state.bitrate = "N/A"
	notify_disconnected()
	emit_state()
end

local function update_wireless()
	process.run_shell("iw dev " .. process.shell_quote(interfaces.wlan) .. " link", function(stdout)
		if tostring(stdout):match("Not connected") then
			update_disconnected()
			return
		end
		local ssid = stdout:match("SSID:%s*(.-)\n") or "N/A"
		local signal_dbm = tonumber(stdout:match("signal:%s*(-?%d+)"))
		local bitrate = stdout:match("tx bitrate:%s*([%d%.]+%s*MBit/s)") or "N/A"
		if not signal_dbm then
			update_disconnected()
			return
		end
		state.mode = "wireless"
		state.connected = true
		state.ssid = ssid
		state.signal_dbm = signal_dbm
		state.bitrate = bitrate
		state.strength = math.min(100, math.max(0, 2 * (signal_dbm + 100)))
		network.check_internet(function()
			notify_connected('Connected to <b>"' .. ssid .. '"</b>', icons.widgets.wifi.wifi_on)
			update_vpn_for_ssid()
			awesome.emit_signal("widget::network:ssid", state.ssid)
			emit_state()
		end)
	end)
end

local function update_wired()
	state.mode = "wired"
	state.connected = true
	state.ssid = interfaces.lan
	state.signal_dbm = nil
	state.strength = 100
	state.bitrate = "N/A"
	network.check_internet(function()
		notify_connected("Ethernet connected", icons.widgets.ethernet.eth_connected)
		emit_state()
	end)
end

local function read_operstate(interface, callback)
	process.run({ "cat", "/sys/class/net/" .. interface .. "/operstate" }, function(stdout, _, _, exit_code)
		if exit_code ~= 0 then callback(nil) return end
		callback(tostring(stdout or ""):gsub("%s+$", ""))
	end)
end

function network.refresh()
	read_operstate(interfaces.lan, function(lan_state)
		read_operstate(interfaces.wlan, function(wlan_state)
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

function network.refresh_vpn(callback)
	process.run_shell("wg show " .. process.shell_quote(state.vpn_interface) .. " >/dev/null 2>&1 && echo up || echo down", function(stdout)
		state.vpn_connected = tostring(stdout):match("up") ~= nil
		emit_state()
		if callback then callback(state.vpn_connected) end
	end)
end

function network.set_vpn(connected)
	connected = connected and true or false
	if connected == state.vpn_connected then
		emit_state()
		return
	end
	if connected then
		process.spawn("sudo /usr/bin/wg-quick up " .. state.vpn_interface)
		state.vpn_connected = true
		naughty.notification({ message = "VPN tunnel has been enabled", title = "Connected to untrusted network", app_name = "System Notification", icon = icons.widgets.wifi.wifi_on })
	else
		process.spawn("sudo /usr/bin/wg-quick down " .. state.vpn_interface)
		state.vpn_connected = false
		naughty.notification({ message = "VPN tunnel has been disabled", title = "Connected to trusted network", app_name = "System Notification", icon = icons.widgets.wifi.wifi_on })
	end
	emit_state()
end

function network.toggle_vpn()
	network.set_vpn(not state.vpn_connected)
end

function network.set_airplane_mode(enabled)
	enabled = enabled and true or false
	state.airplane_mode = enabled
	settings.set_bool("airplane_mode", enabled)
	if enabled then
		process.run_shell("rfkill block wlan", function() emit_state() end)
		naughty.notification({ app_name = "Network Manager", title = "<b>Airplane mode enabled!</b>", message = "Disabling radio devices", icon = icons.dashboard.settings.airplane_mode })
	else
		process.run_shell("rfkill unblock wlan", function() network.refresh(); emit_state() end)
		naughty.notification({ app_name = "Network Manager", title = "<b>Airplane mode disabled!</b>", message = "Initializing network devices", icon = icons.dashboard.settings.airplane_mode_off })
	end
end

function network.toggle_airplane_mode()
	network.set_airplane_mode(not state.airplane_mode)
end

function network.start()
	process.watch("nmcli monitor", { stdout = function() state.last_health_check = 0; network.refresh() end })
	process.watch("rfkill event", { stdout = function() emit_state() end })
	awesome.connect_signal("vpn::toggle", network.toggle_vpn)
	awesome.connect_signal("network::airplane-mode:toggle", network.toggle_airplane_mode)
	gears.timer({ timeout = 60, call_now = true, autostart = true, callback = network.refresh_vpn })
	network.refresh()
end

return network
