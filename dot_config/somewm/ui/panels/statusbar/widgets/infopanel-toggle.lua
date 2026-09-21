local awful = require("awful")
local wibox = require("wibox")
local gears = require("gears")
local dpi = require("beautiful").xresources.apply_dpi
local clickable_container = require("ui.clickable-container")

local icons = require("theme.icons")

return function()
local widget = wibox.widget({
	{
		id = "icon",
		image = icons.system.menu,
		widget = wibox.widget.imagebox,
		resize = true,
	},
	layout = wibox.layout.align.horizontal,
})

local widget_button = wibox.widget({
	{
		widget,
		margins = dpi(7),
		widget = wibox.container.margin,
	},
	widget = clickable_container,
})

widget_button:buttons(gears.table.join(awful.button({}, 1, nil, function()
	local panel = awful.screen.focused().infopanel
	if not panel then return end
	if panel.opened then
		panel:toggle()
	else
		panel:switch_pane("notifications")
		panel:toggle()
	end
end)))

return widget_button
end
