local wibox = require("wibox")
local awful = require("awful")
local gears = require("gears")
local beautiful = require("beautiful")
local dpi = beautiful.xresources.apply_dpi
local clickable_container = require("ui.clickable-container")
local config_dir = gears.filesystem.get_configuration_dir()
local widget_icon_dir = config_dir .. "ui/panels/musicplayer/icons/"
local media_buttons = {}

media_buttons.play_button_image = wibox.widget({
	{
		id = "play",
		image = widget_icon_dir .. "play.svg",
		resize = true,
		widget = wibox.widget.imagebox,
	},
	layout = wibox.layout.align.horizontal,
})

media_buttons.next_button_image = wibox.widget({
	{
		id = "next",
		image = widget_icon_dir .. "next.svg",
		resize = true,
		widget = wibox.widget.imagebox,
	},
	layout = wibox.layout.align.horizontal,
})

media_buttons.prev_button_image = wibox.widget({
	{
		id = "prev",
		image = widget_icon_dir .. "prev.svg",
		resize = true,
		widget = wibox.widget.imagebox,
	},
	layout = wibox.layout.align.horizontal,
})

media_buttons.repeat_button_image = wibox.widget({
	{
		id = "rep",
		image = widget_icon_dir .. "repeat-on.svg",
		resize = true,
		widget = wibox.widget.imagebox,
	},
	layout = wibox.layout.align.horizontal,
})

media_buttons.random_button_image = wibox.widget({
	{
		id = "rand",
		image = widget_icon_dir .. "random-on.svg",
		resize = true,
		widget = wibox.widget.imagebox,
	},
	layout = wibox.layout.align.horizontal,
})

media_buttons.play_button = wibox.widget({
	{
		media_buttons.play_button_image,
		margins = dpi(7),
		widget = wibox.container.margin,
	},
	widget = clickable_container,
})

media_buttons.next_button = wibox.widget({
	{
		media_buttons.next_button_image,
		margins = dpi(10),
		widget = wibox.container.margin,
	},
	widget = clickable_container,
})

media_buttons.prev_button = wibox.widget({
	{
		media_buttons.prev_button_image,
		margins = dpi(10),
		widget = wibox.container.margin,
	},
	widget = clickable_container,
})

media_buttons.repeat_button = wibox.widget({
	{
		media_buttons.repeat_button_image,
		margins = dpi(10),
		widget = wibox.container.margin,
	},
	widget = clickable_container,
})

media_buttons.random_button = wibox.widget({
	{
		media_buttons.random_button_image,
		margins = dpi(10),
		widget = wibox.container.margin,
	},
	widget = clickable_container,
})

local navigate_buttons = wibox.widget({
	expand = "none",
	layout = wibox.layout.align.horizontal,
	media_buttons.repeat_button,
	{
		layout = wibox.layout.fixed.horizontal,
		media_buttons.prev_button,
		media_buttons.play_button,
		media_buttons.next_button,
		forced_height = dpi(35),
	},
	media_buttons.random_button,
	forced_height = dpi(35),
})

local loop_table = {
	"None",
	"Track",
	"Playlist",
}

local playpause_status = false

media_buttons.play_button:buttons(gears.table.join(awful.button({}, 1, nil, function()
	if playpause_status then
		awful.spawn.with_shell("playerctl pause")
		media_buttons.play_button_image.play:set_image(widget_icon_dir .. "play.svg")
	else
		awful.spawn.with_shell("playerctl play")
		media_buttons.play_button_image.play:set_image(widget_icon_dir .. "pause.svg")
	end
	playpause_status = not playpause_status
end)))

media_buttons.next_button:buttons(gears.table.join(awful.button({}, 1, nil, function()
	awful.spawn.with_shell("playerctl next")
end)))

media_buttons.prev_button:buttons(gears.table.join(awful.button({}, 1, nil, function()
	awful.spawn.with_shell("playerctl previous")
end)))

local repeat_status = false

media_buttons.repeat_button:buttons(gears.table.join(awful.button({}, 1, nil, function()
	--awful.spawn.with_shell("playerctl repeat")
end)))

local shuffle_status = false

media_buttons.random_button:buttons(gears.table.join(awful.button({}, 1, nil, function()
	if shuffle_status then
		awful.spawn.with_shell("playerctl shuffle Off")
		media_buttons.repeat_button_image.rep:set_image(widget_icon_dir .. "random-off.svg")
	else
		awful.spawn.with_shell("playerctl shuffle On")
		media_buttons.repeat_button_image.rep:set_image(widget_icon_dir .. "random-on.svg")
	end
	shuffle_status = not shuffle_status
end)))

return navigate_buttons
