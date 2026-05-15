local gears = require("gears")
local process = require("utilities.process")

local media = {}

local metadata_cmd = [[playerctl metadata --format 'artUrl:{{mpris:artUrl}}	length:{{mpris:length}}	position:{{mpris:position}}	trackid:{{mpris:trackid}}	artist:{{xesam:artist}}	title:{{xesam:title}}	status:{{status}}']]
local follow_cmd = [[playerctl metadata --follow --format 'artUrl:{{mpris:artUrl}}	length:{{mpris:length}}	position:{{mpris:position}}	trackid:{{mpris:trackid}}	artist:{{xesam:artist}}	title:{{xesam:title}}	status:{{status}}']]

local state = {
	title = nil,
	artist = nil,
	artUrl = nil,
	trackid = nil,
	status = "Stopped",
	length = 0,
	position = 0,
	shuffle = false,
	playing = false,
}

local follow_pid = nil
local restart_timer = nil
local progress_timer = nil
local last_track_identifier = nil
local show_timer = nil

local function parse_bool(value)
	value = tostring(value or ""):lower()
	return value == "true" or value == "on" or value == "1"
end

local function parse_line(line)
	local data = {}
	line = tostring(line or ""):gsub("\\t", "\t")
	for field in line:gmatch("[^\t]+") do
		local key, value = field:match("^([^:]+):(.*)$")
		if key and value and value ~= "" then
			data[key] = value:match("^%s*(.-)%s*$")
		end
	end
	return data
end

local function track_identifier(data)
	if data.trackid and data.trackid ~= "" then return data.trackid end
	if data.title and data.artist then return data.title .. "|" .. data.artist end
	return data.title
end

local function snapshot()
	local copy = {}
	for key, value in pairs(state) do copy[key] = value end
	return copy
end

local function emit_state()
	awesome.emit_signal("media::state", snapshot())
end

local function stop_progress_timer()
	if progress_timer then progress_timer:stop() end
end

local function ensure_progress_timer()
	if not progress_timer then
		progress_timer = gears.timer({
			timeout = 1,
			autostart = false,
			callback = function()
				if not state.playing then return end
				state.position = math.min((state.position or 0) + 1, state.length or 0)
				awesome.emit_signal("media::progress", state.position, state.length)
				emit_state()
			end,
		})
	end
	if not progress_timer.started then progress_timer:start() end
end

function media.apply(data)
	data = data or {}
	state.title = data.title or state.title
	state.artist = data.artist or state.artist
	state.artUrl = data.artUrl or state.artUrl
	state.trackid = data.trackid or state.trackid
	state.status = data.status or state.status
	state.length = data.length and math.floor((tonumber(data.length) or 0) / 1000000) or state.length or 0
	state.position = data.position and math.floor((tonumber(data.position) or 0) / 1000000) or state.position or 0
	state.shuffle = data.shuffle ~= nil and parse_bool(data.shuffle) or state.shuffle
	state.playing = state.status == "Playing"

	local id = track_identifier(data)
	if id and id ~= last_track_identifier then
		last_track_identifier = id
		awesome.emit_signal("media::track-changed", snapshot())
		if show_timer then show_timer:stop() end
		show_timer = gears.timer({ timeout = 0.1, single_shot = true, callback = function() awesome.emit_signal("panel::musicplayer:show") end })
		show_timer:start()
	elseif not id and last_track_identifier then
		last_track_identifier = nil
		awesome.emit_signal("panel::musicplayer:hide")
	end

	if state.playing and (state.length or 0) > 0 then ensure_progress_timer() else stop_progress_timer() end
	emit_state()
end

function media.refresh(callback)
	process.run_shell(metadata_cmd, function(stdout)
		local line = tostring(stdout or ""):gsub("%s+$", "")
		if line ~= "" then media.apply(parse_line(line)) end
		if callback then callback(snapshot()) end
	end)
end

function media.start()
	media.refresh()
	if follow_pid then return end
	follow_pid = process.watch(follow_cmd, {
		stdout = function(line)
			if line and line ~= "" then media.apply(parse_line(line)) end
		end,
		exit = function()
			follow_pid = nil
			if restart_timer then restart_timer:stop() end
			restart_timer = gears.timer({ timeout = 2, single_shot = true, callback = media.start })
			restart_timer:start()
		end,
	})
end

function media.get_state() return snapshot() end
function media.play() process.spawn("playerctl play"); media.refresh() end
function media.pause() process.spawn("playerctl pause"); media.refresh() end
function media.play_pause() process.spawn("playerctl play-pause"); media.refresh() end
function media.next() process.spawn("playerctl next"); media.refresh() end
function media.previous() process.spawn("playerctl previous"); media.refresh() end
function media.set_shuffle(enabled) process.spawn_shell("playerctl shuffle " .. (enabled and "On" or "Off")); state.shuffle = enabled and true or false; emit_state() end
function media.toggle_shuffle() media.set_shuffle(not state.shuffle) end
function media.status_text(callback) process.run_shell("mpc status", function(stdout) callback(tostring(stdout or ""):gsub("\n$", "")) end) end

awesome.connect_signal("music", media.refresh)

return media
