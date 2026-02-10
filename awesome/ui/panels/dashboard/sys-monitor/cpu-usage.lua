local wibox = require("wibox")
local gears = require("gears")
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
		text = "CPU",
		font = "Inter Bold 10",
		align = "left",
		widget = wibox.widget.textbox,
	})

	local slider = wibox.widget({
		{
			id = "cpu_usage",
			max_value = 100,
			value = 0,
			forced_height = dpi(24),
			color = "#f2f2f2EE",
			background_color = "#ffffff20",
			shape = gears.shape.rounded_rect,
			widget = wibox.widget.progressbar,
		},
		layout = wibox.layout.align.vertical,
	})

	local icon = wibox.widget({
		layout = wibox.layout.align.vertical,
		expand = "none",
		nil,
		{
			image = icons.applets.resources.cpu,
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
					icon,
				},
				nil,
			},
			slider,
		},
	})

	local total_prev = 0
	local idle_prev = 0

	local function update()
		local f = io.open("/proc/stat", "r")
		if not f then
			return
		end
		local line = f:read("*l")
		f:close()
		if not line then
			return
		end

		local user, nice, system, idle, iowait, irq, softirq, steal =
			line:match("cpu%s+(%d+)%s+(%d+)%s+(%d+)%s+(%d+)%s+(%d+)%s+(%d+)%s+(%d+)%s+(%d+)")

		if not user then
			return
		end

		local total = user + nice + system + idle + iowait + irq + softirq + steal
		local diff_idle = idle - idle_prev
		local diff_total = total - total_prev

		if diff_total <= 0 then
			return
		end

		local usage = 100 * (diff_total - diff_idle) / diff_total
		slider.cpu_usage:set_value(usage)
		meter_info:set_text(string.format("CPU %.1f%%", usage))

		total_prev = total
		idle_prev = idle
	end

	local timer = gears.timer({
		timeout = 2,
		autostart = false,
		call_now = true,
		callback = update,
	})

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
