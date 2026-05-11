local awful = require("awful")
local wibox = require("wibox")
local gears = require("gears")
local naughty = require("naughty")
local watch = awful.widget.watch
local dpi = require("beautiful").xresources.apply_dpi

local clickable_container = require("ui.clickable-container")

local icons = require("theme.icons")

local kbd_state = false

local widget = wibox.widget({
	{
		id = "icon",
		image = icons.system.kb_off,
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

local keyboard_tooltip = awful.tooltip({
	objects = { widget_button },
	delay_show = 0.15,
	mode = "outside",
	align = "right",
	margin_leftright = dpi(8),
	margin_topbottom = dpi(8),
	preferred_positions = { "right", "left", "top", "bottom" },
})

widget_button:buttons(gears.table.join(awful.button({}, 1, nil, function()
	if kbd_state then
		awesome.emit_signal("flyout::osd_keyboard:hide")
		keyboard_tooltip.markup = "Show on-screen keyboard"
		widget.icon:set_image(icons.system.kb_off)
	else
		awesome.emit_signal("flyout::osd_keyboard:show")
		keyboard_tooltip.markup = "Hide on-screen keyboard"
		widget.icon:set_image(icons.system.kb_on)
	end
	kbd_state = not kbd_state
end)))

keyboard_tooltip.markup = "Toggle on-screen keyboard"

return widget_button
