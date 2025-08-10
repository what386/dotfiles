local awful = require("awful")
local ruled = require("ruled")
local beautiful = require("beautiful")
local gears = require("gears")
local dpi = beautiful.xresources.apply_dpi
local app = require("config.user.preferences").default.quake -- e.g. "kitty --name QuakeTerminal"
local quake_instance_name = "QuakeTerminal"
local previous_client = nil
local quake_client = nil
local anim_timer = nil
local anim_fps = 60
local anim_duration = 0.20
local steps = anim_duration * anim_fps
local margins = dpi(2.5)
local lr_margins = dpi(300)

-- Function to get current screen dimensions and calculate positioning
local function get_screen_geometry()
	local focused_screen = awful.screen.focused()

	-- Fallback to primary screen if focused screen is nil
	if not focused_screen then
		focused_screen = screen.primary
	end

	-- If still nil, try the first available screen
	if not focused_screen and screen.count() > 0 then
		focused_screen = screen[1]
	end

	-- If we still don't have a screen, return nil
	if not focused_screen then
		return nil
	end

	local screen_geom = focused_screen.workarea
	if not screen_geom then
		return nil
	end

	local screen_width = screen_geom.width
	local screen_height = screen_geom.height
	local panel_width = screen_width - lr_margins * 2
	local panel_height = dpi(500)
	local panel_x = screen_geom.x + lr_margins

	return {
		screen = focused_screen,
		workarea = screen_geom,
		panel_width = panel_width,
		panel_height = panel_height,
		panel_x = panel_x,
		screen_height = screen_height,
	}
end

-- Quake properties
local function quake_properties()
	return {
		skip_decoration = true,
		titlebars_enabled = false,
		switch_to_tags = false,
		opacity = 0.40,
		floating = true,
		skip_taskbar = true,
		ontop = true,
		above = true,
		sticky = true,
		hidden = true,
		skip_center = true,
		round_corners = false,
		placement = awful.placement.top,
		shape = beautiful.client_shape_rectangle,
	}
end

-- Rule for quake terminal
ruled.client.connect_signal("request::rules", function()
	ruled.client.append_rule({
		id = "quake_terminal",
		rule_any = {
			instance = { quake_instance_name },
		},
		properties = quake_properties(),
	})
end)

-- Function to update quake terminal geometry for current screen
local function update_quake_geometry(c, geom)
	if not c or not c.valid then
		return false
	end

	-- Get geometry if not provided
	if not geom then
		geom = get_screen_geometry()
	end

	-- Return early if we can't get screen geometry
	if not geom then
		return false
	end

	local focused_screen = geom.screen

	-- Move client to focused screen if it's on a different screen
	if c.screen ~= focused_screen then
		c:move_to_screen(focused_screen)
	end

	-- Update geometry for the current screen
	c:geometry({
		x = geom.panel_x,
		y = geom.workarea.y - geom.panel_height - margins,
		width = geom.panel_width,
		height = geom.panel_height,
	})

	return true
end

local function animate_quake_terminal(show)
	if not quake_client or not quake_client.valid then
		return
	end

	local geom = get_screen_geometry()

	-- Return early if we can't get screen geometry
	if not geom then
		return
	end

	-- Only update screen/width if we're on a different screen
	-- Don't update Y position as that will interfere with animation
	if quake_client.screen ~= geom.screen then
		quake_client:move_to_screen(geom.screen)
		quake_client:geometry({
			x = geom.panel_x,
			width = geom.panel_width,
			height = geom.panel_height,
		})
	end

	-- Calculate animation positions
	local target_y = show and geom.workarea.y + margins or geom.workarea.y - geom.panel_height - margins - dpi(36)
	local start_y = quake_client.y
	local dy = (target_y - start_y) / steps
	local step = 0

	-- Focus handling
	if show then
		previous_client = client.focus
		quake_client.hidden = false
		quake_client:emit_signal("request::activate", "quake_toggle", { raise = true })
	else
		-- Restore focus to previously focused client if it's still valid
		if previous_client and previous_client.valid then
			client.focus = previous_client
		end
	end

	quake_client.hidden = false
	quake_client:raise()

	if anim_timer and anim_timer.started then
		anim_timer:stop()
	end

	anim_timer = gears.timer({
		timeout = 1 / anim_fps,
		autostart = true,
		call_now = true,
		callback = function()
			if not quake_client or not quake_client.valid then
				anim_timer:stop()
				return
			end

			if step >= steps then
				quake_client.y = target_y
				if not show then
					quake_client.hidden = true
				end
				anim_timer:stop()
				return
			end

			local new_y = math.floor(start_y + dy * step)
			quake_client:geometry({
				y = new_y,
			})
			step = step + 1
		end,
	})
end

-- Toggle quake terminal
local function quake_toggle()
	if not quake_client or not quake_client.valid then
		awful.spawn(app)
	else
		local is_hidden = quake_client.hidden
		animate_quake_terminal(is_hidden)
	end
end

-- Listen for toggle signal
awesome.connect_signal("flyout::quake_terminal:toggle", function()
	quake_toggle()
end)

-- When client is managed, capture it if it's the quake terminal
client.connect_signal("manage", function(c)
	if c.instance == quake_instance_name then
		quake_client = c
		-- Set initial geometry on the focused screen
		local success = update_quake_geometry(c)
		if success then
			c.hidden = true
		else
			-- If we can't get geometry, delay the setup
			gears.timer.delayed_call(function()
				update_quake_geometry(c)
				c.hidden = true
			end)
		end
	end
end)

-- Clean up when the terminal is closed
client.connect_signal("unmanage", function(c)
	if c == quake_client then
		quake_client = nil
	end
end)
