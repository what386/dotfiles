local gears = require("gears")
local naughty = require("naughty")
local gfs = require("gears.filesystem")
local settings = require("modules.settings-store")
local process = require("services.process")

local brightness = {}

local script_dir = gfs.get_configuration_dir() .. "scripts/"
local state = {
	available = false,
	level = 0,
	auto_backlight = settings.get_bool("auto_backlight_enabled", false),
	stream_running = false,
	last_auto_percent = nil,
	last_error = nil,
}

local timer = nil
local apply_timer = nil
local pending_level = nil

local function clamp_percent(value, floor)
	local level = math.floor((tonumber(value) or 0) + 0.5)
	level = math.max(floor or 0, math.min(100, level))
	return level
end

local function emit_state()
	awesome.emit_signal("brightness::state", brightness.get_state())
	awesome.emit_signal("brightness::level", state.level)
	awesome.emit_signal("brightness::auto-backlight", state.auto_backlight)
	awesome.emit_signal("widget::brightness:update", state.level)
	awesome.emit_signal("osd::brightness_osd", state.level)
end

local function emit_error(message)
	state.available = false
	state.last_error = message
	awesome.emit_signal("brightness::error", message)
end

function brightness.get_state()
	return {
		available = state.available,
		level = state.level,
		auto_backlight = state.auto_backlight,
		stream_running = state.stream_running,
		last_error = state.last_error,
	}
end

function brightness.refresh(callback)
	process.run_shell([[brightnessctl -m | awk -F, '{print substr($4, 0, length($4)-1)}']], function(stdout, stderr, _, exit_code)
		if exit_code ~= 0 then
			emit_error(stderr ~= "" and stderr or "brightnessctl unavailable")
			if callback then
				callback(brightness.get_state())
			end
			return
		end

		state.level = clamp_percent(stdout)
		state.available = true
		state.last_error = nil
		emit_state()
		if callback then
			callback(brightness.get_state())
		end
	end)
end

local function ensure_apply_timer()
	if apply_timer then
		return
	end
	apply_timer = gears.timer({
		timeout = 0.08,
		single_shot = true,
		autostart = false,
		callback = function()
			if pending_level == nil then
				return
			end
			local level = pending_level
			pending_level = nil
			process.spawn("brightnessctl s " .. tostring(math.max(level, 5)) .. "%")
			state.level = level
			state.available = true
			state.last_error = nil
			emit_state()
		end,
	})
end

function brightness.set_level(percent)
	pending_level = clamp_percent(percent)
	state.level = pending_level
	emit_state()
	ensure_apply_timer()
	apply_timer:again()
end

function brightness.change_level(delta)
	brightness.set_level((state.level or 0) + (tonumber(delta) or 0))
end

local function start_stream()
	if state.stream_running then
		return
	end
	process.run_shell("bash " .. process.shell_quote(script_dir .. "v4l2_brightness_stream.sh") .. " start", function(_, _, _, exit_code)
		state.stream_running = exit_code == 0
		if not state.stream_running then
			state.auto_backlight = false
			settings.set_bool("auto_backlight_enabled", false)
			emit_state()
			naughty.notification({ title = "Auto Backlight", message = "Unable to start brightness stream (camera/v4l2 unavailable)." })
		end
	end)
end

local function stop_stream()
	if state.stream_running then
		process.spawn_shell("bash " .. process.shell_quote(script_dir .. "v4l2_brightness_stream.sh") .. " stop")
	end
	state.stream_running = false
end

local function read_stream(callback)
	process.run_shell("bash " .. process.shell_quote(script_dir .. "v4l2_brightness_stream.sh") .. " read", function(stdout, _, _, exit_code)
		if exit_code ~= 0 then
			return
		end
		local value = tonumber(stdout:match("([%d%.]+)"))
		if value then
			callback(value)
		end
	end)
end

local function auto_update()
	read_stream(function(raw)
		local percent = clamp_percent(raw * 100, 5)
		if state.last_auto_percent and math.abs(percent - state.last_auto_percent) < 3 then
			return
		end
		state.last_auto_percent = percent
		brightness.set_level(percent)
		awesome.emit_signal("module::auto_brightness:brightness_changed", percent)
	end)
end

function brightness.set_auto_backlight(enabled)
	enabled = enabled and true or false
	if state.auto_backlight == enabled then
		emit_state()
		return
	end

	state.auto_backlight = enabled
	settings.set_bool("auto_backlight_enabled", enabled)
	if enabled then
		start_stream()
		if not timer then
			timer = gears.timer({ timeout = 3, callback = auto_update })
		end
		timer:start()
	else
		state.last_auto_percent = nil
		if timer then
			timer:stop()
		end
		stop_stream()
	end
	emit_state()
end

function brightness.toggle_auto_backlight()
	brightness.set_auto_backlight(not state.auto_backlight)
end

function brightness.start()
	brightness.refresh()
	if state.auto_backlight then
		state.auto_backlight = false
		brightness.set_auto_backlight(true)
	end
end

awesome.connect_signal("widget::brightness", brightness.refresh)
awesome.connect_signal("setting::auto_backlight:toggle", brightness.toggle_auto_backlight)
awesome.connect_signal("exit", stop_stream)

return brightness
