local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("beautiful")
local dpi = beautiful.xresources.apply_dpi

local create_xdg_widgets = function()
	local separator = wibox.widget({
		orientation = "vertical",
		forced_height = dpi(1),
		forced_width = dpi(1),
		span_ratio = 0.55,
		widget = wibox.widget.separator,
	})

	return wibox.widget({
		layout = wibox.layout.align.horizontal,
		{
			require("ui.panels.statusbar.xdg-folders.home")(),
			require("ui.panels.statusbar.xdg-folders.documents")(),
			require("ui.panels.statusbar.xdg-folders.downloads")(),
			require("ui.panels.statusbar.xdg-folders.pictures")(),
			layout = wibox.layout.fixed.horizontal,
			spacing = dpi(4),
		},
	})
end

return create_xdg_widgets
