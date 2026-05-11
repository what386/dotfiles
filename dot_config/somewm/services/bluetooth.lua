local gears = require("gears")
local naughty = require("naughty")
local prefs = require("config.user.preferences")
local icons = require("theme.icons")
local process = require("libraries.process")

local bluetooth = {}

local state = {
	enabled = false,
	devices = {},
	details_unavailable = false,
	last_error = nil,
}

local refresh_generation = 0

local function parse_connected_devices(stdout)
	local devices = {}
	for line in tostring(stdout or ""):gmatch("[^\r\n]+") do
		local address, name = line:match("^Device%s+([%x:]+)%s+(.+)$")
		if address then
			table.insert(devices, { address = address, name = name or address, battery = nil })
		end
	end
	return devices
end

local function parse_battery_percent(stdout)
	for line in tostring(stdout or ""):gmatch("[^\r\n]+") do
		local battery_raw = line:match("^%s*Battery Percentage:%s*(.+)$")
		if battery_raw then
			local direct_percent = tonumber(battery_raw:match("(%d+)%%"))
			local bracket_percent = tonumber(battery_raw:match("%((%d+)%)"))
			local numeric_percent = tonumber(battery_raw:match("^(%d+)$"))
			local hex_percent = battery_raw:match("0x(%x+)")
			local decoded = hex_percent and tonumber(hex_percent, 16) or nil
			local value = direct_percent or bracket_percent or numeric_percent or decoded
			if value then
				return math.max(0, math.min(100, value))
			end
		end
	end
	return nil
end

local function emit_state()
	awesome.emit_signal("bluetooth::state", bluetooth.get_state())
	awesome.emit_signal("bluetooth::power", state.enabled)
	awesome.emit_signal("bluetooth::devices", state.devices)
end

function bluetooth.get_state()
	return {
		enabled = state.enabled,
		devices = state.devices,
		details_unavailable = state.details_unavailable,
		last_error = state.last_error,
	}
end

function bluetooth.open_manager()
	process.spawn(prefs.default.bluetooth_manager)
end

function bluetooth.refresh(callback)
	local on_refresh = type(callback) == "function" and callback or nil

	refresh_generation = refresh_generation + 1
	local generation = refresh_generation
	process.run({ "rfkill", "list", "bluetooth" }, function(stdout, _, _, exit_code)
		if generation ~= refresh_generation then
			return
		end
		if exit_code ~= 0 or tostring(stdout):match("Soft blocked:%s*yes") then
			state.enabled = false
			state.devices = {}
			state.details_unavailable = false
			emit_state()
			if on_refresh then on_refresh(bluetooth.get_state()) end
			return
		end

		state.enabled = true
		process.run({ "bluetoothctl", "devices", "Connected" }, function(devices_stdout, _, _, devices_exit_code)
			if generation ~= refresh_generation then
				return
			end
				if devices_exit_code ~= 0 then
					state.devices = {}
					state.details_unavailable = true
					emit_state()
					if on_refresh then on_refresh(bluetooth.get_state()) end
					return
				end

			local devices = parse_connected_devices(devices_stdout)
			state.devices = devices
				state.details_unavailable = false
				if #devices == 0 then
					emit_state()
					if on_refresh then on_refresh(bluetooth.get_state()) end
					return
				end

			local pending = #devices
			for _, device in ipairs(devices) do
				process.run({ "bluetoothctl", "info", device.address }, function(info_stdout, _, _, info_exit_code)
					if generation ~= refresh_generation then
						return
					end
					if info_exit_code == 0 then
						device.battery = parse_battery_percent(info_stdout)
					end
						pending = pending - 1
						if pending == 0 then
							emit_state()
							if on_refresh then on_refresh(bluetooth.get_state()) end
						end
					end)
				end
		end)
	end)
end

function bluetooth.set_power(enabled)
	enabled = enabled and true or false
	local command
	if enabled then
		command = "rfkill unblock bluetooth; sleep 1; bluetoothctl power on"
		naughty.notification({ app_name = "Bluetooth Manager", title = "System Notification", message = "Initializing bluetooth device...", icon = icons.dashboard.settings.loading })
	else
		command = "bluetoothctl power off; rfkill block bluetooth"
		naughty.notification({ app_name = "Bluetooth Manager", title = "System Notification", message = "The bluetooth device has been disabled.", icon = icons.dashboard.settings.bluetooth_off })
	end
	process.run_shell(command, function()
		state.enabled = enabled
		bluetooth.refresh()
	end)
end

function bluetooth.toggle_power()
	bluetooth.set_power(not state.enabled)
end

function bluetooth.start()
	process.watch("rfkill event", { stdout = function() bluetooth.refresh() end })
	gears.timer({ timeout = 45, autostart = true, call_now = true, callback = bluetooth.refresh })
end

return bluetooth
