local wibox = require("wibox")
local gears = require("gears")
local awful = require("awful")
local naughty = require("naughty")
local beautiful = require("beautiful")
local sounds = require("theme.sounds")
local config_dir = gears.filesystem.get_configuration_dir()
local dpi = beautiful.xresources.apply_dpi
local apps = require("config.user.preferences")
local icons = require("theme.icons")

-- Add PAM library path
package.cpath = package.cpath .. ";" .. config_dir .. "/library/?.so;" .. "/usr/lib/lua-pam/?.so;"

-- ============================================================================
-- CONFIGURATION
-- ============================================================================
local config = {
	using_pam = true,
	military_clock = false,
	blur_background = true,
	bg_dir = config_dir .. "theme/wallpapers/",
	bg_image = "morning-wallpaper.jpg",
	tmp_wall_dir = "/tmp/awesomewm/" .. os.getenv("USER") .. "/",
	enable_fingerprint = true,
	show_fingerprint_feedback = true,
	max_password_length = 256,
}

local function shell_quote(text)
	return "'" .. tostring(text):gsub("'", [['"'"']]) .. "'"
end

-- ============================================================================
-- AUTHENTICATION MANAGER
-- ============================================================================
local AuthManager = {}
AuthManager.__index = AuthManager

function AuthManager:new()
	local self = setmetatable({}, AuthManager)
	self.is_authenticating = false
	self.password_grabber = nil
	self.fingerprint_active = false
	self.fingerprint_pid = nil
	self.fingerprint_retry_timer = nil
	self.fingerprint_success = false
	self.authenticated = false -- Prevent double-unlock
	self:_init_pam()
	return self
end

function AuthManager:_init_pam()
	-- Try to load PAM
	if config.using_pam then
		local success, pam = pcall(require, "liblua_pam")
		if success then
			self.pam = pam
			self.use_pam = true
		else
			naughty.notification({
				app_name = "Security",
				title = "WARNING",
				message = "PAM library not available! Lockscreen disabled for security.",
				urgency = "critical",
			})
			self.use_pam = false
		end
	else
		naughty.notification({
			app_name = "Security",
			title = "WARNING",
			message = "PAM disabled! Lockscreen not secure.",
			urgency = "critical",
		})
		self.use_pam = false
	end
end

function AuthManager:authenticate_password(password)
	-- Validate password
	if not password or #password == 0 then
		return false
	end

	if not self.use_pam then
		return false
	end

	-- Wrap PAM call in pcall for safety
	local success, result = pcall(function()
		return self.pam.auth_current_user(password)
	end)

	if not success then
		naughty.notification({
			app_name = "Security",
			title = "Authentication Error",
			message = "PAM authentication failed",
			urgency = "critical",
		})
		return false
	end

	return result
end

function AuthManager:start(on_success_callback, on_failure_callback, password_widget, capslock_widget)
	if self.is_authenticating then
		return false
	end

	self.is_authenticating = true
	self.authenticated = false
	self.on_success = on_success_callback
	self.on_failure = on_failure_callback

	-- Start both methods
	self:_start_password_grabber(password_widget, capslock_widget)

	if config.enable_fingerprint then
		self:_start_fingerprint()
	end

	return true
end

function AuthManager:stop()
	self.is_authenticating = false

	-- Stop password grabber
	if self.password_grabber then
		-- Prefer instance stop to ensure this exact grabber is released.
		pcall(function()
			self.password_grabber:stop()
		end)
		awful.keygrabber.stop(self.password_grabber)
		self.password_grabber = nil
	end

	-- Stop fingerprint
	self:_stop_fingerprint()
end

function AuthManager:_start_password_grabber(password_widget, capslock_widget)
	local input_password = ""

	local function update_display()
		password_widget:set_markup(string.rep("*", #input_password))
	end

	local function check_capslock()
		awful.spawn.easy_async_with_shell("xset q | grep Caps | cut -d: -f3 | cut -d0 -f1 | tr -d ' '", function(stdout)
			capslock_widget.opacity = stdout:match("on") and 1.0 or 0.0
			capslock_widget:emit_signal("widget::redraw_needed")
		end)
	end

	self.password_grabber = awful.keygrabber({
		auto_start = false,
		stop_event = "release",
		mask_event_callback = true,
		keypressed_callback = function(_, _, key)
			if not self.is_authenticating then
				return
			end

			if key == "Escape" then
				-- Clear password and reset
				input_password = ""
				update_display()
			elseif key == "BackSpace" then
				if #input_password > 0 then
					input_password = input_password:sub(1, -2)
					update_display()
				end
			elseif #key == 1 then
				-- Regular character input
				if #input_password < config.max_password_length then
					input_password = input_password .. key
					update_display()
				end
			end
		end,

		keyreleased_callback = function(_, _, key)
			if key == "Caps_Lock" then
				check_capslock()
			end

			if not self.is_authenticating then
				return
			end

			if key == "Return" then
				local password = input_password
				input_password = "" -- Clear immediately
				update_display()

				if self:authenticate_password(password) then
					self:_handle_success("password")
				else
					self:_handle_failure("password")
				end
			end
		end,
	})

	self.password_grabber:start()
	check_capslock() -- Initial check
end

function AuthManager:_start_fingerprint()
	if self.fingerprint_active then
		return
	end

	self.fingerprint_active = true
	self.fingerprint_success = false

	-- Start fingerprint verification
	self.fingerprint_pid = awful.spawn.with_line_callback("fprintd-verify", {
		stdout = function(line)
			if not self.fingerprint_active or not self.is_authenticating or not line then
				return
			end
			local lowered = line:lower()
			if lowered:match("verify%-match") or lowered:match("match") or lowered:match("success") then
				self.fingerprint_success = true
			end
		end,
		stderr = function(line)
			if not self.fingerprint_active or not self.is_authenticating or not line then
				return
			end
			local lowered = line:lower()
			if lowered:match("verify%-match") or lowered:match("match") or lowered:match("success") then
				self.fingerprint_success = true
			end
		end,
		exit = function(_, code)
			if not self.fingerprint_active or not self.is_authenticating then
				return
			end

			self.fingerprint_active = false
			self.fingerprint_pid = nil

			local success = self.fingerprint_success or code == 0
			self.fingerprint_success = false

			if success then
				self:_handle_success("fingerprint")
			else
				self:_handle_failure("fingerprint")
				if self.is_authenticating then
					if self.fingerprint_retry_timer then
						self.fingerprint_retry_timer:stop()
					end
					self.fingerprint_retry_timer = gears.timer({
						timeout = 1,
						single_shot = true,
						callback = function()
							if self.is_authenticating then
								self:_start_fingerprint()
							end
						end,
					})
					self.fingerprint_retry_timer:start()
				end
			end
		end,
	})
end

function AuthManager:_stop_fingerprint()
	self.fingerprint_active = false

	if self.fingerprint_retry_timer then
		self.fingerprint_retry_timer:stop()
		self.fingerprint_retry_timer = nil
	end

	if self.fingerprint_pid then
		awful.spawn.with_shell("kill -TERM " .. tostring(self.fingerprint_pid) .. " 2>/dev/null")
		self.fingerprint_pid = nil
	else
		local user = os.getenv("USER")
		if user and user ~= "" then
			awful.spawn.with_shell("pkill -u " .. shell_quote(user) .. " -x fprintd-verify 2>/dev/null")
		else
			awful.spawn.with_shell("pkill -x fprintd-verify 2>/dev/null")
		end
	end
end

function AuthManager:_handle_success(method)
	-- Prevent race conditions - only allow one success
	if self.authenticated or not self.is_authenticating then
		return
	end

	self.authenticated = true

	-- Stop everything immediately
	self:stop()

	-- Call success callback
	if self.on_success then
		self.on_success(method)
	end
end

function AuthManager:_handle_failure(method)
	if not self.is_authenticating or self.authenticated then
		return
	end

	-- Call failure callback (but don't stop - allow retry)
	if self.on_failure then
		self.on_failure(method)
	end
end

-- ============================================================================
-- LOCKSCREEN UI
-- ============================================================================
local LockscreenUI = {}
LockscreenUI.__index = LockscreenUI

function LockscreenUI:new(s)
	local self = setmetatable({}, LockscreenUI)
	self.screen = s
	self:_create_widgets()
	self:_create_lockscreen()
	return self
end

function LockscreenUI:_create_widgets()
	self.password_default_border_color = "#00000045"

	-- Username
	self.username = wibox.widget({
		markup = os.getenv("USER") or "user",
		font = "Inter Bold 12",
		align = "center",
		valign = "center",
		widget = wibox.widget.textbox,
	})

	-- Caps Lock indicator
	self.capslock = wibox.widget({
		markup = "Caps Lock is on",
		font = "Inter Italic 10",
		align = "center",
		valign = "center",
		opacity = 0.0,
		widget = wibox.widget.textbox,
	})

	-- Status text
	self.status = wibox.widget({
		markup = '<span color="#ffffff" font="Inter 10">Touch sensor or enter password</span>',
		align = "center",
		valign = "center",
		opacity = 0.8,
		widget = wibox.widget.textbox,
	})

	-- Profile image
	self.profile_image = wibox.widget({
		image = icons.system.default_user,
		resize = true,
		forced_height = dpi(130),
		forced_width = dpi(130),
		clip_shape = gears.shape.circle,
		widget = wibox.widget.imagebox,
	})

	-- Clock
	local clock_format = config.military_clock and '<span font="Inter Bold 52">%H:%M</span>'
		or '<span font="Inter Bold 52">%I:%M %p</span>'
	self.clock = wibox.widget.textclock(clock_format, 1)

	-- Date
	self.date = wibox.widget({
		markup = self:_format_date(),
		font = "Inter Bold 20",
		align = "center",
		valign = "center",
		widget = wibox.widget.textbox,
	})

	-- Password display
	self.password_display = wibox.widget({
		markup = "",
		font = "Inter Bold 16",
		align = "center",
		valign = "center",
		widget = wibox.widget.textbox,
	})

	-- Password container
	self.password_container = wibox.widget({
		{
			self.password_display,
			margins = dpi(2.5),
			widget = wibox.container.margin,
		},
		bg = "#00000032",
		fg = beautiful.fg_normal,
		forced_width = dpi(300),
		forced_height = dpi(36),
		shape = gears.shape.rounded_rect,
		border_width = dpi(2),
		border_color = self.password_default_border_color,
		widget = wibox.container.background,
	})
end

function LockscreenUI:_format_date()
	local date = os.date("%d")
	local day = os.date("%A")
	local month = os.date("%B")

	date = date:gsub("^0", "")

	local ordinal = "th"
	local last_digit = date:sub(-1)
	if last_digit == "1" and date ~= "11" then
		ordinal = "st"
	elseif last_digit == "2" and date ~= "12" then
		ordinal = "nd"
	elseif last_digit == "3" and date ~= "13" then
		ordinal = "rd"
	end

	return date .. ordinal .. " of " .. month .. ", " .. day
end

function LockscreenUI:_create_lockscreen()
	self.lockscreen = wibox({
		screen = self.screen,
		visible = false,
		ontop = true,
		type = "splash",
		width = self.screen.geometry.width,
		height = self.screen.geometry.height,
		bg = beautiful.background,
		fg = beautiful.fg_normal,
	})

	self.lockscreen:setup({
		layout = wibox.layout.align.horizontal,
		expand = "none",
		nil,
		{
			layout = wibox.layout.align.vertical,
			expand = "none",
			{
				widget = wibox.container.margin,
				top = dpi(100),
				{
					layout = wibox.layout.fixed.vertical,
					spacing = dpi(5),
					{
						self.clock,
						halign = "center",
						widget = wibox.container.place,
					},
					{
						self.date,
						halign = "center",
						widget = wibox.container.place,
					},
				},
			},
			{
				layout = wibox.layout.fixed.vertical,
				spacing = dpi(15),
				{
					layout = wibox.layout.fixed.vertical,
					spacing = dpi(15),
					{
						self.profile_image,
						halign = "center",
						widget = wibox.container.place,
					},
					{
						self.username,
						halign = "center",
						widget = wibox.container.place,
					},
				},
				{
					layout = wibox.layout.fixed.vertical,
					spacing = dpi(5),
					{
						self.password_container,
						halign = "center",
						widget = wibox.container.place,
					},
					{
						self.status,
						halign = "center",
						widget = wibox.container.place,
					},
				},
				{
					self.capslock,
					halign = "center",
					widget = wibox.container.place,
				},
			},
			nil,
		},
		nil,
	})
end

function LockscreenUI:show_failure(method)
	local red = beautiful.system_red_dark or "#bf616a"
	self.password_container.border_color = red
	self.password_container:emit_signal("widget::redraw_needed")

	if method == "fingerprint" and config.show_fingerprint_feedback then
		self.status:set_markup('<span color="#bf616a" font="Inter 10">Fingerprint failed - try password</span>')
	end

	gears.timer.start_new(1, function()
		self.password_container.border_color = self.password_default_border_color
		self.password_container:emit_signal("widget::redraw_needed")
		self.status:set_markup('<span color="#ffffff" font="Inter 10">Touch sensor or enter password</span>')
		return false
	end)
end

function LockscreenUI:show_success()
	local green = beautiful.system_green_dark or "#a3be8c"
	self.password_container.border_color = green
	self.password_container:emit_signal("widget::redraw_needed")
end

function LockscreenUI:show()
	self.lockscreen.visible = true
	self.clock:emit_signal("widget::redraw_needed")
end

function LockscreenUI:hide()
	self.lockscreen.visible = false
end

function LockscreenUI:reset()
	self.password_container.border_color = self.password_default_border_color
	self.password_container:emit_signal("widget::redraw_needed")
	self.password_display:set_markup("")
	self.status:set_markup('<span color="#ffffff" font="Inter 10">Touch sensor or enter password</span>')
end

function LockscreenUI:update_user_info()
	-- Update username
	awful.spawn.easy_async_with_shell(
		[[sh -c 'fullname="$(getent passwd $(whoami) | cut -d: -f5 | cut -d, -f1)"
        if [ -z "$fullname" ]; then
            printf "$(whoami)@$(hostname)"
        else
            printf "$fullname"
        fi']],
		function(stdout)
			self.username:set_markup(stdout:gsub("\n", ""))
		end
	)

	-- Update profile image
	awful.spawn.easy_async_with_shell(apps.utils.update_profile, function(stdout)
		stdout = stdout:gsub("\n", "")
		if not stdout:match("default") then
			self.profile_image:set_image(stdout)
		end
	end)
end

-- ============================================================================
-- LOCKSCREEN CONTROLLER
-- ============================================================================
local LockscreenController = {}
LockscreenController.__index = LockscreenController

function LockscreenController:new()
	local self = setmetatable({}, LockscreenController)
	self.auth = AuthManager:new()
	self.ui_instances = {}
	self.is_locked = false

	self:_init_screens()
	self:_setup_signals()
	self:_setup_backgrounds()
	self:_set_locked_state(false)

	return self
end

function LockscreenController:_set_locked_state(locked)
	self.is_locked = locked and true or false
	awesome._lockscreen_is_locked = self.is_locked
end

function LockscreenController:_create_screen_ui(s)
	if self.ui_instances[s] then
		return
	end

	if s == screen.primary then
		self.ui_instances[s] = LockscreenUI:new(s)
		self.ui_instances[s]:update_user_info()
	else
		local extended = wibox({
			screen = s,
			visible = false,
			ontop = true,
			type = "splash",
			x = s.geometry.x,
			y = s.geometry.y,
			width = s.geometry.width,
			height = s.geometry.height,
			bg = beautiful.background,
		})

		self.ui_instances[s] = {
			lockscreen = extended,
			show = function()
				extended.visible = true
			end,
			hide = function()
				extended.visible = false
			end,
			reset = function() end,
		}
	end
end

function LockscreenController:_init_screens()
	for s in screen do
		self:_create_screen_ui(s)
	end
end

function LockscreenController:_setup_signals()
	awesome.connect_signal("screen::lockscreen:show", function()
		self:lock()
	end)
	awesome.connect_signal("screen::lockscreen:hide", function()
		self:unlock("signal")
	end)

	-- Cleanup on exit
	awesome.connect_signal("exit", function()
		self.auth:stop()
	end)

	-- Block notifications while locked
	naughty.connect_signal("request::display", function()
		if self.is_locked then
			naughty.destroy_all_notifications(nil, 1)
		end
	end)

	-- Handle screen changes
	screen.connect_signal("added", function(s)
		self:_create_screen_ui(s)
		self:_apply_background(s)
		if self.is_locked and self.ui_instances[s] then
			self.ui_instances[s]:show()
		end
	end)
	screen.connect_signal("removed", function(s)
		self.ui_instances[s] = nil
	end)
end

function LockscreenController:_setup_backgrounds()
	for s in screen do
		self:_apply_background(s)
	end
end

function LockscreenController:_apply_background(s)
	local index = s.index .. "-"
	local w = s.geometry.width
	local h = s.geometry.height
	local aspect = math.floor((w / h) * 100) / 100

	local blur = config.blur_background and "-filter Gaussian -blur 0x10" or ""

	-- Sanitize paths (basic protection)
	local safe_bg_image = config.bg_image:gsub("[^%w%.%-_]", "")

	local cmd = string.format(
		[[sh -c "mkdir -p '%s' && convert -quality 100 -brightness-contrast -20x0 %s '%s%s' \
            -gravity center -crop %s:1 +repage -resize %dx%d! '%s%s%s'"]],
		config.tmp_wall_dir,
		blur,
		config.bg_dir,
		safe_bg_image,
		aspect,
		w,
		h,
		config.tmp_wall_dir,
		index,
		safe_bg_image
	)

	awful.spawn.easy_async_with_shell(cmd, function()
		local ui = self.ui_instances[s]
		if ui and ui.lockscreen then
			ui.lockscreen.bgimage = config.tmp_wall_dir .. index .. safe_bg_image
		end
	end)
end

function LockscreenController:lock()
	if self.is_locked then
		return
	end

	self:_set_locked_state(true)
	sounds.play("lock")

	-- Close any open menus
	awful.spawn.with_shell("pkill rofi 2>/dev/null")

	-- Stop any active keygrabber
	local current_grabber = awful.keygrabber.current_instance
	if current_grabber then
		current_grabber:stop()
	end

	-- Show all lockscreens
	for _, ui in pairs(self.ui_instances) do
		ui:show()
	end

	-- Start authentication
	local primary_ui = self.ui_instances[screen.primary or screen[1]]

	gears.timer.start_new(0.1, function()
		self.auth:start(function(method)
			self:unlock(method)
		end, function(method)
			primary_ui:show_failure(method)
		end, primary_ui.password_display, primary_ui.capslock)
	end)
end

function LockscreenController:unlock(method)
	if not self.is_locked then
		return
	end

	-- Ensure all auth input handlers (including keygrabber) are released.
	self.auth:stop()

	-- Show success animation
	local primary_ui = self.ui_instances[screen.primary or screen[1]]
	primary_ui:show_success()
	sounds.play("unlock")

	-- Unlock after brief delay
	gears.timer.start_new(0.5, function()
		-- Hide all lockscreens
		for _, ui in pairs(self.ui_instances) do
			ui:reset()
			ui:hide()
		end

		self:_set_locked_state(false)

		local c = awful.client.restore()
		if c then
			c:emit_signal("request::activate")
			c:raise()
		end
		return false
	end)
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================
return LockscreenController:new()
