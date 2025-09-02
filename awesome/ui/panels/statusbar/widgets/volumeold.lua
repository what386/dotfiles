-- Required libraries
local awful = require("awful")
local wibox = require("wibox")
local gears = require("gears")
local watch = require("awful.widget.watch")
local beautiful = require("beautiful")
local dpi = beautiful.xresources.apply_dpi
local clickable_container = require("ui.clickable-container")

local icons = require("theme.icons")

local volume = wibox.widget.textbox()
volume.font = beautiful.popup_subtitle

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

local update_tooltip = function(message)
	volume_tooltip:set_markup(message)
end

local volume_level = 0
local is_muted = false
local device = "speakers"

local function get_volume_icon(level)
	local icon
	if tonumber(level) >= 75 then
		icon = icons.widgets.volume.volume_high
	elseif tonumber(level) >= 50 then
		icon = icons.widgets.volume.volume_medium
	elseif tonumber(level) >= 25 then
		icon = icons.widgets.volume.volume_low
	else
		icon = icons.widgets.volume.volume_off
	end
	return icon
end

local function update_volume_display()
	local icon

	if device == "headphones" then
		if is_muted then
			icon = icons.widgets.volume.headphones_muted
		else
			icon = icons.widgets.volume.headphones
		end
	else
		if is_muted == true then
			icon = icons.widgets.volume.volume_muted
		else
			icon = get_volume_icon(volume_level)
		end
	end

	-- this is so that other widgets can share this logic
	awesome.emit_signal("widget::volume:icon", icon)
	widget.icon:set_image(icon)

	update_tooltip(
		"Volume: <b>"
			.. volume_level
			.. "%</b>"
			.. "\nMuted: <b>"
			.. tostring(is_muted)
			.. "</b>"
			.. "\nOutput: <b>"
			.. device
			.. "</b>"
	)
end

local function update_volume_level()
	awful.spawn.easy_async_with_shell("pactl get-sink-volume @DEFAULT_SINK@", function(stdout)
		volume_level = tonumber(stdout:match("Volume: front.- (%d+)%%") or "0")
		update_volume_display()
	end)
end

local function update_volume_muted()
	awful.spawn.easy_async_with_shell("pactl get-sink-mute @DEFAULT_SINK@", function(stdout)
		local is_muted_string = stdout:match("Mute: (%a+)")

		if is_muted_string == "yes" then
			is_muted = true
		else
			is_muted = false
		end
		update_volume_display()
	end)
end

local function update_volume_device()
	awful.spawn.easy_async("pactl list sinks", function(stdout)
		for line in stdout:gmatch("[^\r\n]+") do
			if line:find("Active Port:") then
				local port = line:match("Active Port: (.+)")
				if port and port:find("headphones") then
					device = "headphones"
				else
					device = "speakers"
				end
			end
		end
		update_volume_display()
	end)
end

widget_button:buttons(gears.table.join(awful.button({}, 1, nil, function()
	awful.spawn("pactl set-sink-mute @DEFAULT_SINK@ toggle", false)
	update_volume_muted()
end)))

volume:connect_signal("button::press", function(_, _, _, button)
	if button == 1 then
		awful.spawn("pactl set-sink-mute @DEFAULT_SINK@ toggle")
		update_volume_muted()
	end
end)

awesome.connect_signal("volume::changed:level", function()
	update_volume_level()
end)

awesome.connect_signal("volume::changed:muted", function()
	update_volume_muted()
end)

awesome.connect_signal("volume::changed:device", function()
	update_volume_device()
end)

awesome.connect_signal("volume::update:level", function(level)
	volume_level = level
	update_volume_display()
end)

gears.timer({
	timeout = 10,
	call_now = true,
	autostart = true,
	callback = function()
		update_volume_level()
		update_volume_muted()
		update_volume_device()
		collectgarbage("collect")
	end,
})

return widget_button
