local wibox = require("wibox")
local gears = require("gears")
local awful = require("awful")
local beautiful = require("beautiful")
local dpi = beautiful.xresources.apply_dpi
local clickable_container = require("ui.clickable-container")
local config_dir = gears.filesystem.get_configuration_dir()
local widget_icon_dir = config_dir .. "ui/panels/dashboard/settings/icons/"

local action_name = wibox.widget({
	text = "Blur Strength",
	font = "Inter Bold 10",
	align = "left",
	widget = wibox.widget.textbox,
})

local icon = wibox.widget({
	layout = wibox.layout.align.vertical,
	expand = "none",
	nil,
	{
		image = widget_icon_dir .. "effects.svg",
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
local slider = wibox.widget({
	nil,
	{
		id = "blur_strength_slider",
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

local blur_slider = slider.blur_strength_slider

local update_slider_value = function()
	awful.spawn.easy_async_with_shell(
		[[bash -c "
		grep -F 'strength =' $HOME/.config/awesome/dependencies/picom/picom.conf |
		awk 'NR==1 {print $3}' | tr -d ';'
		"]],
		function(stdout, stderr)
			local strength = stdout:match("%d+")
			blur_strength = tonumber(strength) / 20 * 100
			blur_slider:set_value(tonumber(blur_strength))
			start_up = false
		end
	)
end

-- Update on startup
update_slider_value()

local action_jump = function()
	local sli_value = blur_slider:get_value()
	local new_value = 0

	if sli_value >= 0 and sli_value < 25 then
		new_value = 25
	elseif sli_value >= 25 and sli_value < 50 then
		new_value = 50
	elseif sli_value >= 50 and sli_value < 100 then
		new_value = 100
	else
		new_value = 0
	end
	blur_slider:set_value(new_value)
end

action_level:buttons(awful.util.table.join(awful.button({}, 1, nil, function()
	action_jump()
end)))

local adjust_blur = function(power)
	awful.spawn.with_shell([[bash -c "
		sed -i 's/.*strength = .*/    strength = ]] .. power .. [[;/g' \
		$HOME/.config/awesome/dependencies/picom/picom.conf
		"]])
end

blur_slider:connect_signal("property::value", function()
	if not start_up then
		strength = blur_slider:get_value() / 50 * 10
		adjust_blur(strength)
	end
end)

-- Adjust slider value to change blur strength
awesome.connect_signal("widget::blur:increase", function()
	-- On startup, the slider.value returns nil so...
	if blur_slider:get_value() == nil then
		return
	end

	local blur_value = blur_slider:get_value() + 10

	-- No more than 100!
	if blur_value > 100 then
		blur_slider:set_value(100)
		return
	end

	blur_slider:set_value(blur_value)
end)

-- Decrease blur
awesome.connect_signal("widget::blur:decrease", function()
	-- On startup, the slider.value returns nil so...
	if blur_slider:get_value() == nil then
		return
	end

	local blur_value = blur_slider:get_value() - 10

	-- No negatives!
	if blur_value < 0 then
		blur_slider:set_value(0)
		return
	end

	blur_slider:set_value(blur_value)
end)

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
