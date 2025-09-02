local awful = require("awful")
local ruled = require("ruled")
local beautiful = require("beautiful")
local gears = require("gears")
local dpi = beautiful.xresources.apply_dpi
local rubato = require("dependencies.rubato")

local app = require("config.user.preferences").default.quake -- e.g. "kitty --name QuakeTerminal"
local quake_instance_name = "QuakeTerminal"
local previous_client = nil
local quake_client = nil
local margins = dpi(2.5)
local lr_margins = dpi(300)

-- Function to get current screen dimensions and calculate positioning
local function get_screen_geometry()
	local focused_screen = awful.screen.focused() or screen.primary or screen[1]
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
	geom = geom or get_screen_geometry()
	if not geom then
		return false
	end

	if c.screen ~= geom.screen then
		c:move_to_screen(geom.screen)
	end

	c:geometry({
		x = geom.panel_x,
		y = geom.workarea.y - geom.panel_height - margins,
		width = geom.panel_width,
		height = geom.panel_height,
	})
	return true
end

-- Rubato animation object (created lazily when terminal spawns)
local quake_y_anim = nil

-- Animate quake terminal using rubato
local function animate_quake_terminal(show)
	if not quake_client or not quake_client.valid then
		return
	end
	local geom = get_screen_geometry()
	if not geom then
		return
	end

	-- Update width/screen without touching y
	if quake_client.screen ~= geom.screen then
		quake_client:move_to_screen(geom.screen)
		quake_client:geometry({
			x = geom.panel_x,
			width = geom.panel_width,
			height = geom.panel_height,
		})
	end

	-- Animation target positions
	local target_y_show = geom.workarea.y + margins
	local target_y_hide = geom.workarea.y - geom.panel_height - margins - dpi(36)

	-- Create rubato animator if not already
	if not quake_y_anim then
		quake_y_anim = rubato.timed({
			intro = 0.15, -- acceleration time
			outro = 0.15,
			duration = 0.3,
			easing = rubato.quadratic,
			subscribed = function(pos)
				if quake_client and quake_client.valid then
					local g = quake_client:geometry()
					g.y = pos
					quake_client:geometry(g)
				end
			end,
		})
	end

	-- Focus handling
	if show then
		previous_client = client.focus
		quake_client.hidden = false
		quake_client:emit_signal("request::activate", "quake_toggle", { raise = true })
	else
		if previous_client and previous_client.valid then
			client.focus = previous_client
		end
	end

	quake_client.hidden = false
	quake_client:raise()

	-- Set rubato target
	quake_y_anim.target = show and target_y_show or target_y_hide

	-- When animation finishes hiding, mark hidden
	if not show then
		gears.timer({
			timeout = quake_y_anim.duration + quake_y_anim.intro,
			autostart = true,
			single_shot = true,
			callback = function()
				if quake_client and quake_client.valid then
					quake_client.hidden = true
				end
			end,
		})
	end
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
		local success = update_quake_geometry(c)
		if success then
			c.hidden = true
		else
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
		quake_y_anim = nil
	end
end)
