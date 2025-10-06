-- User profile widget
-- Optional dependency:
--    mugshot (use to update profile picture and information)

local awful = require("awful")
local wibox = require("wibox")
local gears = require("gears")
local naughty = require("naughty")
local beautiful = require("beautiful")
local dpi = beautiful.xresources.apply_dpi
local preferences = require("config.user.preferences")

local icons = require("theme.icons")

local create_profile = function()
	local profile_imagebox = wibox.widget({
		{
			id = "icon",
			forced_height = dpi(65),
			forced_width = dpi(65),
			image = icons.system.default_user,
			widget = wibox.widget.imagebox,
			resize = true,
			clip_shape = function(cr, width, height)
				gears.shape.rounded_rect(cr, width, height, beautiful.groups_radius)
			end,
		},
		layout = wibox.layout.align.horizontal,
	})

	profile_imagebox:buttons(
		gears.table.join(awful.button({}, 1, nil, function() end), awful.button({}, 3, nil, function() end))
	)

	local profile_name = wibox.widget({
		font = "Inter Regular 10",
		markup = "User",
		align = "left",
		valign = "center",
		widget = wibox.widget.textbox,
	})

	local distro_name = wibox.widget({
		font = "Inter Regular 10",
		markup = "GNU/Linux",
		align = "left",
		valign = "center",
		widget = wibox.widget.textbox,
	})

	local kernel_version = wibox.widget({
		font = "Inter Regular 10",
		markup = "Linux",
		align = "left",
		valign = "center",
		widget = wibox.widget.textbox,
	})

	local uptime_time = wibox.widget({
		font = "Inter Regular 10",
		markup = "up 1 minute",
		align = "left",
		valign = "center",
		widget = wibox.widget.textbox,
	})

	local update_profile_image = function()
		awful.spawn.easy_async_with_shell(preferences.utils.update_profile, function(stdout)
			stdout = stdout:gsub("%\n", "")
			if not stdout:match("default") then
				profile_imagebox.icon:set_image(stdout)
			else
				profile_imagebox.icon:set_image(icons.system.default_user)
			end
		end)
	end

	update_profile_image()

	awful.spawn.easy_async_with_shell(
		[[
	sh -c '
	fullname="$(getent passwd `whoami` | cut -d ':' -f 5 | cut -d ',' -f 1 | tr -d "\n")"
	if [ -z "$fullname" ];
	then
		printf "$(whoami)@$(hostname)"
	else
		printf "$fullname"
	fi
	'
	]],
		function(stdout)
			local stdout = stdout:gsub("%\n", "")
			profile_name:set_markup(stdout)
		end
	)

	awful.spawn.easy_async_with_shell(
		[[
	cat /etc/os-release | awk 'NR==1'| awk -F '"' '{print $2}'
	]],
		function(stdout)
			local distroname = stdout:gsub("%\n", "")
			distro_name:set_markup(distroname)
		end
	)

	awful.spawn.easy_async_with_shell("uname -r", function(stdout)
		local kname = stdout:gsub("%\n", "")
		kernel_version:set_markup("Kernel:" + kname)
	end)

	local update_uptime = function()
		awful.spawn.easy_async_with_shell("uptime -p", function(stdout)
			local uptime = stdout:gsub("%\n", "")
			uptime_time:set_markup(uptime)
		end)
	end

	gears.timer({
		timeout = 60,
		autostart = true,
		call_now = true,
		callback = function()
			update_uptime()
		end,
	})

	local user_profile = wibox.widget({
		layout = wibox.layout.fixed.horizontal,
		spacing = dpi(0),
		{
			layout = wibox.layout.align.vertical,
			expand = "none",
			profile_imagebox,
		},
	})

	user_profile:connect_signal("mouse::enter", function()
		update_uptime()
	end)

	return user_profile
end

return create_profile
