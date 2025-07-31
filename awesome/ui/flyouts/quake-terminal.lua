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

local screen_width = awful.screen.focused().geometry.width
local screen_height = awful.screen.focused().geometry.height
local margins = dpi(2.5)
local lr_margins = dpi(300)

local panel_width = screen_width - lr_margins * 2
local panel_height = screen_height / 3
local panel_x = lr_margins

-- Quake properties
local quake_properties = function()
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
		width = panel_width,
		--maximized_horizontal = false,
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

local function animate_quake_terminal(show)
	if not quake_client or not quake_client.valid then
		return
	end

	local screen_geom = quake_client.screen.workarea
	local target_y = show and screen_geom.y + margins or screen_geom.y - screen_height
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

	--ignore check nil errors
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
awesome.connect_signal("module::quake_terminal:toggle", function()
	quake_toggle()
end)

-- When client is managed, capture it if it's the quake terminal
client.connect_signal("manage", function(c)
	if c.instance == quake_instance_name then
		quake_client = c

		-- Initial geometry
		local screen_geom = c.screen.workarea

		c:geometry({
			x = panel_x,
			y = screen_geom.y - panel_height - margins,
			width = panel_width,
			height = panel_height,
		})

		c.hidden = true
	end
end)

-- Clean up when the terminal is closed
client.connect_signal("unmanage", function(c)
	if c == quake_client then
		quake_client = nil
	end
end)
