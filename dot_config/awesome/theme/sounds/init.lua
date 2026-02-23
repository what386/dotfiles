local awful = require("awful")
local gfs = require("gears.filesystem")

local config_dir = gfs.get_configuration_dir()
local sounds_dir = config_dir .. "theme/sounds/"

local events = {
	login = "login.oga",
	logout = "logout.ogg",
	lock = "switch.oga",
	unlock = "switch.oga",
	notification = "notification.oga",
	notification_critical = "notification-critical.oga",
}

local cooldown_seconds = {
	login = 2.0,
	logout = 1.0,
	lock = 0.6,
	unlock = 0.6,
	notification = 0.15,
	notification_critical = 0.3,
}

local last_played = {}

local function shell_quote(text)
	return "'" .. tostring(text):gsub("'", [['"'"']]) .. "'"
end

local function now_seconds()
	return os.clock()
end

local function should_skip(event)
	local cooldown = cooldown_seconds[event] or 0
	if cooldown <= 0 then
		return false
	end

	local now = now_seconds()
	local last = last_played[event] or 0
	if (now - last) < cooldown then
		return true
	end

	last_played[event] = now
	return false
end

local function build_play_command(sound_path)
	local q = shell_quote(sound_path)
	return string.format(
		[[sh -c 'if command -v pw-play >/dev/null 2>&1; then pw-play %s; elif command -v paplay >/dev/null 2>&1; then paplay %s; elif command -v canberra-gtk-play >/dev/null 2>&1; then canberra-gtk-play -f %s; fi']],
		q,
		q,
		q
	)
end

local sounds = {}

function sounds.path(event)
	local file = events[event]
	if not file then
		return nil
	end

	local path = sounds_dir .. file
	if not gfs.file_readable(path) then
		return nil
	end

	return path
end

function sounds.play(event)
	if not event or should_skip(event) then
		return false
	end

	local sound_path = sounds.path(event)
	if not sound_path then
		return false
	end

	awful.spawn.with_shell(build_play_command(sound_path))
	return true
end

awesome.connect_signal("theme::sound:play", function(event)
	sounds.play(event)
end)

return sounds
