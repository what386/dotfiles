local wibox = require("wibox")
local gears = require("gears")
local awful = require("awful")
local beautiful = require("beautiful")
local watch = awful.widget.watch
local spawn = awful.spawn
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
		image = widget_icon_dir .. "memory.svg",
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

local ram_meter = wibox.widget({
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

watch([[bash -c "free | grep -z Mem.*Swap.*"]], 2, function(_, stdout)
	local total, used, free, shared, buff_cache, available, total_swap, used_swap, free_swap =
		stdout:match("(%d+)%s*(%d+)%s*(%d+)%s*(%d+)%s*(%d+)%s*(%d+)%s*Swap:%s*(%d+)%s*(%d+)%s*(%d+)")
	slider.ram_usage:set_value(used / total * 100)

	local used_GiB = string.format("%.1f", used / 976600)
	local cache_GiB = string.format("%.1f", buff_cache / 976600)

	local total_GiB = string.format("%.1f", total / 976600)
	local swap_GiB = string.format("%.1f", used_swap / 976600)
	local frswap_GiB = string.format("%.1f", free_swap / 976600)
	local swtotal_GiB = string.format("%.1f", total_swap / 976600)

	meter_info:set_text(
		"RAM (used/cache/total): "
		.. used_GiB
		.. "GiB, "
		.. cache_GiB
		.. "GiB, "
		.. total_GiB
		.. "GiB \nSwap (used/free/total): "
		.. swap_GiB
		.. "GiB, "
		.. frswap_GiB
		.. "GiB, "
		.. swtotal_GiB
		.. "GiB"
	)
	collectgarbage("collect")
end)

return ram_meter
