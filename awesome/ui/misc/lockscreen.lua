local wibox = require("wibox")
local gears = require("gears")
local awful = require("awful")
local naughty = require("naughty")
local beautiful = require("beautiful")
local config_dir = gears.filesystem.get_configuration_dir()
local dpi = beautiful.xresources.apply_dpi
local apps = require("config.user.preferences")
local widget_icon_dir = config_dir .. "configuration/user-profile/"

-- Add paths to package.cpath
package.cpath = package.cpath .. ";" .. config_dir .. "/library/?.so;" .. "/usr/lib/lua-pam/?.so;"

-- this file is terrible. For hours, I kept running into unexplainable problems,
-- so i fed my code through Claude to refactor and ChatGPT to fix Claude's code.
-- I have no idea how this file works.
--
-- Abandon all hope, ye who enter here.

-- ============================================================================
-- CONFIGURATION
-- ============================================================================
local config = {
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
	self.callbacks = {}
	self:_init_pam()
	return self
end

function AuthManager:_init_pam()
	self.authenticate_password = function(password)
		return password == config.fallback_password
	end

	if config.using_pam then
		local success, pam = pcall(require, "liblua_pam")
		if success then
			self.authenticate_password = function(password)
				return pam.auth_current_user(password)
			end
		else
			naughty.notification({
				app_name = "Security",
				title = "WARNING",
				message = "PAM library not available! Using fallback password authentication.",
				urgency = "critical",
			})
		end
	end
end

function AuthManager:start_authentication(callbacks)
	if self.is_authenticating then
		return false
	end

	self.is_authenticating = true
	self.callbacks = callbacks or {}

	-- Start both authentication methods
	self:_start_password_auth()
	if config.enable_fingerprint then
		self:_start_fingerprint_auth()
	end

	return true
end

function AuthManager:stop_authentication()
	self.is_authenticating = false

	-- Stop password grabber
	if self.password_grabber then
		self.password_grabber:stop()
		self.password_grabber = nil
	end

	-- Stop fingerprint
	self:_stop_fingerprint_auth()

	-- Clear callbacks
	self.callbacks = {}
end

function AuthManager:_start_password_auth()
	local input_password = nil

	self.password_grabber = awful.keygrabber({
		auto_start = true,
		stop_event = "release",
		mask_event_callback = true,
		keybindings = {
			awful.key({
				modifiers = { "Control" },
				key = "u",
				on_press = function()
					input_password = nil
					if self.callbacks.on_password_change then
						self.callbacks.on_password_change("")
					end
				end,
			}),
		},

		keypressed_callback = function(grabber, mod, key, command)
			if not self.is_authenticating then
				return
			end

			if key == "BackSpace" then
				if input_password and #input_password > 0 then
					input_password = input_password:sub(1, -2)
					if #input_password == 0 then
						input_password = nil
					end
					if self.callbacks.on_password_change then
						self.callbacks.on_password_change(input_password or "")
					end
				end
			elseif key == "Escape" then
				input_password = nil
				if self.callbacks.on_password_change then
					self.callbacks.on_password_change("")
				end
				self:stop_authentication()
				if self.callbacks.on_cancel then
					self.callbacks.on_cancel()
				end
			elseif #key == 1 then
				input_password = (input_password or "") .. key
				if self.callbacks.on_password_change then
					self.callbacks.on_password_change(input_password)
				end
			end
		end,

		keyreleased_callback = function(grabber, mod, key, command)
			if key == "Caps_Lock" and self.callbacks.on_capslock_change then
				self.callbacks.on_capslock_change()
			end

			if not self.is_authenticating then
				return
			end

			if key == "Return" then
				local password = input_password
				input_password = nil

				if self.callbacks.on_password_change then
					self.callbacks.on_password_change("")
				end

				if password and self.authenticate_password(password) then
					self:_on_auth_success("password")
				else
					self:_on_auth_failure("password")
					-- Re-enable typing after failure
					input_password = nil
				end
			end
		end,
	})

	self.password_grabber:start()
end

function AuthManager:_start_fingerprint_auth()
	if not config.enable_fingerprint or self.fingerprint_active then
		return
	end

	self.fingerprint_active = true

	-- Start fingerprint daemon
	--awful.spawn.easy_async_with_shell("pgrep -x open-fprintd >/dev/null || (open-fprintd &)", function()
	--gears.timer.start_new(0.5, function()
	if not self.fingerprint_active or not self.is_authenticating then
		return
	end

	awful.spawn.easy_async_with_shell("fprintd-verify 2>&1", function(stdout, stderr, reason, code)
		if not self.fingerprint_active or not self.is_authenticating then
			return
		end

		self.fingerprint_active = false

		local success = code == 0
			or stdout:match("verify%-match")
			or stdout:match("Match!")
			or stdout:lower():match("success")

		if success then
			self:_on_auth_success("fingerprint")
		else
			self:_on_auth_failure("fingerprint")
			-- Retry fingerprint after failure
			if self.is_authenticating then
				gears.timer.start_new(1, function()
					if self.is_authenticating then
						self:_start_fingerprint_auth()
					end
				end)
			end
		end
	end)
	--end)
	--end)
end

function AuthManager:_stop_fingerprint_auth()
	self.fingerprint_active = false
	awful.spawn.with_shell("pkill -f 'fprintd-verify' 2>/dev/null")
	awful.spawn.with_shell("pkill -f 'open-fprintd' 2>/dev/null")
end

function AuthManager:_on_auth_success(method)
	if not self.is_authenticating then
		return
	end
	-- capture before stop_authentication() clears callbacks
	local on_success = self.callbacks and self.callbacks.on_success

	self:stop_authentication() -- this clears self.callbacks

	if on_success then
		on_success(method)
	end
end

function AuthManager:_on_auth_failure(method)
	if not self.is_authenticating then
		return
	end
	-- Defensive: capture before anything else could clear callbacks later
	local on_failure = self.callbacks and self.callbacks.on_failure

	-- Don't stop authentication on failure - allow retries
	if on_failure then
		on_failure(method)
	end
end

-- ============================================================================
-- LOCKSCREEN UI MANAGER
-- ============================================================================
local LockscreenUI = {}
LockscreenUI.__index = LockscreenUI

function LockscreenUI:new(screen)
	local self = setmetatable({}, LockscreenUI)
	self.screen = screen
	self.widgets = {}
	self:_create_widgets()
	self:_create_lockscreen()
	return self
end

function LockscreenUI:_create_widgets()
	-- Username text
	self.widgets.username = wibox.widget({
		markup = "$USER",
		font = "Inter Bold 12",
		align = "center",
		valign = "center",
		widget = wibox.widget.textbox,
	})

	-- Caps lock indicator
	self.widgets.capslock = wibox.widget({
		markup = "Caps Lock is on",
		font = "Inter Italic 10",
		align = "center",
		valign = "center",
		opacity = 0.0,
		widget = wibox.widget.textbox,
	})

	-- Fingerprint status
	self.widgets.fingerprint_status = wibox.widget({
		markup = '<span color="#ffffff" font="Inter 10">Touch sensor or enter password</span>',
		align = "center",
		valign = "center",
		opacity = 0.8,
		widget = wibox.widget.textbox,
	})

	-- Profile image
	self.widgets.profile_image = wibox.widget({
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
	self.widgets.clock = wibox.widget.textclock(clock_format, 1)

	-- Date
	self.widgets.date = wibox.widget({
		markup = self:_get_date_string(),
		font = "Inter Bold 20",
		align = "center",
		valign = "center",
		widget = wibox.widget.textbox,
	})

	-- Password display
	self.widgets.password_display = wibox.widget({
		markup = "",
		font = "Inter Bold 16",
		align = "center",
		valign = "center",
		widget = wibox.widget.textbox,
	})

	-- Password container
	self.widgets.password_container = wibox.widget({
		{
			self.widgets.password_display,
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

function LockscreenUI:_get_date_string()
	local date = os.date("%d")
	local day = os.date("%A")
	local month = os.date("%B")

	-- Remove leading zero
	date = date:gsub("^0", "")

	-- Determine ordinal suffix
	local last_digit = date:sub(-1)
	local ordinal = "th"
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
					self.widgets.clock,
					self.widgets.date,
				},
			},
			{
				layout = wibox.layout.fixed.vertical,
				spacing = dpi(15),
				{
					layout = wibox.layout.fixed.vertical,
					spacing = dpi(15),
					self.widgets.profile_image,
					self.widgets.username,
				},
				{
					layout = wibox.layout.fixed.vertical,
					spacing = dpi(5),
					self.widgets.password_container,
					self.widgets.fingerprint_status,
				},
				self.widgets.capslock,
			},
			nil,
		},
		nil,
	})
end

function LockscreenUI:update_password_display(password)
	local stars = password and string.rep("*", #password) or ""
	self.widgets.password_display:set_markup(stars)
end

function LockscreenUI:update_capslock_status()
	awful.spawn.easy_async_with_shell("xset q | grep Caps | cut -d: -f3 | cut -d0 -f1 | tr -d ' '", function(stdout)
		self.widgets.capslock.opacity = stdout:match("on") and 1.0 or 0.0
		self.widgets.capslock:emit_signal("widget::redraw_needed")
	end)
end

function LockscreenUI:update_username()
	awful.spawn.easy_async_with_shell(
		[[
		sh -c '
		fullname="$(getent passwd `whoami` | cut -d ':' -f 5 | cut -d ',' -f 1 | tr -d "\n")"
		if [ -z "$fullname" ]; then
			printf "$(whoami)@$(hostname)"
		else
			printf "$fullname"
		fi'
		]],
		function(stdout)
			self.widgets.username:set_markup(stdout:gsub("%\n", ""))
		end
	)
end

function LockscreenUI:update_profile_image()
	awful.spawn.easy_async_with_shell(apps.utils.update_profile, function(stdout)
		stdout = stdout:gsub("%\n", "")
		if not stdout:match("default") then
			self.widgets.profile_image:set_image(stdout)
		else
			self.widgets.profile_image:set_image(widget_icon_dir .. "default.svg")
		end
	end)
end

function LockscreenUI:show_auth_failure(method)
	local red = beautiful.system_red_dark or "#bf616a"
	self.widgets.password_container.border_color = red
	self.widgets.password_container:emit_signal("widget::redraw_needed")

	if method == "fingerprint" and config.show_fingerprint_feedback then
		self.widgets.fingerprint_status:set_markup(
			'<span color="#bf616a" font="Inter 10">Fingerprint failed - try password</span>'
		)
	end

	gears.timer.start_new(1, function()
		self.widgets.password_container.border_color = "#00000045"
		self.widgets.password_container:emit_signal("widget::redraw_needed")

		if method == "fingerprint" then
			self.widgets.fingerprint_status:set_markup(
				'<span color="#ffffff" font="Inter 10">Touch sensor or enter password</span>'
			)
		end
	end)
end

function LockscreenUI:show_auth_success()
	local green = beautiful.system_green_dark or "#a3be8c"
	self.widgets.password_container.border_color = green
	self.widgets.password_container:emit_signal("widget::redraw_needed")
end

function LockscreenUI:show()
	self.lockscreen.visible = true
	self.widgets.clock:emit_signal("widget::redraw_needed")
	self:update_capslock_status()
end

function LockscreenUI:hide()
	self.lockscreen.visible = false
end

function LockscreenUI:reset()
	-- reset border
	self.widgets.password_container.border_color = "#00000045"
	self.widgets.password_container:emit_signal("widget::redraw_needed")

	-- clear password display
	self.widgets.password_display:set_markup("")

	-- reset fingerprint prompt
	self.widgets.fingerprint_status:set_markup(
		'<span color="#ffffff" font="Inter 10">Touch sensor or enter password</span>'
	)
end

-- ============================================================================
-- LOCKSCREEN CONTROLLER
-- ============================================================================
local LockscreenController = {}
LockscreenController.__index = LockscreenController

function LockscreenController:new()
	local self = setmetatable({}, LockscreenController)
	self.auth_manager = AuthManager:new()
	self.ui_instances = {}
	self.is_locked = false
	self.locked_tag = nil
	self:_init_screens()
	self:_setup_signals()
	self:_setup_background()
	return self
end

function LockscreenController:_init_screens()
	for s in screen do
		if s.index == 1 then
			self.ui_instances[s] = LockscreenUI:new(s)
			self.ui_instances[s]:update_username()
			gears.timer.start_new(2, function()
				self.ui_instances[s]:update_profile_image()
			end)
		else
			-- Create simple extended lockscreen for additional monitors
			local extended = wibox({
				screen = s,
				visible = false,
				ontop = true,
				x = s.geometry.x,
				y = s.geometry.y,
				width = s.geometry.width,
				height = s.geometry.height,
				bg = beautiful.background,
				fg = beautiful.fg_normal,
			})
			self.ui_instances[s] = {
				lockscreen = extended,
				show = function()
					extended.visible = true
				end,
				hide = function()
					extended.visible = false
				end,
			}
		end
	end
end

function LockscreenController:_setup_signals()
	awesome.connect_signal("screen::lockscreen:show", function()
		if not self.is_locked then
			self:lock()
		end
	end)

	-- Recreate screens on changes
	screen.connect_signal("request::desktop_decoration", function(s)
		if s.index == 1 then
			self.ui_instances[s] = LockscreenUI:new(s)
			self.ui_instances[s]:update_username()
			self.ui_instances[s]:update_profile_image()
		else
			local extended = wibox({
				screen = s,
				visible = false,
				ontop = true,
				x = s.geometry.x,
				y = s.geometry.y,
				width = s.geometry.width,
				height = s.geometry.height,
				bg = beautiful.background,
				fg = beautiful.fg_normal,
			})
			self.ui_instances[s] = {
				lockscreen = extended,
				show = function()
					extended.visible = true
				end,
				hide = function()
					extended.visible = false
				end,
			}
		end
		self:_apply_background_to_screen(s)
	end)

	-- Block notifications while locked
	naughty.connect_signal("request::display", function()
		if self.is_locked then
			naughty.destroy_all_notifications(nil, 1)
		end
	end)
end

function LockscreenController:_free_keygrab()
	-- Kill rofi
	awful.spawn.with_shell("kill -9 $(pgrep rofi)")

	-- Stop current keygrabber
	local keygrabbing = awful.keygrabber.current_instance
	if keygrabbing then
		keygrabbing:stop()
	end

	-- Minimize focused client and unselect tags
	if client.focus then
		client.focus.minimized = true
	end

	for _, t in ipairs(mouse.screen.selected_tags) do
		self.locked_tag = t
		t.selected = false
	end
end

function LockscreenController:lock()
	if self.is_locked then
		return
	end

	self.is_locked = true
	self:_free_keygrab()

	-- Show all lockscreens
	for _, ui in pairs(self.ui_instances) do
		ui:show()
	end

	-- Get primary UI for callbacks
	local primary_ui = self.ui_instances[screen.primary or screen[1]]

	-- Weak self reference for callbacks
	local controller = self

	-- Start authentication after delay
	gears.timer.start_new(1, function()
		self.auth_manager:start_authentication({
			on_password_change = function(password)
				if primary_ui.update_password_display then
					primary_ui:update_password_display(password)
				end
			end,
			on_capslock_change = function()
				if primary_ui.update_capslock_status then
					primary_ui:update_capslock_status()
				end
			end,
			on_success = function(method)
				controller:unlock(method)
			end,
			on_failure = function(method)
				if primary_ui.show_auth_failure then
					primary_ui:show_auth_failure(method)
				end
			end,
			on_cancel = function()
				-- User cancelled, unlock without authentication for testing
				-- Remove this in production
				controller.is_locked = false
			end,
		})
	end)
end

function LockscreenController:unlock(method)
	-- Show success animation on primary screen
	local primary_ui = self.ui_instances[screen.primary or screen[1]]
	if primary_ui.show_auth_success then
		primary_ui:show_auth_success()
	end

	-- Unlock after animation
	gears.timer.start_new(0.5, function()
		-- Hide all lockscreens
		for _, ui in pairs(self.ui_instances) do
			if ui.reset then
				ui:reset()
			end

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

function LockscreenController:_setup_background()
	for s in screen do
		self:_apply_background_to_screen(s)
	end
end

function LockscreenController:_apply_background_to_screen(s)
	local index = s.index .. "-"
	local width = s.geometry.width
	local height = s.geometry.height
	local aspect_ratio = math.floor((width / height) * 100) / 100

	local blur_param = config.blur_background and "-filter Gaussian -blur 0x10" or ""

	local cmd = string.format(
		[[
		sh -c "
		if [ ! -d %s ]; then
			mkdir -p %s;
		fi
		convert -quality 100 -brightness-contrast -20x0 %s %s%s \
			-gravity center -crop %s:1 +repage -resize %dx%d! \
			%s%s%s
		"
	]],
		config.tmp_wall_dir,
		config.tmp_wall_dir,
		blur_param,
		config.bg_dir,
		config.bg_image,
		aspect_ratio,
		width,
		height,
		config.tmp_wall_dir,
		index,
		config.bg_image
	)

	awful.spawn.easy_async_with_shell(cmd, function()
		local ui = self.ui_instances[s]
		if ui and ui.lockscreen then
			ui.lockscreen.bgimage = config.tmp_wall_dir .. index .. config.bg_image
		end
	end)
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================
local lockscreen_controller = LockscreenController:new()

return lockscreen_controller
