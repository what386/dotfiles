local awful = require("awful")
local gears = require("gears")

local auto_brightness = {}
auto_brightness.enabled = false
auto_brightness.timer = nil
auto_brightness.stream_running = false

local config_dir = gears.filesystem.get_configuration_dir()
local script_dir = config_dir .. "/scripts/"

-- Start brightness stream
local function start_brightness_stream()
	if auto_brightness.stream_running then
		return
	end

	awful.spawn.with_shell("bash " .. script_dir .. "v4l2_brightness_stream.sh start")
	auto_brightness.stream_running = true

	-- Give stream time to start
	gears.timer.start_new(2, function()
		return false -- don't repeat
	end)
end

-- Stop brightness stream
local function stop_brightness_stream()
	if not auto_brightness.stream_running then
		return
	end

	awful.spawn.with_shell("bash " .. script_dir .. "v4l2_brightness_stream.sh stop")
	auto_brightness.stream_running = false
end

-- Read current brightness from stream
local function read_brightness_from_stream(callback)
	awful.spawn.easy_async_with_shell(
		"bash " .. script_dir .. "v4l2_brightness_stream.sh read",
		function(stdout, stderr, reason, exit_code)
			local brightness = tonumber(stdout:match("([%d%.]+)"))
			if brightness then
				callback(brightness)
			end
		end
	)
end

-- Set screen brightness
local function set_screen_brightness(brightness)
	local percent = math.floor(brightness * 120)
	percent = math.max(5, math.min(100, percent))

	awful.spawn("brightnessctl s " .. percent .. "%", false)

	-- Emit signal with current brightness level
	awesome.emit_signal("module::auto_brightness:brightness_changed", percent)
end

-- Update function
local function update_brightness()
	read_brightness_from_stream(function(brightness)
		set_screen_brightness(brightness)
	end)
end

-- Start auto-brightness
local function start_auto_brightness()
	if auto_brightness.enabled then
		return
	end

	auto_brightness.enabled = true
	start_brightness_stream()

	if not auto_brightness.timer then
		auto_brightness.timer = gears.timer({
			timeout = 3,
			callback = update_brightness,
		})
	end

	auto_brightness.timer:start()
	awesome.emit_signal("module::auto_brightness:status_changed", true)
end

-- Stop auto-brightness
local function stop_auto_brightness()
	if not auto_brightness.enabled then
		return
	end

	auto_brightness.enabled = false
	if auto_brightness.timer then
		auto_brightness.timer:stop()
	end
	stop_brightness_stream()
	awesome.emit_signal("module::auto_brightness:status_changed", false)
end

-- Toggle auto-brightness
local function toggle_auto_brightness()
	if auto_brightness.enabled then
		stop_auto_brightness()
	else
		start_auto_brightness()
	end
end

-- Signal handlers
awesome.connect_signal("module::auto_brightness:start", start_auto_brightness)
awesome.connect_signal("module::auto_brightness:stop", stop_auto_brightness)
awesome.connect_signal("module::auto_brightness:toggle", toggle_auto_brightness)

-- Additional signals for advanced control
awesome.connect_signal("module::auto_brightness:set_interval", function(seconds)
	if auto_brightness.timer then
		auto_brightness.timer.timeout = seconds
		if auto_brightness.enabled then
			auto_brightness.timer:stop()
			auto_brightness.timer:start()
		end
	end
end)

-- Cleanup on exit
awesome.connect_signal("exit", function()
	stop_brightness_stream()
end)
