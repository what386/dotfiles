local wibox = require("wibox")
local awful = require("awful")
local gears = require("gears")
local beautiful = require("beautiful")
local dpi = beautiful.xresources.apply_dpi
local clickable_container = require("ui.clickable-container")
local icons = require("theme.icons")
local media = require("services.media")
local media_buttons = {}

media_buttons.play_button_image = wibox.widget({
	{
		id = "play",
		image = icons.applets.media.play,
		resize = true,
		widget = wibox.widget.imagebox,
	},
	layout = wibox.layout.align.horizontal,
})

media_buttons.next_button_image = wibox.widget({
	{
		id = "next",
		image = icons.applets.media.next,
		resize = true,
		widget = wibox.widget.imagebox,
	},
	layout = wibox.layout.align.horizontal,
})

media_buttons.prev_button_image = wibox.widget({
	{
		id = "prev",
		image = icons.applets.media.prev,
		resize = true,
		widget = wibox.widget.imagebox,
	},
	layout = wibox.layout.align.horizontal,
})

media_buttons.repeat_button_image = wibox.widget({
	{
		id = "rep",
		image = icons.applets.media.repeat_on,
		resize = true,
		widget = wibox.widget.imagebox,
	},
	layout = wibox.layout.align.horizontal,
})

media_buttons.random_button_image = wibox.widget({
	{
		id = "rand",
		image = icons.applets.media.random_on,
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

local playpause_status = false

media_buttons.play_button:buttons(gears.table.join(awful.button({}, 1, nil, function()
	media.play_pause()
end)))

media_buttons.next_button:buttons(gears.table.join(awful.button({}, 1, nil, function()
	media.next()
end)))

media_buttons.prev_button:buttons(gears.table.join(awful.button({}, 1, nil, function()
	media.previous()
end)))

media_buttons.repeat_button:buttons(gears.table.join(awful.button({}, 1, nil, function()
end)))

media_buttons.random_button:buttons(gears.table.join(awful.button({}, 1, nil, function()
	media.toggle_shuffle()
end)))

awesome.connect_signal("media::state", function(state)
	playpause_status = state.playing and true or false
	media_buttons.play_button_image.play:set_image(playpause_status and icons.applets.media.pause or icons.applets.media.play)
	media_buttons.random_button_image.rand:set_image(state.shuffle and icons.applets.media.random_on or icons.applets.media.random_off)
end)

return navigate_buttons
