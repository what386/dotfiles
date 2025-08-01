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
	text = "Disk",
	font = "Inter Bold 10",
	align = "left",
	widget = wibox.widget.textbox,
})

local icon = wibox.widget({
	layout = wibox.layout.align.vertical,
	expand = "none",
	nil,
	{
		image = widget_icon_dir .. "storage.svg",
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
		id = "disk_usage",
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

local disk_meter = wibox.widget({
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

watch([[bash -c "df -h / | grep '^/' | awk '{print $2,$3,$4,$5}'"]], 60, function(_, stdout)
	local total, used, available, consumed = stdout:match("(%d+G) (%d+G) (%d+G) (%d+)")
	slider.disk_usage:set_value(tonumber(consumed))
	meter_info:set_text("Disk (used/total): " .. used .. ", " .. total)
	collectgarbage("collect")
end)

return disk_meter
