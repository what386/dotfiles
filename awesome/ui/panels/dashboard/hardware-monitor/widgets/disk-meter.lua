local wibox = require("wibox")
local gears = require("gears")
local beautiful = require("beautiful")
local watch = require("awful.widget.watch")
local icons = require("theme.icons")
local dpi = beautiful.xresources.apply_dpi

local disk = wibox.widget.textbox()
disk.font = beautiful.widget_text

local slider = wibox.widget({
	nil,
	{
		id = "hdd_usage",
		max_value = 100,
		value = 29,
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

watch([[bash -c "df -h / | grep '^/' | awk '{print $2,$3,$4,$5}'"]], 60, function(_, stdout)
	local total, used, available, consumed = stdout:match("(%d+G) (%d+G) (%d+G) (%d+)")
	slider.hdd_usage:set_value(tonumber(consumed))
	disk.text = used
	collectgarbage("collect")
end)

local disk_meter = wibox.widget({
	{
		{
			{
				{
					image = icons.applets.resources.storage,
					resize = true,
					widget = wibox.widget.imagebox,
				},
				top = dpi(12),
				bottom = dpi(12),
				widget = wibox.container.margin,
			},
			{
				disk,
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

return disk_meter
