local wibox = require("wibox")
local gears = require("gears")
local awful = require("awful")
local naughty = require("naughty")
local beautiful = require("beautiful")
local config_dir = gears.filesystem.get_configuration_dir()
local dpi = beautiful.xresources.apply_dpi
local apps = require("config.user.preferences")
local widget_icon_dir = config_dir .. "configuration/user-profile/"

package.cpath = package.cpath .. ";" .. config_dir .. "/library/?.so;" .. "/usr/lib/lua-pam/?.so;"

-- Locker configuration
local locker_config = {
	using_pam = true,
	military_clock = false,
	fallback_password = "password",
	blur_background = true,
	bg_dir = config_dir .. "theme/wallpapers/",
	bg_image = "morning-wallpaper.jpg",
	tmp_wall_dir = "/tmp/awesomewm/" .. os.getenv("USER") .. "/",
	enable_fingerprint = true,
	fingerprint_timeout = 10,
	show_fingerprint_feedback = true,
}

-- Fallback authentication
local function fallback_auth(password)
	return password == locker_config.fallback_password
end

-- PAM authentication wrapper
local function pam_auth(password)
	if not locker_config.using_pam then
		return fallback_auth(password)
	end
	local pam = require("liblua_pam")
	return pam.auth_current_user(password)
end

-- =========================
-- AUTHENTICATION MANAGER
-- =========================
local auth_manager = {
	password_grabber = nil,
	fingerprint_active = false,
	type_again = true,
	callbacks = {},
}

function auth_manager:start(callbacks)
	self.callbacks = callbacks or {}
	self.type_again = true
end

function auth_manager:stop()
	self.type_again = false
	if self.password_grabber then
		self.password_grabber:stop()
	end
	self.password_grabber = nil
	self:stop_fingerprint()
end

function auth_manager:on_success()
	if self.callbacks.on_success then
		self.callbacks.on_success()
	end
end

function auth_manager:on_failure()
	if self.callbacks.on_failure then
		self.callbacks.on_failure()
	end
end

-- =========================
-- FINGERPRINT AUTH MODULE
-- =========================
local fingerprint_auth = {}

function fingerprint_auth:start(callbacks)
	if not locker_config.enable_fingerprint or not auth_manager.type_again then
		return
	end

	auth_manager.fingerprint_active = true

	awful.spawn.easy_async_with_shell("pgrep -x open-fprintd >/dev/null || (open-fprintd &)", function()
		gears.timer.start_new(0.5, function()
			if not auth_manager.type_again or not auth_manager.fingerprint_active then
				return
			end

			awful.spawn.easy_async_with_shell("fprintd-verify 2>&1", function(stdout, stderr, reason, code)
				if not auth_manager.type_again or not auth_manager.fingerprint_active then
					return
				end

				local success = code == 0
					or stdout:match("verify%-match")
					or stdout:match("Match!")
					or stdout:lower():match("success")
				auth_manager.fingerprint_active = false

				if success then
					auth_manager:stop()
					callbacks.on_success()
				else
					if locker_config.show_fingerprint_feedback and callbacks.on_failure then
						callbacks.on_failure()
					end
				end
			end)
		end)
	end)
end

function auth_manager:stop_fingerprint()
	auth_manager.fingerprint_active = false
	awful.spawn.with_shell("pkill -f 'fprintd-verify' 2>/dev/null")
	awful.spawn.with_shell("pkill -f 'open-fprintd' 2>/dev/null")
end

-- =========================
-- PASSWORD AUTH MODULE
-- =========================
local password_auth = {}

function password_auth:start(callbacks, password_display_widget, caps_text_widget)
	local input_password = ""

	local update_display = function()
		password_display_widget:set_markup(string.rep("*", #input_password))
	end

	local check_caps = function()
		awful.spawn.easy_async_with_shell("xset q | grep Caps | cut -d: -f3 | cut -d0 -f1 | tr -d ' '", function(stdout)
			caps_text_widget.opacity = stdout:match("on") and 1.0 or 0.0
			caps_text_widget:emit_signal("widget::redraw_needed")
		end)
	end

	local grabber = awful.keygrabber({
		auto_start = true,
		stop_event = "release",
		keypressed_callback = function(_, _, key)
			if not auth_manager.type_again then
				return
			end

			if key == "BackSpace" then
				input_password = string.sub(input_password, 1, -2)
				update_display()
				return
			elseif key == "Escape" then
				input_password = ""
				update_display()
				auth_manager:stop_fingerprint()
				return
			elseif #key == 1 then
				input_password = input_password .. key
				update_display()
			elseif key == "Return" then
				auth_manager.type_again = false
				auth_manager:stop_fingerprint()
				local authenticated = pam_auth(input_password)
				input_password = ""
				update_display()

				if authenticated then
					grabber:stop()
					callbacks.on_success()
				else
					callbacks.on_failure()
				end
			elseif key == "Caps_Lock" then
				check_caps()
			end
		end,
	})

	auth_manager.password_grabber = grabber
	grabber:start()
end

-- =========================
-- EXPORTED MODULE
-- =========================
return {
	auth_manager = auth_manager,
	password_auth = password_auth,
	fingerprint_auth = fingerprint_auth,
	locker_config = locker_config,
}
