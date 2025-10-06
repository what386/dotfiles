local wibox = require("wibox")
local awful = require("awful")
local gears = require("gears")

local clickable_container = require("ui.clickable-container")
local dpi = require("beautiful").xresources.apply_dpi

local icons = require("theme.icons")
local dl_widget = wibox.widget({
	{
		image = icons.folders.downloads,
		resize = true,
		widget = wibox.widget.imagebox,
	},
	layout = wibox.layout.align.horizontal,
})

local downloads_button = wibox.widget({
	{
		dl_widget,
		margins = dpi(10),
		widget = wibox.container.margin,
	},
	widget = clickable_container,
})

downloads_button:buttons(gears.table.join(awful.button({}, 1, nil, function()
	awful.spawn.with_shell("xdg-open $(xdg-user-dir DOWNLOAD)")
end)))

awful.tooltip({
	objects = { downloads_button },
	mode = "outside",
	align = "right",
	text = "Downloads",
	margin_leftright = dpi(8),
	margin_topbottom = dpi(8),
	preferred_positions = { "top", "bottom", "right", "left" },
})

return downloads_button
