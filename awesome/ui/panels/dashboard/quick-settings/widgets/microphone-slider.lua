local wibox = require("wibox")
local gears = require("gears")
local awful = require("awful")
local beautiful = require("beautiful")
local spawn = awful.spawn
local dpi = beautiful.xresources.apply_dpi
local icons = require("theme.icons")
local clickable_container = require("ui.clickable-container")

local widget = wibox.widget({
	{
		id = "icon",
		image = icons.widgets.microphone.microphone,
		widget = wibox.widget.imagebox,
		resize = true,
	},
	layout = wibox.layout.align.horizontal,
})

local action_level = wibox.widget({
	{
		widget,
		widget = clickable_container,
	},
	bg = beautiful.transparent,
	shape = gears.shape.circle,
	widget = wibox.container.background,
})

local slider = wibox.widget({
	nil,
	{
		id = "mic_slider",
		bar_shape = gears.shape.rounded_rect,
		bar_height = dpi(2),
		bar_color = "#ffffff20",
		bar_active_color = "#f2f2f2EE",
		handle_color = "#ffffff",
		handle_shape = gears.shape.circle,
		handle_width = dpi(15),
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

local function get_microphone_icon(level, is_muted)
	local icon
	if is_muted then
		return icons.widgets.microphone.microphone_off
	end

	if tonumber(level) >= 75 then
		icon = icons.widgets.microphone.mic_high
	elseif tonumber(level) >= 50 then
		icon = icons.widgets.microphone.mic_medium
	elseif tonumber(level) >= 25 then
		icon = icons.widgets.microphone.mic_low
	else
		icon = icons.widgets.microphone.microphone
	end
	return icon
end

local mic_slider = slider.mic_slider

mic_slider:connect_signal("property::value", function()
	local microphone_level = mic_slider:get_value()

	awful.spawn("pactl set-source-volume $(pactl get-default-source) " .. microphone_level .. "%", false)

	local is_muted = false

	-- Update microphone osd
	awesome.emit_signal("osd::microphone_osd", microphone_level)
	awesome.emit_signal("widget::microphone:icon", get_microphone_icon(microphone_level, is_muted))
end)

awesome.connect_signal("widget::microphone:icon", function(icon)
	widget.icon:set_image(icon)
end)

mic_slider:buttons(gears.table.join(
	awful.button({}, 4, nil, function()
		if mic_slider:get_value() > 100 then
			mic_slider:set_value(100)
			return
		end
		mic_slider:set_value(mic_slider:get_value() + 5)
	end),
	awful.button({}, 5, nil, function()
		if mic_slider:get_value() < 0 then
			mic_slider:set_value(0)
			return
		end
		mic_slider:set_value(mic_slider:get_value() - 5)
	end)
))

local update_slider = function()
	awful.spawn.easy_async_with_shell(
		[[pactl get-source-volume $(pactl get-default-source) | grep -Po '\d+(?=%)' | head -n 1]],
		function(stdout)
			local level = tonumber(stdout)
			mic_slider:set_value(tonumber(level))
		end
	)
end

-- Update on startup
update_slider()

local action_jump = function()
	local sli_value = mic_slider:get_value()
	local new_value = 0

	if sli_value >= 0 and sli_value < 50 then
		new_value = 50
	elseif sli_value >= 50 and sli_value < 100 then
		new_value = 100
	else
		new_value = 0
	end
	mic_slider:set_value(new_value)
end

action_level:buttons(awful.util.table.join(awful.button({}, 1, nil, function()
	action_jump()
end)))

-- The emit will come from the global keybind
awesome.connect_signal("widget::microphone", function()
	update_slider()
end)

-- The emit will come from the OSD
awesome.connect_signal("widget::microphone:update", function(value)
	mic_slider:set_value(tonumber(value))
end)

local microphone_setting = wibox.widget({
	{
		{
			action_level,
			top = dpi(12),
			bottom = dpi(12),
			widget = wibox.container.margin,
		},
		slider,
		spacing = dpi(24),
		layout = wibox.layout.fixed.horizontal,
	},
	left = dpi(24),
	right = dpi(24),
	forced_height = dpi(48),
	widget = wibox.container.margin,
})

return microphone_setting
