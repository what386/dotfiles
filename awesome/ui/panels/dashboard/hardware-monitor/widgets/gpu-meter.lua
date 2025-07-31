local wibox = require("wibox")
local gears = require("gears")
local beautiful = require("beautiful")
local awful = require("awful")
local icons = require("theme.icons")

local dpi = beautiful.xresources.apply_dpi

local gpu = wibox.widget.textbox()
gpu.font = beautiful.widget_text

local slider = wibox.widget({
	nil,
	{
		id = "gpu_usage",
		max_value = 100,
		value = 0,
		forced_height = dpi(2),
		color = beautiful.fg_normal,
		background_color = beautiful.groups_bg,
		shape = gears.shape.rounded_rect,
		widget = wibox.widget.progressbar,
	},
	nil,
	expand = "none",
	layout = wibox.layout.align.vertical,
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
	gpu.text = math.floor((freq / max_freq) * 100) .. "%"
	collectgarbage("collect")
end)

local ram_meter = wibox.widget({
	{
		{
			{
				{
					image = icons.applets.resources.gpu,
					resize = true,
					widget = wibox.widget.imagebox,
				},
				top = dpi(12),
				bottom = dpi(12),
				widget = wibox.container.margin,
			},
			{
				gpu,
				fg = beautiful.fg_normal,
				widget = wibox.container.background,
			},
			spacing = dpi(4),
			layout = wibox.layout.fixed.horizontal,
			forced_width = dpi(65),
		},
		slider,
		spacing = dpi(12),
		layout = wibox.layout.fixed.horizontal,
	},
	left = dpi(24),
	right = dpi(24),
	forced_height = dpi(48),
	widget = wibox.container.margin,
})

return ram_meter
