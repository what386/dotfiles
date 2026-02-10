local awful = require("awful")
local naughty = require("naughty")
local wibox = require("wibox")
local gears = require("gears")
local beautiful = require("beautiful")
local settings = require("modules.settings-store")

local dpi = beautiful.xresources.apply_dpi
local clickable_container = require("ui.clickable-container")

local icons = require("theme.icons")

_G.dont_disturb = false

local dont_disturb_imagebox = wibox.widget({
	{
		id = "icon",
		image = icons.applets.notifications.dont_disturb_mode,
		resize = true,
		forced_height = dpi(20),
		forced_width = dpi(20),
		widget = wibox.widget.imagebox,
	},
	layout = wibox.layout.fixed.horizontal,
})

local function update_icon()
	local widget_icon_name = nil
	local dd_icon = dont_disturb_imagebox.icon

	if dont_disturb then
		widget_icon_name = "toggled-on"
		dd_icon:set_image(icons.applets.notifications.dont_disturb_mode)
	else
		widget_icon_name = "toggled-off"
		dd_icon:set_image(icons.applets.notifications.notify_mode)
	end
end

local check_disturb_status = function()
	dont_disturb = settings.get_bool("disturb_status", false)
	update_icon()
end

check_disturb_status()

local toggle_disturb = function()
	if dont_disturb then
		dont_disturb = false
	else
		dont_disturb = true
	end
	settings.set_bool("disturb_status", dont_disturb)
	update_icon()
end

local dont_disturb_button = wibox.widget({
	{
		dont_disturb_imagebox,
		margins = dpi(7),
		widget = wibox.container.margin,
	},
	widget = clickable_container,
})

dont_disturb_button:buttons(gears.table.join(awful.button({}, 1, nil, function()
	toggle_disturb()
end)))

local dont_disturb_wrapped = wibox.widget({
	nil,
	{
		dont_disturb_button,
		bg = beautiful.groups_bg,
		shape = gears.shape.circle,
		widget = wibox.container.background,
	},
	nil,
	expand = "none",
	layout = wibox.layout.align.vertical,
})

-- Create a notification sound
naughty.connect_signal("request::display", function(n)
	if not dont_disturb then
		awful.spawn.with_shell("canberra-gtk-play -i message")
	end
end)

return dont_disturb_wrapped
