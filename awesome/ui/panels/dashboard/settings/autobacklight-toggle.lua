local awful = require("awful")
local wibox = require("wibox")
local gears = require("gears")
local beautiful = require("beautiful")
local dpi = beautiful.xresources.apply_dpi
local clickable_container = require("ui.clickable-container")
local config_dir = gears.filesystem.get_configuration_dir()
local widget_icon_dir = config_dir .. "ui/panels/dashboard/settings/icons/"
local script_dir = config_dir .. "/scripts/"

local action_name = wibox.widget({
	text = "Auto Backlight",
	font = "Inter Bold 10",
	align = "left",
	widget = wibox.widget.textbox,
})

local action_status = wibox.widget({
	text = "Off",
	font = "Inter Regular 10",
	align = "left",
	widget = wibox.widget.textbox,
})

local action_info = wibox.widget({
	layout = wibox.layout.fixed.vertical,
	action_name,
	action_status,
})

local button_widget = wibox.widget({
	{
		id = "icon",
		image = widget_icon_dir .. "brightness-off.svg",
		widget = wibox.widget.imagebox,
		resize = true,
	},
	layout = wibox.layout.align.horizontal,
})

local widget_button = wibox.widget({
	{
		{
			button_widget,
			margins = dpi(15),
			forced_height = dpi(48),
			forced_width = dpi(48),
			widget = wibox.container.margin,
		},
		widget = clickable_container,
	},
	bg = beautiful.groups_bg,
	shape = gears.shape.circle,
	widget = wibox.container.background,
})

local update_widget = function()
	if blue_light_state then
		action_status:set_text("On")
		widget_button.bg = beautiful.accent
		button_widget.icon:set_image(widget_icon_dir .. "brightness.svg")
	else
		action_status:set_text("Off")
		widget_button.bg = beautiful.groups_bg
		button_widget.icon:set_image(widget_icon_dir .. "brightness-off.svg")
	end
end

local auto_brightness = {}
auto_brightness.enabled = false
auto_brightness.timer = nil
auto_brightness.stream_running = false

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
end

local toggle_action = function()
	if auto_brightness.enabled then
		stop_auto_brightness()
	else
		start_auto_brightness()
	end
end

widget_button:buttons(gears.table.join(awful.button({}, 1, nil, function()
	toggle_action()
	update_widget()
end)))

action_info:buttons(gears.table.join(awful.button({}, 1, nil, function()
	toggle_action()
	update_widget()
end)))

local action_widget = wibox.widget({
	layout = wibox.layout.fixed.horizontal,
	spacing = dpi(10),
	widget_button,
	{
		layout = wibox.layout.align.vertical,
		expand = "none",
		nil,
		action_info,
		nil,
	},
})

-- Cleanup on exit
awesome.connect_signal("exit", function()
	stop_brightness_stream()
end)

awesome.connect_signal("setting::auto_backlight:toggle", function()
	toggle_action()
end)

return action_widget
