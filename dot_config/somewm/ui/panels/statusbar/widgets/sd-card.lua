local awful = require("awful")
local wibox = require("wibox")
local gears = require("gears")
local dpi = require("beautiful").xresources.apply_dpi

local clickable_container = require("ui.clickable-container")
local icons = require("theme.icons")

local DEVICE_PATH = "/sys/bus/usb/devices/2-3"
local BOUND_PATH = "/sys/bus/usb/drivers/usb/2-3"
local CMD_OFF = { "sudo", "-n", "/usr/local/bin/sdcard-off" }
local CMD_ON = { "sudo", "-n", "/usr/local/bin/sdcard-on" }

local widget = wibox.widget({
	{
		id = "icon",
		image = icons.widgets.sd_card.sd_unavailable,
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

local sd_tooltip = awful.tooltip({
	objects = { widget_button },
	delay_show = 0.15,
	mode = "outside",
	align = "right",
	margin_leftright = dpi(8),
	margin_topbottom = dpi(8),
	preferred_positions = { "right", "left", "top", "bottom" },
})

local refresh_generation = 0
local state = {
	available = false,
	bound = false,
	busy = false,
}

local function update_display(status_text)
	if not state.available then
		widget.icon:set_image(icons.widgets.sd_card.sd_unavailable)
		sd_tooltip.markup = status_text or "SD card reader unavailable"
		return
	end

	if state.bound then
		widget.icon:set_image(icons.widgets.sd_card.sd_on)
		sd_tooltip.markup = status_text or "SD card reader is on"
	else
		widget.icon:set_image(icons.widgets.sd_card.sd_off)
		sd_tooltip.markup = status_text or "SD card reader is off"
	end
end

local function refresh_state()
	refresh_generation = refresh_generation + 1
	local generation = refresh_generation

	awful.spawn.easy_async({ "test", "-e", DEVICE_PATH }, function(_, _, _, device_exit_code)
		if generation ~= refresh_generation then
			return
		end

		state.available = device_exit_code == 0
		if not state.available then
			state.bound = false
			update_display()
			return
		end

		awful.spawn.easy_async({ "test", "-e", BOUND_PATH }, function(_, _, _, bound_exit_code)
			if generation ~= refresh_generation then
				return
			end

			state.bound = bound_exit_code == 0
			update_display()
		end)
	end)
end

local function toggle_sd_reader()
	if state.busy or not state.available then
		return
	end

	state.busy = true
	local command = state.bound and CMD_OFF or CMD_ON
	local pending_text = state.bound and "Disabling SD card reader..." or "Enabling SD card reader..."
	update_display(pending_text)

	awful.spawn.easy_async(command, function(_, stderr, _, exit_code)
		state.busy = false
		if exit_code ~= 0 then
			local err = (stderr or ""):gsub("%s+$", "")
			if err == "" then
				err = "Command failed"
			end
			update_display("SD card toggle failed: " .. err)
			return
		end

		refresh_state()
	end)
end

widget_button:buttons(gears.table.join(awful.button({}, 1, nil, function()
	toggle_sd_reader()
end)))

widget_button:connect_signal("mouse::enter", refresh_state)

gears.timer({
	timeout = 60,
	autostart = true,
	call_now = true,
	callback = refresh_state,
})

return widget_button
