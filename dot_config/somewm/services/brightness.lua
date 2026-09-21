local gears = require("gears")
local naughty = require("naughty")
local settings = require("utilities.settings")
local process = require("utilities.process")

local brightness = {}

local state = {
	available = false,
	level = 0,
	auto_backlight = false,
	stream_running = false,
	last_error = nil,
}

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

function brightness.set_auto_backlight(enabled)
	if enabled then
		naughty.notification({
			title = "Auto Backlight",
			message = "Automatic brightness is not available on this system.",
		})
	end
	state.auto_backlight = false
	state.stream_running = false
	settings.set_bool("auto_backlight_enabled", false)
	emit_state()
end

function brightness.toggle_auto_backlight()
	brightness.set_auto_backlight(not state.auto_backlight)
end

function brightness.start()
	brightness.refresh()
	brightness.set_auto_backlight(false)
end

awesome.connect_signal("widget::brightness", brightness.refresh)
awesome.connect_signal("setting::auto_backlight:toggle", brightness.toggle_auto_backlight)
return brightness
