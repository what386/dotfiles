local awful = require("awful")
local wibox = require("wibox")
local gears = require("gears")
local beautiful = require("beautiful")
local dpi = beautiful.xresources.apply_dpi
local config_dir = gears.filesystem.get_configuration_dir()
local widget_icon_dir = config_dir .. "ui/panels/musicplayer/icons/"
local media_buttons = require("ui.panels.musicplayer.media-buttons")
local music_updater = require("ui.panels.musicplayer.updater")

-- This file (and its updater) might be the worst code ive ever written

local create_musicplayer = function(s)
	-- Create widgets
	local title = wibox.widget({
		id = "title",
		text = "The song title is here",
		font = "Inter Bold 12",
		align = "center",
		valign = "center",
		ellipsize = "end",
		widget = wibox.widget.textbox,
	})

	local artist = wibox.widget({
		id = "artist",
		text = "The artist name is here",
		font = "Inter 10",
		align = "center",
		valign = "center",
		widget = wibox.widget.textbox,
	})

	local length = wibox.widget({
		id = "length_time",
		text = "00:00",
		font = "Inter 8",
		align = "center",
		valign = "center",
		forced_height = dpi(10),
		widget = wibox.widget.textbox,
	})

	local position = wibox.widget({
		id = "position_time",
		text = "00:00",
		font = "Inter 8",
		align = "center",
		valign = "center",
		forced_height = dpi(10),
		widget = wibox.widget.textbox,
	})

	local progress_bar = wibox.widget({
		{
			id = "music_bar",
			max_value = 100,
			value = 0,
			forced_height = dpi(3),
			forced_width = dpi(100),
			color = "#ffffff",
			background_color = "#ffffff20",
			shape = gears.shape.rounded_bar,
			widget = wibox.widget.progressbar,
		},
		layout = wibox.layout.stack,
	})

	local album_art = wibox.widget({
		{
			id = "cover",
			image = widget_icon_dir .. "vinyl.svg",
			resize = true,
			clip_shape = gears.shape.rounded_rect,
			widget = wibox.widget.imagebox,
		},
		layout = wibox.layout.fixed.vertical,
	})

	-- Register widgets with the updater
	music_updater.register_widgets({
		title = title,
		artist = artist,
		length = length,
		position = position,
		progress_bar = progress_bar:get_children_by_id("music_bar")[1],
		album_art = album_art:get_children_by_id("cover")[1],
	})

	local music_box_margin = dpi(25)
	local music_box_height = dpi(375)
	local music_box_width = dpi(260)

	local musicpop = awful.popup({
		widget = {
			-- Removing this block will cause an error...
		},
		ontop = true,
		visible = false,
		type = "dock",
		screen = s,
		placement = function(w)
			awful.placement.bottom_right(w, { offset = { x = -music_box_margin, y = -music_box_margin } })
		end,
		width = music_box_width,
		height = music_box_height,
		maximum_width = music_box_width,
		maximum_height = music_box_height,
		offset = dpi(5),
		shape = gears.shape.rectangle,
		bg = beautiful.transparent,
		preferred_anchors = { "middle", "back", "front" },
		preferred_positions = { "left", "right", "top", "bottom" },
	})

	musicpop.hover = false

	musicpop:connect_signal("mouse::enter", function()
		musicpop.hover = true
	end)

	musicpop:connect_signal("mouse::leave", function()
		musicpop.hover = false
		awesome.emit_signal("panel::musicplayer:rerun")
	end)

	musicpop:setup({
		{
			{
				layout = wibox.layout.fixed.vertical,
				expand = "none",
				spacing = dpi(8),
				{
					album_art,
					bottom = dpi(5),
					widget = wibox.container.margin,
				},
				{
					layout = wibox.layout.fixed.vertical,
					{
						spacing = dpi(4),
						layout = wibox.layout.fixed.vertical,
						progress_bar,
						{
							expand = "none",
							layout = wibox.layout.align.horizontal,
							position,
							nil,
							length,
						},
					},
					{
						layout = wibox.layout.fixed.vertical,
						{
							title,
							id = "title_scroll_container",
							max_size = 345,
							speed = 75,
							expand = true,
							halign = "center",
							valign = "center",
							direction = "h",
							step_function = wibox.container.scroll.step_functions.waiting_nonlinear_back_and_forth,
							fps = 60,
							layout = wibox.container.scroll.horizontal,
						},
						{
							artist,
							id = "artist_scroll_container",
							max_size = 345,
							speed = 75,
							expand = true,
							halign = "center",
							valign = "center",
							direction = "h",
							step_function = wibox.container.scroll.step_functions.waiting_nonlinear_back_and_forth,
							layout = wibox.container.scroll.horizontal,
							fps = 60,
						},
					},
					media_buttons,
				},
			},
			top = dpi(15),
			left = dpi(15),
			right = dpi(15),
			widget = wibox.container.margin,
		},
		bg = beautiful.background,
		shape = function(cr, width, height)
			gears.shape.partially_rounded_rect(cr, width, height, true, true, true, true, beautiful.groups_radius)
		end,
		widget = wibox.container.background(),
	})

	return musicpop
end

local hide_musicplayer = gears.timer({
	timeout = 4,
	autostart = true,
	callback = function()
		local focused = awful.screen.focused()
		if not focused.musicplayer.hover then
			focused.musicplayer.visible = false
		end
	end,
})

awesome.connect_signal("panel::musicplayer:rerun", function()
	if hide_musicplayer.started then
		hide_musicplayer:again()
	else
		hide_musicplayer:start()
	end
end)

awesome.connect_signal("panel::musicplayer:show", function()
	local focused = awful.screen.focused()
	focused.musicplayer.visible = true
	awesome.emit_signal("panel::musicplayer:rerun")
end)

return create_musicplayer
