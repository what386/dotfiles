local gears = require("gears")
local naughty = require("naughty")
local icons = require("theme.icons")
local prefs = require("config.user.preferences")
local process = require("libraries.process")

local power = {}

local state = {
	battery = {
		status = "Unknown",
		charge = nil,
		time = "Unavailable",
		health = nil,
		design_capacity = nil,
		effective_capacity = nil,
	},
	low_message_shown = false,
}

local function trim(value)
	return tostring(value or ""):match("^%s*(.-)%s*$")
end

local function parse_acpi(stdout)
	local first_line = tostring(stdout or ""):match("^[^\r\n]+") or ""
	local status, charge_str, time = first_line:match("Battery %d+: ([^,]+), (%d+)%%, (%d+:%d+):")
	if not time then
		status, charge_str, time = first_line:match("Battery %d+: ([^,]+), (%d+)%%, (.+)$")
		if not time then
			status, charge_str = first_line:match("Battery %d+: ([^,]+), (%d+)%%")
			time = "Unavailable"
		end
	end

	local design_cap, effective_cap, health = tostring(stdout or ""):match("design capacity (%d+ mAh), last full capacity (%d+ mAh) = (%d+%%)")
	return {
		status = trim(status ~= "" and status or "Unknown"),
		charge = tonumber(charge_str),
		time = trim(time ~= "" and time or "Unavailable"),
		design_capacity = design_cap,
		effective_capacity = effective_cap,
		health = health,
	}
end

local function notify(message, title)
	naughty.notification({
		message = message,
		title = title,
		app_name = "System Notification",
		icon = icons.widgets.battery.battery_alert,
	})
end

local function apply_policy(battery)
	local charge = battery.charge
	if not charge then
		return
	end

	if charge <= 5 and not state.low_message_shown then
		notify("System will hibernate at 1%\nTime remaining: <b>" .. tostring(battery.time or "unavailable") .. "</b>", "Battery is low")
		state.low_message_shown = true
	end

	if charge > 5 then
		state.low_message_shown = false
	end

	if charge <= 1 and battery.status ~= "Charging" then
		notify("System hibernating in 5 seconds!", "Battery critically low")
		process.run_shell("sleep 5; systemctl hibernate")
	end
end

local function emit_battery()
	awesome.emit_signal("power::battery", state.battery)
	if state.battery.health then
		awesome.emit_signal("power::battery-health", state.battery)
	end
end

function power.get_battery_state()
	return state.battery
end

function power.refresh_battery(callback)
	process.run_shell("acpi -i", function(stdout, stderr, _, exit_code)
		if exit_code ~= 0 then
			awesome.emit_signal("power::error", stderr ~= "" and stderr or "acpi unavailable")
			return
		end
		state.battery = parse_acpi(stdout)
		emit_battery()
		apply_policy(state.battery)
		if callback then
			callback(state.battery)
		end
	end)
end

function power.open_power_manager()
	process.spawn(prefs.default.power_manager)
end

function power.suspend()
	awesome.emit_signal("screen::exit_screen:hide")
	process.spawn_shell("systemctl suspend")
end

function power.hibernate()
	awesome.emit_signal("screen::exit_screen:hide")
	process.spawn_shell("systemctl hibernate")
end

function power.lock()
	awesome.emit_signal("screen::exit_screen:hide")
	awesome.emit_signal("screen::lockscreen:show")
end

function power.poweroff()
	awesome.emit_signal("module::session_manager:save")
	gears.timer({ timeout = 0.5, autostart = true, single_shot = true, callback = function() process.spawn_shell("poweroff") end })
	awesome.emit_signal("screen::exit_screen:hide")
end

function power.reboot()
	awesome.emit_signal("module::session_manager:save")
	gears.timer({ timeout = 0.5, autostart = true, single_shot = true, callback = function() process.spawn_shell("reboot") end })
	awesome.emit_signal("screen::exit_screen:hide")
end

function power.start()
	gears.timer({ timeout = 30, call_now = true, autostart = true, callback = function() power.refresh_battery() end })
	process.watch("acpi_listen", {
		stdout = function(line)
			if line:match("ac_adapter") or line:match("battery") then
				power.refresh_battery()
			end
		end,
	})
end

return power
