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

local update_tooltip = function(message)
	volume_tooltip:set_markup(message)
end

local volume_level = 0
local is_muted = false
local device = "speakers"

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
		local new_level = tonumber(stdout:match("Volume: front.- (%d+)%%") or "0")
		if new_level ~= volume_level then
			volume_level = new_level

			-- broadcast to any listener (OSD, notifications, etc.)
			awesome.emit_signal("widget::volume:level", volume_level)
		end
		update_volume_display()
	end)
end

local function update_volume_muted()
	awful.spawn.easy_async_with_shell("pactl get-sink-mute @DEFAULT_SINK@", function(stdout)
		local is_muted_string = stdout:match("Mute: (%a+)")
		local new_muted = (is_muted_string == "yes")
		if new_muted ~= is_muted then
			is_muted = new_muted
			-- re-broadcast full state
			awesome.emit_signal("widget::volume:level", volume_level)
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

-- Store previous state to compare against
local last_volume = nil
local last_muted = nil
local last_device = nil

local function check_and_update_volume()
	awful.spawn.easy_async("pactl get-sink-volume @DEFAULT_SINK@", function(volume_out)
		awful.spawn.easy_async("pactl get-sink-mute @DEFAULT_SINK@", function(mute_out)
			awful.spawn.easy_async("pactl get-default-sink", function(device_out)
				local current_volume = volume_out:match("(%d+)%%")
				local current_muted = mute_out:match("Mute: (%w+)")
				local current_device = device_out:gsub("%s+", "")

				-- Only update if something actually changed
				if current_volume ~= last_volume or current_muted ~= last_muted or current_device ~= last_device then
					last_volume = current_volume
					last_muted = current_muted
					last_device = current_device

					update_volume_device()
					update_volume_level()
					update_volume_muted()
				end
			end)
		end)
	end)
end

local volume_timer = nil
local function debounced_check_and_update_volume()
	if volume_timer then
		volume_timer:stop()
	end
	volume_timer = gears.timer({
		timeout = 0.05, -- 50ms debounce
		single_shot = true,
		callback = check_and_update_volume,
	})
	volume_timer:start()
end

awful.spawn.with_line_callback("pactl subscribe", {
	stdout = function(line)
		-- Only respond to sink changes and server changes (default sink change)
		if line:match("Event 'change' on sink") or line:match("Event 'change' on server") then
			debounced_check_and_update_volume()
		end
	end,
})

volume:connect_signal("button::press", function(_, _, _, button)
	if button == 1 then
		awful.spawn("pactl set-sink-mute @DEFAULT_SINK@ toggle")
	end
end)

return widget_button
