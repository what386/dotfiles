local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("beautiful")
local dpi = beautiful.xresources.apply_dpi
local clickable_container = require("ui.clickable-container")
local icons = require("theme.icons")
local audio = require("services.audio")

local widget = wibox.widget({
	{
		id = "icon",
		image = icons.widgets.volume.volume_off,
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

local volume_tooltip = awful.tooltip({
	text = "Loading...",
	objects = { widget_button },
	delay_show = 0.15,
	mode = "outside",
	align = "right",
	preferred_positions = { "left", "right", "top", "bottom" },
	margin_leftright = dpi(8),
	margin_topbottom = dpi(8),
})

local function update_tooltip(state)
	state = state or audio.get_state()
	local output = state.default_sink or "unknown"
	volume_tooltip:set_markup(
		"Volume: <b>"
			.. tostring(state.output_volume or 0)
			.. "%</b>"
			.. "\nMuted: <b>"
			.. tostring(state.output_muted and true or false)
			.. "</b>"
			.. "\nOutput: <b>"
			.. output
			.. "</b>"
	)
end

awesome.connect_signal("widget::volume:icon", function(icon)
	widget.icon:set_image(icon)
end)

awesome.connect_signal("audio::state", function(state)
	update_tooltip(state)
end)

widget_button:connect_signal("button::press", function(_, _, _, button)
	if button == 1 then
		audio.toggle_output_mute()
		awesome.emit_signal("osd::volume_osd:show", true)
	end
end)

update_tooltip(audio.get_state())
audio.refresh_state()

return widget_button
