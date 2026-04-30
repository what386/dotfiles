-- User profile widget
-- Optional dependency:
--    mugshot (use to update profile picture and information)

local awful = require("awful")
local wibox = require("wibox")
local gears = require("gears")
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
		align = "right",
		valign = "center",
		widget = wibox.widget.textbox,
	})

	local left_column_width = dpi(130)
	local right_column_width = dpi(125)

	local top_left = wibox.widget({
		profile_name,
		forced_width = left_column_width,
		strategy = "max",
		widget = wibox.container.constraint,
	})

	local top_right = wibox.widget({
		uptime_time,
		forced_width = right_column_width,
		strategy = "max",
		widget = wibox.container.constraint,
	})

	local bottom_left = wibox.widget({
		distro_name,
		forced_width = left_column_width,
		strategy = "max",
		widget = wibox.container.constraint,
	})

	local bottom_right = wibox.widget({
		kernel_version,
		forced_width = right_column_width,
		strategy = "max",
		widget = wibox.container.constraint,
	})

	local profile_row_top = wibox.widget({
		layout = wibox.layout.align.horizontal,
		top_left,
		nil,
		top_right,
	})

	local profile_row_bottom = wibox.widget({
		layout = wibox.layout.align.horizontal,
		bottom_left,
		nil,
		bottom_right,
	})

	local profile_info = wibox.widget({
		layout = wibox.layout.fixed.vertical,
		spacing = dpi(2),
		profile_row_top,
		profile_row_bottom,
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
		kernel_version:set_markup(kname)
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
		spacing = dpi(10),
		{
			layout = wibox.layout.align.vertical,
			expand = "none",
			profile_imagebox,
		},
		{
			layout = wibox.layout.align.vertical,
			expand = "none",
			profile_info,
		},
	})

	user_profile:connect_signal("mouse::enter", function()
		update_uptime()
	end)

	return user_profile
end

return create_profile
