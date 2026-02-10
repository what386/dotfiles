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
		text = "RAM",
		font = "Inter Bold 10",
		align = "left",
		widget = wibox.widget.textbox,
	})

	local icon = wibox.widget({
		layout = wibox.layout.align.vertical,
		expand = "none",
		nil,
		{
			image = icons.applets.resources.ram,
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
			id = "ram_usage",
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

	local function update()
		local mem_total = 0
		local mem_available = 0
		local swap_total = 0
		local swap_free = 0

		local f = io.open("/proc/meminfo", "r")
		if not f then
			return
		end
		for line in f:lines() do
			local k, v = line:match("^(%w+):%s+(%d+)")
			if k == "MemTotal" then
				mem_total = tonumber(v) or 0
			elseif k == "MemAvailable" then
				mem_available = tonumber(v) or 0
			elseif k == "SwapTotal" then
				swap_total = tonumber(v) or 0
			elseif k == "SwapFree" then
				swap_free = tonumber(v) or 0
			end
		end
		f:close()

		if mem_total <= 0 then
			return
		end

		local mem_used = mem_total - mem_available
		local swap_used = math.max(0, swap_total - swap_free)
		slider.ram_usage:set_value(mem_used / mem_total * 100)

		meter_info:set_text(
			string.format(
				"RAM %.1f/%.1f GiB  |  Swap %.1f/%.1f GiB",
				mem_used / 1048576,
				mem_total / 1048576,
				swap_used / 1048576,
				swap_total / 1048576
			)
		)
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
