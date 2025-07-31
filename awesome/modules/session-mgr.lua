local awful = require("awful")
local gears = require("gears")
local naughty = require("naughty")
local json = require("dependencies.json")

local session_file = gears.filesystem.get_configuration_dir() .. "persistent/session.json"
local command_file = gears.filesystem.get_configuration_dir() .. "persistent/command_table.json"

-- Table to store pending applications to restore
local pending_restore = {}

local function read_command_table()
	local f = io.open(command_file, "r")
	if not f then
		naughty.notify({ title = "No command file found", text = command_file })
		return
	end
	local content = f:read("*a")
	f:close()
	local commands = json.parse(content)
	if not commands then
		naughty.notify({ title = "Error", text = "Failed to parse command file." })
		return
	end
	return commands
end

local command_table = read_command_table()

local function get_command_from_pid(pid)
	if not pid then
		return nil
	end
	local f = io.open("/proc/" .. pid .. "/cmdline", "r")
	if not f then
		return nil
	end
	local cmd = f:read("*a")
	f:close()
	-- Replace null bytes (used as argument separators) with spaces
	return cmd and cmd:gsub("%z", " ")
end

local function resolve_command(c)
	if command_table[c.class] then
		return command_table[c.class]
	else
		local cmd = get_command_from_pid(c.pid)
		if not cmd or not c.class then
			return nil
		end
		command_table[c.class] = cmd

		return cmd
	end
end

local function save()
	local session = {}
	for _, c in ipairs(client.get()) do
		if c.class and not c.skip_taskbar and c.name ~= "awesome" and c.type ~= "dialog" then
			local cmd = resolve_command(c)
			table.insert(session, {
				class = c.class,
				instance = c.instance,
				name = c.name,
				tag = c.first_tag and c.first_tag.name,
				screen = c.screen.index,
				floating = c.floating,
				geometry = c:geometry(),
				command = cmd,
			})
		end
	end

	local f, err
	f, err = io.open(session_file, "w")
	if f then
		f:write(json.stringify(session))
		f:close()
	else
		naughty.notify({ title = "Error saving session table", text = err or "Could not open file." })
	end
	f, err = io.open(command_file, "w")
	if f then
		f:write(json.stringify(command_table))
		f:close()
	else
		naughty.notify({ title = "Error saving command table", text = err or "Could not open file." })
	end
	naughty.notify({ title = "Session saved", text = session_file .. "\n" .. command_file })
end

-- Function to find a matching app in pending_restore for a client
local function find_matching_app(c)
	for i, app in ipairs(pending_restore) do
		-- Try to match by class first
		if app.class and c.class and app.class == c.class then
			-- Remove from pending list and return the app data
			table.remove(pending_restore, i)
			return app
		end
		-- Fallback: try to match by instance if class doesn't match
		if app.instance and c.instance and app.instance == c.instance then
			table.remove(pending_restore, i)
			return app
		end
	end
	return nil
end

-- Function to apply saved data to a client
local function apply_saved_data(c, app_data)
	-- Apply tag
	if app_data.tag then
		local target_screen = screen[app_data.screen] or screen.primary
		local tag = nil
		for _, t in ipairs(target_screen.tags) do
			if t.name == app_data.tag then
				tag = t
				break
			end
		end
		if tag then
			c:move_to_tag(tag)
		end
	end

	-- Apply screen
	if app_data.screen then
		local target_screen = screen[app_data.screen] or screen.primary
		c:move_to_screen(target_screen)
	end

	-- Apply floating state
	if app_data.floating ~= nil then
		c.floating = app_data.floating
	end

	-- Apply geometry (with a small delay to ensure the client is ready)
	if app_data.geometry then
		gears.timer.delayed_call(function()
			if c.valid then
				c:geometry(app_data.geometry)
			end
		end)
	end
end

-- Signal handler for new clients during restore
local function handle_new_client_during_restore(c)
	local app_data = find_matching_app(c)
	if app_data then
		apply_saved_data(c, app_data)
	end
end

local function restore()
	local f = io.open(session_file, "r")
	if not f then
		naughty.notify({ title = "No session file found", text = session_file })
		return
	end
	local content = f:read("*a")
	f:close()
	local session = json.parse(content)
	if not session then
		naughty.notify({ title = "Error", text = "Failed to parse session file." })
		return
	end

	-- Clear any previous pending restore data
	pending_restore = {}

	-- Connect signal to handle new clients during restore
	client.connect_signal("manage", handle_new_client_during_restore)

	-- Populate pending_restore with session data
	for _, app in ipairs(session) do
		table.insert(pending_restore, app)
	end

	-- Spawn all applications
	for _, app in ipairs(session) do
		local cmd = app.command
		if cmd then
			awful.spawn.with_shell(cmd)
		else
			naughty.notify({
				title = "Missing command",
				text = "Could not find command for class: " .. (app.class or "unknown"),
				preset = naughty.config.presets.critical,
			})
		end
	end

	-- Set up a timer to disconnect the signal after a reasonable time
	-- This prevents the signal from interfering with normal client management
	gears.timer.start_new(30, function()
		client.disconnect_signal("manage", handle_new_client_during_restore)
		-- Clear any remaining pending restore data
		pending_restore = {}
		return false -- Don't repeat the timer
	end)

	naughty.notify({ title = "Session restored", text = session_file })
end

local modkey = "Mod4"

local existing_keys = root.keys()

local keys = gears.table.join(
	awful.key({ modkey, "Shift" }, "r", function()
		awesome.emit_signal("module::session_manager:restore")
	end, { description = "restore session", group = "awesome" }),

	awful.key({ modkey, "Shift" }, "s", function()
		awesome.emit_signal("module::session_manager:save")
	end, { description = "save session", group = "awesome" })
)

root.keys(gears.table.join(existing_keys, keys))

awesome.connect_signal("module::session_manager:save", function()
	save()
end)

awesome.connect_signal("module::session_manager:restore", function()
	restore()
end)
