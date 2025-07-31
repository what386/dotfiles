local awful = require("awful")
local gears = require("gears")

local terminal_classes = {
	"Alacritty",
	"kitty",
	"XTerm",
	"URxvt",
	"Terminator",
	"Gnome-terminal",
	"St",
}

-- dont swallow these apps because weird things happen
local blacklist = {
	"firefox",
	"chromium",
	"steam",
	"discord",
}

local swallowed_windows = {}

local function is_terminal(c)
	if not c.class then
		return false
	end

	for _, term_class in ipairs(terminal_classes) do
		if c.class:lower():find(term_class:lower()) then
			return true
		end
	end
	return false
end

local function is_blacklisted(c)
	if not c.class then
		return false
	end

	for _, blacklisted in ipairs(blacklist) do
		if c.class:lower():find(blacklisted:lower()) then
			return true
		end
	end
	return false
end

local function get_parent_pid(c)
	if not c.pid then
		return nil
	end

	-- read the parent PID from /proc/PID/stat
	local stat_file = io.open("/proc/" .. c.pid .. "/stat", "r")
	if not stat_file then
		return nil
	end

	local stat_line = stat_file:read("*line")
	stat_file:close()

	if not stat_line then
		return nil
	end

	-- parent PID is the 4th field in /proc/PID/stat
	-- hopefully this never changes because that would be bad
	local fields = {}
	for field in stat_line:gmatch("%S+") do
		table.insert(fields, field)
	end

	return tonumber(fields[4])
end

-- Get client by PID
local function get_client_by_pid(pid)
	for _, c in ipairs(client.get()) do
		if c.pid == pid then
			return c
		end
	end
	return nil
end

-- check if client is a GUI application using basic GUI heuristics
local function is_gui_application(c)
	return c.width and c.height and c.width > 50 and c.height > 50 and c.class and c.class ~= ""
end

local function swallow_terminal(terminal_client, gui_client)
	swallowed_windows[gui_client] = {
		terminal = terminal_client,
		original_geometry = {
			x = terminal_client.x,
			y = terminal_client.y,
			width = terminal_client.width,
			height = terminal_client.height,
		},
		original_tag = terminal_client.first_tag,
		original_screen = terminal_client.screen,
	}

	gui_client:geometry({
		x = terminal_client.x,
		y = terminal_client.y,
		width = terminal_client.width,
		height = terminal_client.height,
	})

	if terminal_client.first_tag then
		gui_client:move_to_tag(terminal_client.first_tag)
	end
	gui_client:move_to_screen(terminal_client.screen)

	terminal_client.hidden = true
	terminal_client:lower()

	-- Focus the GUI application
	gui_client:raise()
	client.focus = gui_client
end

local function restore_terminal(gui_client)
	local swallow_data = swallowed_windows[gui_client]
	if not swallow_data then
		return
	end

	local terminal_client = swallow_data.terminal

	if terminal_client and terminal_client.valid then
		-- restore terminal visibility and position
		terminal_client.hidden = false
		terminal_client:geometry(swallow_data.original_geometry)
		terminal_client:raise()
		client.focus = terminal_client
	end

	swallowed_windows[gui_client] = nil
end

local function handle_new_client(c)
	-- wait for client to be fully initialized
	gears.timer.delayed_call(function()
		if not c.valid then
			return
		end

		if not is_gui_application(c) or is_blacklisted(c) then
			return
		end

		local parent_pid = get_parent_pid(c)
		if not parent_pid then
			return
		end

		-- Find parent client (potential terminal)
		local parent_client = get_client_by_pid(parent_pid)
		if not parent_client then
			return
		end

		-- Check if parent is a terminal
		if is_terminal(parent_client) then
			swallow_terminal(parent_client, c)
		end
	end)
end

-- handle client removal (restore terminal)
local function handle_client_unmanage(c)
	if swallowed_windows[c] then
		restore_terminal(c)
	end
end

client.connect_signal("manage", handle_new_client)
client.connect_signal("unmanage", handle_client_unmanage)

-- also handle clients that are killed/closed
client.connect_signal("request::kill", handle_client_unmanage)

-- manual window swallowing function
-- shouldnt be needed, but its here
-- just in case of weird behavior

--local function toggle_swallow(c)
--	c = c or client.focus
--	if not c then
--		return
--	end
--
--	if swallowed_windows[c] then
--		restore_terminal(c)
--	else
--		-- Try to find a terminal to swallow
--		local parent_pid = get_parent_pid(c)
--		if parent_pid then
--			local parent_client = get_client_by_pid(parent_pid)
--			if parent_client and is_terminal(parent_client) then
--				swallow_terminal(parent_client, c)
--			end
--		end
--	end
--end
