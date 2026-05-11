local wibox = require("wibox")
local beautiful = require("beautiful")
local dpi = beautiful.xresources.apply_dpi

local separator = wibox.widget({
	orientation = "vertical",
	forced_height = dpi(1),
	forced_width = dpi(1),
	span_ratio = 0.55,
	widget = wibox.widget.separator,
})

local folders = wibox.widget({
	layout = wibox.layout.align.horizontal,
	{
		require("ui.panels.dock.xdg-folders.home"),
		require("ui.panels.dock.xdg-folders.documents"),
		require("ui.panels.dock.xdg-folders.downloads"),
		require("ui.panels.dock.xdg-folders.pictures"),
		separator,
		require("ui.panels.dock.xdg-folders.trash"),
		layout = wibox.layout.fixed.horizontal,
	},
})

return folders
