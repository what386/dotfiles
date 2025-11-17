local wibox = require("wibox")
local gears = require("gears")
local awful = require("awful")
local naughty = require("naughty")
local beautiful = require("beautiful")
local config_dir = gears.filesystem.get_configuration_dir()
local dpi = beautiful.xresources.apply_dpi
local apps = require("config.user.preferences")
local widget_icon_dir = config_dir .. "configuration/user-profile/"

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
		auto_start = true,
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

	-- Start fingerprint verification
	self.fingerprint_pid = awful.spawn.with_line_callback("fprintd-verify 2>&1", function(stdout, _, _, code)
		-- Check if we're still authenticating
		if not self.fingerprint_active or not self.is_authenticating then
			return
		end

		self.fingerprint_active = false

		-- Check for success
		local success = code == 0
			or stdout:match("verify%-match")
			or stdout:match("Match!")
			or stdout:lower():match("success")

		if success then
			self:_handle_success("fingerprint")
		else
			self:_handle_failure("fingerprint")
			-- Retry fingerprint
			if self.is_authenticating then
				gears.timer.start_new(1, function()
					if self.is_authenticating then
						self:_start_fingerprint()
					end
				end)
			end
		end
	end)
end

function AuthManager:_stop_fingerprint()
	self.fingerprint_active = false

	if self.fingerprint_pid then
		-- pid found, kill by that
		awful.spawn.with_shell("kill -9 " .. tostring(self.fingerprint_pid))
	else
		-- Fallback to prevent zombie fprintd process
		awful.spawn.with_shell("pkill -n fprintd-verify")
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
	-- Username
	self.username = wibox.widget({
		markup = "$USER",
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
		image = widget_icon_dir .. "default.svg",
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
		forced_width = 100,
		forced_height = 36,
		shape = gears.shape.rounded_rect,
		border_width = dpi(2),
		border_color = "#00000045",
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
					self.clock,
					self.date,
				},
			},
			{
				layout = wibox.layout.fixed.vertical,
				spacing = dpi(15),
				{
					layout = wibox.layout.fixed.vertical,
					spacing = dpi(15),
					self.profile_image,
					self.username,
				},
				{
					layout = wibox.layout.fixed.vertical,
					spacing = dpi(5),
					self.password_container,
					self.status,
				},
				self.capslock,
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
		self.password_container.border_color = "#00000045"
		self.password_container:emit_signal("widget::redraw_needed")
		self.status:set_markup('<span color="#ffffff" font="Inter 10">Touch sensor or enter password</span>')
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
	self.password_container.border_color = "#00000045"
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
	self.locked_tag = nil

	self:_init_screens()
	self:_setup_signals()
	self:_setup_backgrounds()

	return self
end

function LockscreenController:_init_screens()
	for s in screen do
		if s.index == 1 then
			-- Primary screen with full UI
			self.ui_instances[s] = LockscreenUI:new(s)
			self.ui_instances[s]:update_user_info()
		else
			-- Secondary screens with simple blank screen
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
end

function LockscreenController:_setup_signals()
	awesome.connect_signal("screen::lockscreen:show", function()
		self:lock()
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
	screen.connect_signal("request::desktop_decoration", function(s)
		self:_init_screens()
		self:_apply_background(s)
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

	self.is_locked = true

	-- Close any open menus
	awful.spawn.with_shell("pkill rofi 2>/dev/null")

	-- Stop any active keygrabber
	local current_grabber = awful.keygrabber.current_instance
	if current_grabber then
		current_grabber:stop()
	end

	-- Minimize focused client and unselect tags
	if client.focus then
		client.focus.minimized = true
	end

	for _, t in ipairs(mouse.screen.selected_tags) do
		self.locked_tag = t
		t.selected = false
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

	-- Show success animation
	local primary_ui = self.ui_instances[screen.primary or screen[1]]
	primary_ui:show_success()

	-- Unlock after brief delay
	gears.timer.start_new(0.5, function()
		-- Hide all lockscreens
		for _, ui in pairs(self.ui_instances) do
			ui:reset()
			ui:hide()
		end

		self.is_locked = false

		-- Restore tag and client
		if self.locked_tag then
			self.locked_tag.selected = true
			self.locked_tag = nil
		end

		local c = awful.client.restore()
		if c then
			c:emit_signal("request::activate")
			c:raise()
		end
	end)
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================
return LockscreenController:new()
