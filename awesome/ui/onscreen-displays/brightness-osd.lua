local awful = require("awful")
local gears = require("gears")
local wibox = require("wibox")
local beautiful = require("beautiful")
local dpi = beautiful.xresources.apply_dpi
local icons = require("theme.icons")

local osd_header = wibox.widget({
	text = "Brightness",
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
		id = "bri_osd_slider",
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

local bri_osd_slider = slider_osd.bri_osd_slider

bri_osd_slider:connect_signal("property::value", function()
	local brightness_level = bri_osd_slider:get_value()

	awful.spawn("brightnessctl s " .. math.max(brightness_level, 5) .. "%", false)

	-- Update textbox widget text
	osd_value.text = brightness_level .. "%"

	-- Update the brightness slider if values here change
	awesome.emit_signal("widget::brightness:update", brightness_level)

	if awful.screen.focused().show_bri_osd then
		awesome.emit_signal("osd::brightness_osd:show", true)
	end
end)

bri_osd_slider:connect_signal("button::press", function()
	awful.screen.focused().show_bri_osd = true
end)

bri_osd_slider:connect_signal("mouse::enter", function()
	awful.screen.focused().show_bri_osd = true
end)

-- The emit will come from brightness slider
awesome.connect_signal("osd::brightness_osd", function(brightness)
	bri_osd_slider:set_value(brightness)
end)

local icon = wibox.widget({
	{
		image = icons.widgets.brightness.brightness,
		resize = true,
		widget = wibox.widget.imagebox,
	},
	top = dpi(12),
	bottom = dpi(12),
	widget = wibox.container.margin,
})

local brightness_slider_osd = wibox.widget({
	icon,
	slider_osd,
	spacing = dpi(24),
	layout = wibox.layout.fixed.horizontal,
})

local osd_height = dpi(100)
local osd_width = dpi(300)
local osd_margin = dpi(25)

screen.connect_signal("request::desktop_decoration", function(s)
	local s = s or {}
	s.show_bri_osd = false

	s.brightness_osd_overlay = awful.popup({
		widget = {
			-- Removing this block will cause an error...
		},
		ontop = true,
		visible = false,
		type = "notification",
		screen = s,
		height = osd_height,
		width = osd_width,
		maximum_height = osd_height,
		maximum_width = osd_width,
		placement = function(w)
			awful.placement.bottom_left(w, { offset = { x = osd_margin, y = -osd_margin } })
		end,
		offset = dpi(5),
		shape = gears.shape.rectangle,
		bg = beautiful.transparent,
		preferred_anchors = "middle",
		preferred_positions = { "left", "right", "top", "bottom" },
	})

	s.brightness_osd_overlay:setup({
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
				brightness_slider_osd,
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

	-- Reset timer on mouse hover
	s.brightness_osd_overlay:connect_signal("mouse::enter", function()
		awful.screen.focused().show_bri_osd = true
		awesome.emit_signal("osd::brightness_osd:rerun")
	end)
end)

local hide_osd = gears.timer({
	timeout = 2,
	autostart = true,
	callback = function()
		local focused = awful.screen.focused()
		focused.brightness_osd_overlay.visible = false
		focused.show_bri_osd = false
	end,
})

awesome.connect_signal("osd::brightness_osd:rerun", function()
	if hide_osd.started then
		hide_osd:again()
	else
		hide_osd:start()
	end
end)

awesome.connect_signal("osd::brightness_osd:show", function(bool)
	awful.screen.focused().brightness_osd_overlay.visible = bool
	if bool then
		awesome.emit_signal("osd::brightness_osd:rerun")
		awesome.emit_signal("osd::volume_osd:show", false)
		--awesome.emit_signal("osd::microphone_osd:show", false)
	else
		if hide_osd.started then
			hide_osd:stop()
		end
	end
end)
