local awful = require("awful")
local wibox = require("wibox")
local gears = require("gears")
local clickable_container = require("ui.clickable-container")

local beautiful = require("beautiful")
local dpi = beautiful.xresources.apply_dpi

local icons = require("theme.icons")

local systray = require("ui.panels.statusbar.applets.systray")

local opened = false

local widget = wibox.widget({
	{
		id = "icon",
		image = icons.system.down_chevron,
		widget = wibox.widget.imagebox,
		resize = true,
	},
	layout = wibox.layout.align.horizontal,
})

local widget_button = wibox.widget({
	{
		widget,
		margins = dpi(6),
		widget = wibox.container.margin,
	},
	widget = clickable_container,
})

local tray = wibox.widget({
	layout = wibox.layout.align.horizontal,
	systray,
	widget_button,
})

widget_button:buttons(gears.table.join(awful.button({}, 1, nil, function()
	if opened then
		widget.icon:set_image(icons.system.down_chevron)
		systray.visible = false
		opened = false
	else
		widget.icon:set_image(icons.system.left_chevron)
		systray.visible = true
		opened = true
	end
end)))

return tray
