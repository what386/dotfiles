local gears = require("gears")
local wibox = require("wibox")
local beautiful = require("beautiful")
local xresources = beautiful.xresources
local dpi = xresources.apply_dpi

local systray = wibox.widget({
	visible = false,
	base_size = dpi(36),
	horizontal = true,
	screen = "primary",
	{
		{
			{
				wibox.widget.systray,
				layout = wibox.layout.fixed.horizontal,
			},
			widget = wibox.container.margin,
		},
		shape = function(cr, w, h)
			gears.shape.rectangle(cr, w, h, 8)
		end,
		bg = beautiful.bg_systray,
		fg = beautiful.fg_systray,
		widget = wibox.container.background,
	},
	margins = { top = dpi(4), bottom = dpi(4) },
	widget = wibox.container.margin,
})

return systray
