local awful = require("awful")
local gears = require("gears")
local wibox = require("wibox")
local beautiful = require("beautiful")
local glib = require("lgi").GLib
local dpi = beautiful.xresources.apply_dpi
local icons = require("theme.icons")
local sounds = require("theme.sounds")
local clickable_container = require("ui.clickable-container")
local power = require("services.power")
local filesystem = require("gears.filesystem")
local config_dir = filesystem.get_configuration_dir()
local TRANSITION_DURATION = 0.18
local FRAME_INTERVAL = 1 / 60

local active_screen
local exit_screen_grabber
local open = false
local transition_progress = 0
local transition_timer

local function finish_hide()
	if active_screen and active_screen.exit_screen then
		active_screen.exit_screen.visible = false
		active_screen.exit_screen.opacity = 0
	end
	active_screen = nil
	transition_progress = 0
end

local function animate_to(target)
	if transition_timer then transition_timer:stop(); transition_timer = nil end
	local start = transition_progress
	if start == target then
		if target == 0 then finish_hide() end
		return
	end
	local started_at = glib.get_monotonic_time()
	local duration = TRANSITION_DURATION * math.abs(target - start)
	transition_timer = gears.timer({
		timeout = FRAME_INTERVAL,
		callback = function()
			local elapsed = (glib.get_monotonic_time() - started_at) / 1000000
			local fraction = math.min(1, elapsed / duration)
			local eased = target == 1 and (1 - (1 - fraction) ^ 3) or fraction ^ 3
			transition_progress = start + (target - start) * eased
			if active_screen and active_screen.exit_screen then
				active_screen.exit_screen.opacity = transition_progress
			end
			if fraction == 1 then
				transition_timer:stop()
				transition_timer = nil
				if target == 0 and not open then finish_hide() end
			end
		end,
	})
	transition_timer:start()
end

local msg_table = {
	"See you later, alligator!",
	"Stay out of trouble.",
	"I'll still be here.",
	"Gotta get going.",
	"Don't forget to come back!",
	"Better things to do?",
	"Adios, amigo.",
	"Arrivederci.",
	"Never look back!",
	"Au revoir!",
	"Later, skater!",
	"Happy trails!",
	"Sayonara!",
	"See you, Space Cowboy!",
	"Ship log updated.",
	"It's time for something new, now.",
}
local greeter_message = wibox.widget({
	markup = "Choose wisely!",
	font = "Inter UltraLight 48",
	align = "center",
	valign = "center",
	widget = wibox.widget.textbox,
})
local profile_name = wibox.widget({
	markup = "user@domain",
	font = "Inter Bold 12",
	align = "center",
	valign = "center",
	widget = wibox.widget.textbox,
})
local profile_imagebox = wibox.widget({
	image = icons.system.default_user,
	resize = true,
	forced_height = dpi(140),
	clip_shape = gears.shape.circle,
	widget = wibox.widget.imagebox,
})

local update_profile_pic = function()
	awful.spawn.easy_async_with_shell(config_dir .. "/scripts/update_profile.sh", function(stdout)
		stdout = stdout:gsub("%\n", "")
		if not stdout:match("default") then
			profile_imagebox:set_image(stdout)
		else
			profile_imagebox:set_image(icons.system.default_user)
		end
		profile_imagebox:emit_signal("widget::redraw_needed")
	end)
end
update_profile_pic()
local update_user_name = function()
	awful.spawn.easy_async_with_shell(
		[[
		fullname="$(getent passwd `whoami` | cut -d ':' -f 5 | cut -d ',' -f 1 | tr -d "\n")"
		if [ -z "$fullname" ];
		then
				printf "$(whoami)@$(hostname)"
		else
			printf "$fullname"
		fi
		]],
		function(stdout)
			stdout = stdout:gsub("%\n", "")
			local first_name = stdout:match("(.*)@") or stdout:match("(.-)%s")
			if first_name and #first_name > 0 then
				first_name = first_name:sub(1, 1):upper() .. first_name:sub(2)
			end
			profile_name:set_markup(stdout)
			profile_name:emit_signal("widget::redraw_needed")
		end
	)
end
update_user_name()
local update_greeter_msg = function()
	greeter_message:set_markup(msg_table[math.random(#msg_table)])
	greeter_message:emit_signal("widget::redraw_needed")
end
update_greeter_msg()
local build_power_button = function(name, icon, callback)
	local power_button_label = wibox.widget({
		text = name,
		font = "Inter Regular 10",
		align = "center",
		valign = "center",
		forced_width = dpi(138),
		widget = wibox.widget.textbox,
	})
	local power_button = wibox.widget({
		{
			{
				{
					{
						image = icon,
						widget = wibox.widget.imagebox,
					},
					margins = dpi(16),
					widget = wibox.container.margin,
				},
				bg = beautiful.groups_bg,
				widget = wibox.container.background,
			},
			shape = gears.shape.rounded_rect,
			forced_width = dpi(90),
			forced_height = dpi(90),
			widget = clickable_container,
		},
		left = dpi(24),
		right = dpi(24),
		widget = wibox.container.margin,
	})
	local exit_screen_item = wibox.widget({
		layout = wibox.layout.fixed.vertical,
		spacing = dpi(5),
		power_button,
		power_button_label,
	})
	exit_screen_item:connect_signal("button::release", function()
		callback()
	end)
	return exit_screen_item
end
local suspend_command = function()
	power.suspend()
end
local logout_command = function()
	sounds.play("logout")
	awesome.emit_signal("module::session_manager:save")
	gears.timer({
		timeout = 0.5,
		autostart = true,
		single_shot = true,
		callback = function()
			awesome.quit()
		end,
	})
end
local lock_command = function()
	power.lock()
end
local hibernate_command = function()
	power.hibernate()
end
local poweroff_command = function()
	power.poweroff()
end
local reboot_command = function()
	power.reboot()
end
local poweroff = build_power_button("[P]ower off", icons.power.power, poweroff_command)
local reboot = build_power_button("[R]estart", icons.power.reboot, reboot_command)
local hibernate = build_power_button("[H]ibernate", icons.power.hibernate, hibernate_command)
local suspend = build_power_button("[S]uspend", icons.power.sleep, suspend_command)
local logout = build_power_button("[E]xit user", icons.power.logout, logout_command)
local lock = build_power_button("[L]ock", icons.power.lock, lock_command)
local create_exit_screen = function(s)
	s.exit_screen = wibox({
		screen = s,
		type = "notification",
		visible = false,
		ontop = true,
		opacity = 0,
		bg = beautiful.overlay_backdrop,
		fg = beautiful.fg_normal,
		height = s.geometry.height,
		width = s.geometry.width,
		x = s.geometry.x,
		y = s.geometry.y,
	})
	s.exit_screen:buttons({
		awful.button({}, 2, function()
			awesome.emit_signal("screen::exit_screen:hide")
		end),
		awful.button({}, 3, function()
			awesome.emit_signal("screen::exit_screen:hide")
		end)
	})
	s.exit_screen:setup({
		layout = wibox.layout.align.vertical,
		expand = "none",
		nil,
		{
			layout = wibox.layout.align.vertical,
			{
				nil,
				{
					layout = wibox.layout.fixed.vertical,
					spacing = dpi(5),
					{
						layout = wibox.layout.align.vertical,
						expand = "none",
						nil,
						{
							layout = wibox.layout.align.horizontal,
							expand = "none",
							nil,
							profile_imagebox,
							nil,
						},
						nil,
					},
					profile_name,
				},
				nil,
				expand = "none",
				layout = wibox.layout.align.horizontal,
			},
			{
				layout = wibox.layout.align.horizontal,
				expand = "none",
				nil,
				{
					widget = wibox.container.margin,
					margins = dpi(15),
					greeter_message,
				},
				nil,
			},
			{
				layout = wibox.layout.align.horizontal,
				expand = "none",
				nil,
				{
					{
						{
							poweroff,
							reboot,
							hibernate,
							suspend,
							logout,
							lock,
							layout = wibox.layout.fixed.horizontal,
						},
						spacing = dpi(30),
						layout = wibox.layout.fixed.vertical,
					},
					widget = wibox.container.margin,
					margins = dpi(15),
				},
				nil,
			},
		},
		nil,
	})
end
screen.connect_signal("request::desktop_decoration", function(s)
	create_exit_screen(s)
end)
screen.connect_signal("removed", function(s)
	if active_screen == s then
		if transition_timer then transition_timer:stop(); transition_timer = nil end
		if open and exit_screen_grabber then exit_screen_grabber:stop() end
		active_screen = nil
		open = false
		transition_progress = 0
	end
	if s.exit_screen then s.exit_screen.visible = false; s.exit_screen = nil end
end)
exit_screen_grabber = awful.keygrabber({
	auto_start = false,
	stop_event = "release",
	keypressed_callback = function(self, mod, key, command)
		if key == "s" then
			suspend_command()
		elseif key == "e" then
			logout_command()
		elseif key == "l" then
			lock_command()
		elseif key == "h" then
			hibernate_command()
		elseif key == "p" then
			poweroff_command()
		elseif key == "r" then
			reboot_command()
		elseif key == "Escape" or key == "q" or key == "x" then
			awesome.emit_signal("screen::exit_screen:hide")
		end
	end,
})
awesome.connect_signal("screen::exit_screen:show", function()
	if open then return end
	local focused = awful.screen.focused()
	if not focused or not focused.exit_screen then return end
	if active_screen and active_screen ~= focused then
		active_screen.exit_screen.visible = false
		transition_progress = 0
	end
	for s in screen do
		if s ~= focused then s.exit_screen.visible = false end
	end
	active_screen = focused
	focused.exit_screen:geometry(focused.geometry)
	focused.exit_screen.opacity = transition_progress
	focused.exit_screen.visible = true
	open = true
	animate_to(1)
	exit_screen_grabber:start()
end)
awesome.connect_signal("screen::exit_screen:hide", function()
	if not open then return end
	open = false
	update_greeter_msg()
	exit_screen_grabber:stop()
	animate_to(0)
end)
