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
		text = "Temperature",
		font = "Inter Bold 10",
		align = "left",
		widget = wibox.widget.textbox,
	})

	local icon = wibox.widget({
		layout = wibox.layout.align.vertical,
		expand = "none",
		nil,
		{
			image = icons.applets.resources.temp,
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
			id = "temp_status",
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

	local temp_path = "/sys/class/thermal/thermal_zone0/temp"
	local max_temp = 100

	local function detect_path(cb)
		awful.spawn.easy_async_with_shell(
			[[
        for i in /sys/class/hwmon/hwmon*/temp*_input;
        do
            label="$(cat ${i%_*}_label 2>/dev/null)"
            if [ "$label" = "Package" ]; then
                readlink -f $i
                exit
            fi
        done
        ]],
			function(out)
				local p = out:gsub("\n", "")
				if p ~= "" then
					temp_path = p
				end
				cb()
			end
		)
	end

	local function update()
		awful.spawn.easy_async_with_shell("cat " .. temp_path, function(out)
			local t = tonumber(out:match("%d+"))
			if not t then
				return
			end

			t = t / 1000

			slider.temp_status:set_value(t / max_temp * 100)
			meter_info:set_text(string.format("%.1f°C / %d°C", t, max_temp))
		end)
	end

	local timer = gears.timer({ timeout = 2, autostart = false, call_now = true, callback = update })

	function widget:start()
		detect_path(function()
			if not timer.started then
				timer:start()
			end
		end)
	end

	function widget:stop()
		timer:stop()
	end

	return widget
end

return new
