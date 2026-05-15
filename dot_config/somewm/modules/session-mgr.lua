local awful = require("awful")
local gears = require("gears")
local naughty = require("naughty")
local json = require("libraries.json")
local settings = require("utilities.settings")

local config_dir   = gears.filesystem.get_configuration_dir()
local session_file = config_dir .. "persistent/session.json"
local command_file = config_dir .. "persistent/command_table.json"

local autorestore_allowed = settings.get_bool("autorestore_allowed", true)
local restore_in_progress = false
local pending_restore = {}

-- ── Command table ─────────────────────────────────────────────────────────────

local function read_command_table()
	local f = io.open(command_file, "r")
	if not f then return {} end
	local content = f:read("*a")
	f:close()
	return json.parse(content) or {}
end

local command_table = read_command_table()

-- Returns a stable identifier for a client, preferring app_id (Wayland native)
-- then class (XWayland), then instance.
local function client_id(c)
	return c.app_id or c.class or c.instance
end

local function get_command_from_pid(pid)
	if not pid then return nil end
	local f = io.open("/proc/" .. pid .. "/cmdline", "r")
	if not f then return nil end
	local raw = f:read("*a")
	f:close()
	if not raw or raw == "" then return nil end
	-- /proc/PID/cmdline uses NUL as arg separator; convert to a shell command
	local args = {}
	for arg in (raw .. "\0"):gmatch("([^%z]*)%z") do
		if arg ~= "" then
			-- Shell-quote each argument
			table.insert(args, "'" .. arg:gsub("'", "'\\''") .. "'")
		end
	end
	return #args > 0 and table.concat(args, " ") or nil
end

local function resolve_command(c)
	local id = client_id(c)
	if not id then return nil end
	if command_table[id] then return command_table[id] end
	local cmd = get_command_from_pid(c.pid)
	if cmd then
		command_table[id] = cmd
	end
	return cmd
end

-- ── Save ──────────────────────────────────────────────────────────────────────

local function save()
	local session = {}
	for _, c in ipairs(client.get()) do
		local id = client_id(c)
		if id and not c.skip_taskbar and c.type ~= "dialog" then
			local cmd = resolve_command(c)
			table.insert(session, {
				id       = id,                              -- app_id or class
				class    = c.class,
				instance = c.instance,
				app_id   = c.app_id,
				name     = c.name,
				tag      = c.first_tag and c.first_tag.name,
				screen   = c.screen.index,
				floating = c.floating,
				geometry = c:geometry(),
				command  = cmd,
			})
		end
	end

	local function write(path, data, label)
		local f, err = io.open(path, "w")
		if f then
			f:write(json.stringify(data))
			f:close()
		else
			naughty.notify({ title = "Error saving " .. label, text = err or "Could not open file." })
		end
	end

	write(session_file, session,       "session table")
	write(command_file, command_table, "command table")
	naughty.notify({ title = "Session saved", text = session_file })
end

-- ── Restore ───────────────────────────────────────────────────────────────────

local function find_matching_app(c)
	local id = client_id(c)
	for i, app in ipairs(pending_restore) do
		-- Match by the unified id field first, then fall back to individual fields
		if (id and app.id and app.id == id)
			or (c.class    and app.class    and c.class    == app.class)
			or (c.app_id   and app.app_id   and c.app_id   == app.app_id)
			or (c.instance and app.instance and c.instance == app.instance)
		then
			table.remove(pending_restore, i)
			return app
		end
	end
	return nil
end

local function apply_saved_data(c, app)
	-- Tag
	if app.tag then
		local target = screen[app.screen] or screen.primary
		for _, t in ipairs(target.tags) do
			if t.name == app.tag then
				c:move_to_tag(t)
				break
			end
		end
	end

	-- Screen
	if app.screen then
		c:move_to_screen(screen[app.screen] or screen.primary)
	end

	-- Floating
	if app.floating ~= nil then
		c.floating = app.floating
	end

	-- Geometry — delayed to give the client time to map itself.
	-- Under XWayland this is best-effort; native Wayland clients may ignore it.
	if app.geometry then
		gears.timer.start_new(0.5, function()
			if c.valid then
				c:geometry(app.geometry)
			end
			return false
		end)
	end
end

local function handle_new_client(c)
	local app = find_matching_app(c)
	if app then apply_saved_data(c, app) end
end

local function restore()
	if restore_in_progress then
		naughty.notify({ title = "Restore already in progress", text = "Please wait." })
		return
	end
	restore_in_progress = true

	local f = io.open(session_file, "r")
	if not f then
		naughty.notify({ title = "No session file found", text = session_file })
		restore_in_progress = false
		return
	end
	local content = f:read("*a")
	f:close()

	local session = json.parse(content)
	if not session then
		naughty.notify({ title = "Error", text = "Failed to parse session file." })
		restore_in_progress = false
		return
	end

	pending_restore = {}
	client.connect_signal("request::manage", handle_new_client)

	for _, app in ipairs(session) do
		table.insert(pending_restore, app)
	end

	for _, app in ipairs(session) do
		if app.command then
			-- Ensure Wayland env vars are present when re-launching
			awful.spawn.with_shell(app.command)
		else
			naughty.notify({
				title = "Missing command",
				text  = "No command for: " .. (app.id or app.class or "unknown"),
			})
		end
	end

	-- Disconnect the signal after 30 s regardless of how many apps were matched
	gears.timer.start_new(30, function()
		client.disconnect_signal("request::manage", handle_new_client)
		pending_restore      = {}
		restore_in_progress  = false
		return false
	end)

	naughty.notify({ title = "Session restored", text = session_file })
end

-- ── Keybindings ───────────────────────────────────────────────────────────────

local modkey = "Mod4"
local keys = {
	awful.key({ modkey, "Shift" }, "r", restore, { description = "restore session", group = "awesome" }),
	awful.key({ modkey, "Shift" }, "s", save,    { description = "save session",    group = "awesome" }),
}
local merged = {}
for _, k in ipairs(root.keys()) do merged[#merged + 1] = k end
for _, k in ipairs(keys)        do merged[#merged + 1] = k end
root.keys(merged)

-- ── Auto-restore on startup ───────────────────────────────────────────────────

if awesome.startup and autorestore_allowed then
	gears.timer.start_new(1, function()
		restore()
		return false
	end)
end

-- ── Signals ───────────────────────────────────────────────────────────────────

awesome.connect_signal("module::session_manager:save",    function() if autorestore_allowed then save()    end end)
awesome.connect_signal("module::session_manager:restore", function() if autorestore_allowed then restore() end end)
awesome.connect_signal("module::session_manager:autosave_enable",  function()
	autorestore_allowed = true
	settings.set_bool("autorestore_allowed", true)
end)
awesome.connect_signal("module::session_manager:autosave_disable", function()
	autorestore_allowed = false
	settings.set_bool("autorestore_allowed", false)
end)
