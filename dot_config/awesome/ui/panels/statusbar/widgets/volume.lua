local awful = require("awful")
local wibox = require("wibox")
local gears = require("gears")
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

-- State
local volume_level = 0
local is_muted = false
local device = "speakers"
local last_default_sink = nil

-- Helper functions
local function get_volume_icon(level)
	if tonumber(level) >= 75 then
		return icons.widgets.volume.volume_high
	elseif tonumber(level) >= 50 then
		return icons.widgets.volume.volume_medium
	elseif tonumber(level) >= 25 then
		return icons.widgets.volume.volume_low
	else
		return icons.widgets.volume.volume_off
	end
end

local function update_volume_display()
	local icon
	if device == "headphones" then
		icon = is_muted and icons.widgets.volume.headphones_muted or icons.widgets.volume.headphones
	else
		icon = is_muted and icons.widgets.volume.volume_muted or get_volume_icon(volume_level)
	end

	-- Broadcast icon to other widgets
	awesome.emit_signal("widget::volume:icon", icon)
	widget.icon:set_image(icon)

	volume_tooltip:set_markup(
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

local function refresh_sink_device()
	awful.spawn.easy_async("pactl get-default-sink", function(stdout)
		local sink_name = stdout:gsub("%s+", "")
		if sink_name == "" then
			return
		end
		if sink_name ~= last_default_sink then
			last_default_sink = sink_name
		end

		if sink_name:lower():find("headphone") then
			device = "headphones"
		else
			device = "speakers"
		end
		update_volume_display()
	end)
end

local function check_and_update_volume()
	awful.spawn.easy_async_with_shell(
		"pactl get-sink-volume @DEFAULT_SINK@; pactl get-sink-mute @DEFAULT_SINK@",
		function(stdout)
			local new_level = tonumber(stdout:match("(%d+)%%") or "0")
			local muted_value = stdout:match("Mute:%s*(%a+)")
			local new_muted = (muted_value == "yes")

			local changed = (new_level ~= volume_level) or (new_muted ~= is_muted)
			volume_level = new_level
			is_muted = new_muted

			if changed then
				awesome.emit_signal("volume::update", volume_level)
				update_volume_display()
			end
		end
	)
	refresh_sink_device()
end

-- Debounce timer for pactl events
local volume_timer = gears.timer({
	timeout = 0.08,
	single_shot = true,
	callback = check_and_update_volume,
})
local function debounced_check_and_update_volume()
	volume_timer:again()
end

-- Subscribe to pulseaudio events
awful.spawn.with_line_callback("pactl subscribe", {
	stdout = function(line)
		-- Only respond to sink changes and server changes
		if line:match("Event 'change' on sink") or line:match("Event 'change' on server") then
			debounced_check_and_update_volume()
		end
	end,
})

-- Click to toggle mute
volume:connect_signal("button::press", function(_, _, _, button)
	if button == 1 then
		awful.spawn("pactl set-sink-mute @DEFAULT_SINK@ toggle")
	end
end)

widget_button:connect_signal("button::press", function(_, _, _, button)
	if button == 1 then
		awful.spawn("pactl set-sink-mute @DEFAULT_SINK@ toggle")
	end
end)

-- Initialize on startup
check_and_update_volume()

return widget_button
