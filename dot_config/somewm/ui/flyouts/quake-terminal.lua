local awful = require("awful")
local ruled = require("ruled")
local beautiful = require("beautiful")
local gears = require("gears")
local dpi = beautiful.xresources.apply_dpi
local rubato = require("dependencies.rubato")
local app = require("config.preferences.apps").quake
local quake_app_id = "org.somewm.QuakeTerminal"
local config_dir = gears.filesystem.get_configuration_dir()
local quake_pid_path = config_dir .. "persistent/quake-terminal.pid"
local previous_client = nil
local quake_client = nil
local quake_pid = nil
local margins = dpi(2.5)
local lr_margins = dpi(600)
local opened = false
local hide_timer = nil

local function read_quake_pid()
	local file = io.open(quake_pid_path, "r")
	if not file then
		return nil
	end
	local pid = tonumber(file:read("*a"))
	file:close()
	if pid and pid > 0 and pid == math.floor(pid) then
		return pid
	end
	return nil
end

local function write_quake_pid(pid)
	local temp_path = quake_pid_path .. ".tmp"
	local file = io.open(temp_path, "w")
	if not file then
		return false
	end
	file:write(tostring(pid), "\n")
	file:close()
	return os.rename(temp_path, quake_pid_path)
end

local function clear_quake_pid()
	os.remove(quake_pid_path)
	quake_pid = nil
end

local function quake_process_is_running(pid)
	if not pid then
		return false
	end
	local file = io.open("/proc/" .. tostring(pid) .. "/cmdline", "r")
	if not file then
		return false
	end
	local command_line = file:read("*a")
	file:close()
	return command_line:find("ghostty", 1, true) ~= nil
		and command_line:find("--class=" .. quake_app_id, 1, true) ~= nil
end

local function spawn_quake_terminal()
	local pid = awful.spawn(app)
	if pid and pid > 0 then
		quake_pid = pid
		write_quake_pid(pid)
	end
	return pid
end

local function ensure_quake_terminal()
	if quake_client and quake_client.valid then
		return
	end
	if quake_process_is_running(quake_pid) then
		return
	end
	clear_quake_pid()
	spawn_quake_terminal()
end

-- SomeWM's Lua hidden setter unbans the scene without clearing the xdg
-- suspended state. Retagging this sticky client invokes native arrangement,
-- which reconciles suspension too
local function set_hidden(c, hidden)
	c.hidden = hidden
	local tags = c:tags()
	if #tags == 0 and c.screen.selected_tag then
		tags = { c.screen.selected_tag }
	end
	c:tags({})
	c:tags(tags)
end

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
	local panel_width =
		math.max(1, math.min(screen_width - margins * 2, math.max(dpi(640), screen_width - lr_margins * 2)))
	local panel_height = math.max(1, math.min(dpi(600), screen_height - margins * 2))
	local panel_x = screen_geom.x + (screen_width - panel_width) / 2
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
		opacity = 0, -- Start with opacity 0 for fade-in effect
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
		rule = { class = quake_app_id }, -- Ghostty's Wayland app ID maps to class.
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

-- Rubato animation objects (created lazily when terminal spawns)
local quake_y_anim = nil
local quake_opacity_anim = nil

-- Animate quake terminal using rubato
local function animate_quake_terminal(show)
	if not quake_client or not quake_client.valid then
		return
	end
	local geom = get_screen_geometry()
	if not geom then
		return
	end
	opened = show
	if hide_timer then
		hide_timer:stop()
		hide_timer = nil
	end

	-- Update width/screen without touching y
	if quake_client.screen ~= geom.screen then
		quake_client:move_to_screen(geom.screen)
	end
	quake_client:geometry({
		x = geom.panel_x,
		width = geom.panel_width,
		height = geom.panel_height,
	})

	-- Animation target positions
	local target_y_show = geom.workarea.y + margins
	local target_y_hide = geom.workarea.y - (dpi(48) + margins)

	-- Opacity targets
	local target_opacity_show = 1
	local target_opacity_hide = 0

	-- Create rubato animators if not already created
	if not quake_y_anim then
		quake_y_anim = rubato.timed({
			rate = 144,
			intro = 0.06,
			outro = 0.06,
			duration = 0.32,
			easing = rubato.easing.quadratic,
			subscribed = function(pos)
				if quake_client and quake_client.valid then
					quake_client:geometry({ y = pos })
				end
			end,
		})
	end

	if not quake_opacity_anim then
		quake_opacity_anim = rubato.timed({
			rate = 60, -- half the rate of position animation
			intro = 0.04,
			outro = 0.04,
			duration = 0.16,
			easing = rubato.easing.zero,
			subscribed = function(opacity)
				if quake_client and quake_client.valid then
					quake_client.opacity = opacity
				end
			end,
		})
	end

	-- Focus handling and initial setup
	if show then
		if client.focus ~= quake_client then
			previous_client = client.focus
		end
		set_hidden(quake_client, false)
		quake_client:emit_signal("request::activate", "quake_toggle", { raise = true })
		client.focus = quake_client
		-- Start fade in slightly before the slide animation
		quake_opacity_anim.target = target_opacity_show
	else
		if previous_client and previous_client.valid then
			client.focus = previous_client
		end
		-- Start fade out immediately
		quake_opacity_anim.target = target_opacity_hide
	end

	quake_client.hidden = false
	quake_client:raise()

	-- Set rubato target for position animation
	quake_y_anim.target = show and target_y_show or target_y_hide

	-- When animation finishes hiding, mark hidden
	if not show then
		local hiding_client = quake_client
		hide_timer = gears.timer({
			timeout = math.max(
				quake_y_anim.duration + quake_y_anim.intro,
				quake_opacity_anim.duration + quake_opacity_anim.intro
			),
			autostart = true,
			single_shot = true,
			callback = function()
				hide_timer = nil
				if not opened and quake_client == hiding_client and hiding_client.valid then
					set_hidden(hiding_client, true)
				end
			end,
		})
	end
end

-- Toggle quake terminal
local function quake_toggle()
	if not quake_client or not quake_client.valid then
		ensure_quake_terminal()
	else
		animate_quake_terminal(not opened)
	end
end

-- Listen for toggle signal
awesome.connect_signal("flyout::quake_terminal:toggle", function()
	quake_toggle()
end)

-- When client is managed, capture it if it's the quake terminal
client.connect_signal("request::manage", function(c)
	local is_tracked_process = quake_pid and tonumber(c.pid) == quake_pid
	local is_quake_app = c.class == quake_app_id
	if is_tracked_process or is_quake_app then
		quake_client = c
		quake_pid = tonumber(c.pid) or quake_pid
		if quake_pid then
			write_quake_pid(quake_pid)
		end
		local success = update_quake_geometry(c)
		if success then
			c.hidden = true
			c.opacity = 0 -- Ensure it starts invisible
		else
			gears.timer.delayed_call(function()
				update_quake_geometry(c)
				c.hidden = true
				c.opacity = 0
			end)
		end
	end
end)

-- Clean up when the terminal is closed
client.connect_signal("request::unmanage", function(c)
	if c == quake_client then
		opened = false
		if hide_timer then
			hide_timer:stop()
			hide_timer = nil
		end
		quake_client = nil
		quake_y_anim = nil
		quake_opacity_anim = nil
		clear_quake_pid()
	end
end)

-- Reattach after a config reload before considering a new spawn. Match the
-- persisted PID first; the app ID adopts a quake window if no PID was saved.
quake_pid = read_quake_pid()
if not quake_process_is_running(quake_pid) then
	clear_quake_pid()
else
	for _, c in ipairs(client.get()) do
		if c.valid and tonumber(c.pid) == quake_pid then
			quake_client = c
			opened = not c.hidden
			update_quake_geometry(c)
			break
		end
	end
end

if not quake_client then
	for _, c in ipairs(client.get()) do
		if c.valid and c.class == quake_app_id then
			quake_client = c
			quake_pid = tonumber(c.pid)
			if quake_pid then
				write_quake_pid(quake_pid)
			end
			opened = not c.hidden
			update_quake_geometry(c)
			break
		end
	end
end

if not quake_client then
	ensure_quake_terminal()
end
