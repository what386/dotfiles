local wibox = require("wibox")
local gears = require("gears")
local awful = require("awful")
local beautiful = require("beautiful")
local spawn = awful.spawn
local dpi = beautiful.xresources.apply_dpi
local clickable_container = require("ui.clickable-container")
local config_dir = gears.filesystem.get_configuration_dir()
local widget_icon_dir = config_dir .. "ui/panels/dashboard/settings/icons/"

-- Header
local action_name = wibox.widget({
	text = "Volume",
	font = "Inter Bold 10",
	align = "left",
	widget = wibox.widget.textbox,
})

-- Icon
local icon = wibox.widget({
	layout = wibox.layout.align.vertical,
	expand = "none",
	nil,
	{
		image = widget_icon_dir .. "volume-medium.svg",
		resize = true,
		widget = wibox.widget.imagebox,
	},
	nil,
})

local action_level = wibox.widget({
	{
		{
			icon,
			margins = dpi(5),
			widget = wibox.container.margin,
		},
		widget = clickable_container,
	},
	bg = beautiful.groups_bg,
	shape = function(cr, width, height)
		gears.shape.rounded_rect(cr, width, height, beautiful.groups_radius)
	end,
	widget = wibox.container.background,
})

-- Slider
local slider = wibox.widget({
	nil,
	{
		id = "volume_slider",
		bar_shape = gears.shape.rounded_rect,
		bar_height = dpi(24),
		bar_color = "#ffffff20",
		bar_active_color = "#f2f2f2EE",
		handle_color = "#ffffff",
		handle_shape = gears.shape.circle,
		handle_width = dpi(24),
		handle_border_color = "#00000012",
		handle_border_width = dpi(1),
		maximum = 100,
		widget = wibox.widget.slider,
	},
	nil,
	expand = "none",
	forced_height = dpi(24),
	layout = wibox.layout.align.vertical,
})

local volume_slider = slider.volume_slider

-- Flag to prevent circular updates
local updating_from_signal = false

-- When user drags this slider
volume_slider:connect_signal("property::value", function()
	if updating_from_signal then
		return
	end

	local volume_level = volume_slider:get_value()
	spawn("pactl set-sink-volume @DEFAULT_SINK@ " .. volume_level .. "%", false)

	-- Broadcast to other widgets (OSD, widget, etc.)
	awesome.emit_signal("volume::update", volume_level)
end)

-- Mouse wheel support
volume_slider:buttons(gears.table.join(
	awful.button({}, 4, nil, function()
		if volume_slider:get_value() > 100 then
			volume_slider:set_value(100)
			return
		end
		volume_slider:set_value(volume_slider:get_value() + 5)
	end),
	awful.button({}, 5, nil, function()
		if volume_slider:get_value() < 0 then
			volume_slider:set_value(0)
			return
		end
		volume_slider:set_value(volume_slider:get_value() - 5)
	end)
))

-- Initialize slider value
local function update_slider()
	awful.spawn.easy_async_with_shell(
		[[pactl get-sink-volume @DEFAULT_SINK@ | grep -Po '\d+(?=%)' | head -n 1]],
		function(stdout)
			local level = tonumber(stdout) or 0
			updating_from_signal = true
			volume_slider:set_value(level)
			updating_from_signal = false
		end
	)
end

-- Update on startup
update_slider()

-- Click icon to jump between volume levels
local action_jump = function()
	local sli_value = volume_slider:get_value()
	local new_value = 0
	if sli_value >= 0 and sli_value < 50 then
		new_value = 50
	elseif sli_value >= 50 and sli_value < 100 then
		new_value = 100
	else
		new_value = 0
	end
	volume_slider:set_value(new_value)
end

action_level:buttons(awful.util.table.join(awful.button({}, 1, nil, function()
	action_jump()
end)))

-- Listen for volume updates from other sources
awesome.connect_signal("volume::update", function(level)
	updating_from_signal = true
	volume_slider:set_value(level)
	updating_from_signal = false
end)

-- Main widget layout
local volume_setting = wibox.widget({
	layout = wibox.layout.fixed.vertical,
	forced_height = dpi(48),
	spacing = dpi(5),
	action_name,
	{
		layout = wibox.layout.fixed.horizontal,
		spacing = dpi(5),
		{
			layout = wibox.layout.align.vertical,
			expand = "none",
			nil,
			{
				layout = wibox.layout.fixed.horizontal,
				forced_height = dpi(24),
				forced_width = dpi(24),
				action_level,
			},
			nil,
		},
		slider,
	},
})

return volume_setting
