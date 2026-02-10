local wibox = require("wibox")
local gears = require("gears")
local awful = require("awful")
local beautiful = require("beautiful")
local dpi = beautiful.xresources.apply_dpi

local icons = require("theme.icons")

local function new()
	local meter_info = wibox.widget({
		text = "100%",
		font = "Inter Bold 10",
		align = "left",
		widget = wibox.widget.textbox,
	})

	local meter_name = wibox.widget({
		text = "Fan Speed",
		font = "Inter Bold 10",
		align = "left",
		widget = wibox.widget.textbox,
	})

	local icon = wibox.widget({
		layout = wibox.layout.align.vertical,
		expand = "none",
		nil,
		{
			image = icons.applets.resources.gpu,
			resize = true,
			widget = wibox.widget.imagebox,
		},
		nil,
	})

	local meter_icon = wibox.widget({
		{
			icon,
			margins = dpi(5),
			widget = wibox.container.margin,
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
			id = "rpm_status",
			max_value = 100,
			value = 29,
			forced_height = dpi(24),
			color = "#f2f2f2EE",
			background_color = "#ffffff20",
			shape = gears.shape.rounded_rect,
			widget = wibox.widget.progressbar,
		},
		nil,
		expand = "none",
		forced_height = dpi(24),
		layout = wibox.layout.align.vertical,
	})

	local widget = wibox.widget({

		layout = wibox.layout.fixed.vertical,
		spacing = dpi(5),
		{
			layout = wibox.layout.align.horizontal,
			meter_name,
			nil,
			meter_info,
		},
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
					meter_icon,
				},
				nil,
			},
			slider,
		},
	})

	local max_rpm = 4000

	local function update()
		awful.spawn.easy_async_with_shell("sensors | grep -i fan | awk '{print $2}'", function(out)
			local rpm = tonumber(out:match("%d+"))
			if not rpm then
				return
			end

			slider.rpm_status:set_value(rpm / max_rpm * 100)
			meter_info:set_text(rpm .. " RPM / " .. max_rpm .. " RPM")
		end)
	end

	local timer = gears.timer({ timeout = 2, autostart = false, call_now = true, callback = update })

	function widget:start()
		if not timer.started then
			timer:start()
		end
	end

	function widget:stop()
		timer:stop()
	end

	return widget
end

return new
