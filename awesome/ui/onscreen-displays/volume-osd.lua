local awful = require("awful")
local gears = require("gears")
local wibox = require("wibox")
local beautiful = require("beautiful")
local dpi = beautiful.xresources.apply_dpi
local icons = require("theme.icons")

local osd_header = wibox.widget({
	text = "Volume",
	font = "Inter Bold 12",
	align = "left",
	valign = "center",
	widget = wibox.widget.textbox,
})

local osd_value = wibox.widget({
	text = "0%",
	font = "Inter Bold 12",
	align = "center",
	valign = "center",
	widget = wibox.widget.textbox,
})

local slider_osd = wibox.widget({
	nil,
	{
		id = "vol_osd_slider",
		bar_shape = gears.shape.rounded_rect,
		bar_height = dpi(2),
		bar_color = "#ffffff20",
		bar_active_color = "#f2f2f2EE",
		handle_color = "#ffffff",
		handle_shape = gears.shape.circle,
		handle_width = dpi(15),
		handle_border_color = "#00000012",
		handle_border_width = dpi(1),
		maximum = 100,
		widget = wibox.widget.slider,
	},
	nil,
	expand = "none",
	layout = wibox.layout.align.vertical,
})

local vol_osd_slider = slider_osd.vol_osd_slider

-- Dragging the slider changes volume, but still uses the signals to update UI
vol_osd_slider:connect_signal("property::value", function()
	local volume_level = vol_osd_slider:get_value()
	awful.spawn("pactl set-sink-volume @DEFAULT_SINK@ " .. volume_level .. "%", false)
	awesome.emit_signal("volume::update:level", volume_level)

	if awful.screen.focused().show_vol_osd then
		awesome.emit_signal("osd::volume_osd:show", true)
	end
end)

vol_osd_slider:connect_signal("button::press", function()
	awful.screen.focused().show_vol_osd = true
end)

vol_osd_slider:connect_signal("mouse::enter", function()
	awful.screen.focused().show_vol_osd = true
end)

-- 📡 Passive updates: only respond to signals
awesome.connect_signal("volume::update:level", function(level)
	vol_osd_slider:set_value(level)
	osd_value.text = tostring(level) .. "%"
	awesome.emit_signal("osd::volume_osd:show", true) -- show OSD on level change
end)

local widget = wibox.widget({
	{
		id = "icon",
		image = icons.widgets.volume.volume_off,
		widget = wibox.widget.imagebox,
		resize = true,
	},
	top = dpi(12),
	bottom = dpi(12),
	widget = wibox.container.margin,
})

awesome.connect_signal("widget::volume:icon", function(newicon)
	widget.icon:set_image(newicon)
	awesome.emit_signal("osd::volume_osd:show", true) -- show OSD on mute/unmute change
end)

local volume_slider_osd = wibox.widget({
	widget,
	slider_osd,
	spacing = dpi(24),
	layout = wibox.layout.fixed.horizontal,
})

local osd_height = dpi(100)
local osd_width = dpi(300)
local osd_margin = dpi(25)

screen.connect_signal("request::desktop_decoration", function(s)
	s.show_vol_osd = false

	s.volume_osd_overlay = awful.popup({
		widget = {},
		ontop = true,
		visible = false,
		type = "notification",
		screen = s,
		height = osd_height,
		width = osd_width,
		maximum_height = osd_height,
		maximum_width = osd_width,
		offset = dpi(5),
		placement = function(w)
			awful.placement.bottom_left(w, { offset = { x = osd_margin, y = -osd_margin } })
		end,
		shape = gears.shape.rectangle,
		bg = beautiful.transparent,
		preferred_anchors = "middle",
		preferred_positions = { "left", "right", "top", "bottom" },
	})

	s.volume_osd_overlay:setup({
		{
			{
				{
					layout = wibox.layout.align.horizontal,
					expand = "none",
					forced_height = dpi(48),
					osd_header,
					nil,
					osd_value,
				},
				volume_slider_osd,
				layout = wibox.layout.fixed.vertical,
			},
			left = dpi(24),
			right = dpi(24),
			widget = wibox.container.margin,
		},
		bg = beautiful.background,
		shape = gears.shape.rounded_rect,
		widget = wibox.container.background(),
	})

	s.volume_osd_overlay:connect_signal("mouse::enter", function()
		awful.screen.focused().show_vol_osd = true
		awesome.emit_signal("osd::volume_osd:rerun")
	end)
end)

local hide_osd = gears.timer({
	timeout = 2,
	autostart = true,
	callback = function()
		local focused = awful.screen.focused()
		focused.volume_osd_overlay.visible = false
		focused.show_vol_osd = false
	end,
})

awesome.connect_signal("osd::volume_osd:rerun", function()
	if hide_osd.started then
		hide_osd:again()
	else
		hide_osd:start()
	end
end)

awesome.connect_signal("osd::volume_osd:show", function(bool)
	awful.screen.focused().volume_osd_overlay.visible = bool
	if bool then
		awesome.emit_signal("osd::volume_osd:rerun")
		awesome.emit_signal("osd::brightness_osd:show", false)
		awesome.emit_signal("osd::microphone_osd:show", false)
	else
		if hide_osd.started then
			hide_osd:stop()
		end
	end
end)

return volume_slider_osd
