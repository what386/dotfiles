local wibox = require("wibox")
local gears = require("gears")
local awful = require("awful")
local beautiful = require("beautiful")
local dpi = beautiful.xresources.apply_dpi
local config_dir = gears.filesystem.get_configuration_dir()
local widget_icon_dir = config_dir .. "ui/panels/dashboard/sys-monitor/icons/"

local meter_info = wibox.widget({
	text = "100%",
	font = "Inter Bold 10",
	align = "left",
	widget = wibox.widget.textbox,
})
local meter_name = wibox.widget({
	text = "GPU",
	font = "Inter Bold 10",
	align = "left",
	widget = wibox.widget.textbox,
})

local icon = wibox.widget({
	layout = wibox.layout.align.vertical,
	expand = "none",
	nil,
	{
		image = widget_icon_dir .. "gpu.svg",
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
		id = "gpu_usage",
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

local gpu_meter = wibox.widget({
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

local max_freq = 1100

local function update_max_freq()
	awful.spawn.easy_async_with_shell([[cat /sys/class/drm/card1/gt_max_freq_mhz]], function(stdout)
		max_freq = stdout:match("%d+") or 1100
	end)
end

update_max_freq()

awful.widget.watch([[cat /sys/class/drm/card1/gt_cur_freq_mhz]], 2, function(_, stdout)
	local freq = stdout:match("%d+")
	slider.gpu_usage:set_value(freq / max_freq * 100)
	meter_info:set_text("GPU (cur/max): " .. freq .. " MHz, " .. max_freq .. " Mhz")
	collectgarbage("collect")
end)

return gpu_meter
