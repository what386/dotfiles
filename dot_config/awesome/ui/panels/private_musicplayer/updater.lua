local awful = require("awful")
local gears = require("gears")
local naughty = require("naughty")
local playing_trackid = nil
local music_updater = {}
-- Store references to widgets that need updating
local widgets = {}
local show_timer = nil -- Add timer for delayed show signal
local follow_pid = nil
local restart_timer = nil
local progress_timer = nil
local current_length_seconds = 0
local current_position_seconds = 0
local is_playing = false

-- Helper function to format time from seconds
local function format_time(seconds)
	if not seconds or seconds == 0 then
		return "00:00"
	end
	local mins = math.floor(seconds / 60)
	local secs = seconds % 60
	return string.format("%d:%02d", mins, secs)
end

-- One-shot command to fetch current metadata
local cmd = [[playerctl metadata --format 'artUrl:{{mpris:artUrl}}	length:{{mpris:length}}	position:{{mpris:position}}	trackid:{{mpris:trackid}}	artist:{{xesam:artist}}	title:{{xesam:title}}	status:{{status}}']]
local follow_cmd = [[playerctl metadata --follow --format 'artUrl:{{mpris:artUrl}}	length:{{mpris:length}}	position:{{mpris:position}}	trackid:{{mpris:trackid}}	artist:{{xesam:artist}}	title:{{xesam:title}}	status:{{status}}']]

local function stop_progress_timer()
	if progress_timer then
		progress_timer:stop()
	end
end

local function ensure_progress_timer()
	if not progress_timer then
		progress_timer = gears.timer({
			timeout = 1,
			autostart = false,
			callback = function()
				if not widgets.position or not widgets.progress_bar or not is_playing then
					return
				end
				current_position_seconds = math.min(current_position_seconds + 1, current_length_seconds)
				widgets.position:set_text(format_time(current_position_seconds))
				if current_length_seconds > 0 then
					widgets.progress_bar.value = (current_position_seconds / current_length_seconds) * 100
				end
			end,
		})
	end
	if not progress_timer.started then
		progress_timer:start()
	end
end

local function parse_media_line(line)
	local media_data = {}
	for field in line:gmatch("[^\t]+") do
		local key, value = field:match("^([^:]+):(.*)$")
		if key and value and value ~= "" then
			media_data[key] = value:match("^%s*(.-)%s*$")
		end
	end
	return media_data
end

-- Helper function to create a unique track identifier
local function create_track_identifier(media_data)
	-- Use trackid if available, otherwise create one from title + artist
	if media_data.title and media_data.artist then
		return media_data.title .. "|" .. media_data.artist
	elseif media_data.title then
		return media_data.title
	else
		return nil
	end
end

-- Main update function
local function apply_media_info(media_data)
	-- Check if widgets are available
	if not widgets.title then
		return
	end

	-- Create a unique identifier for this track
	local current_track_id = create_track_identifier(media_data)
	local track_changed = current_track_id ~= playing_trackid

	-- Update title widget
	if media_data.title then
		widgets.title:set_text(media_data.title)
	end

	-- Update artist widget
	if media_data.artist then
		widgets.artist:set_text(media_data.artist)
	end

	-- Update length widget
	if media_data.length then
		current_length_seconds = math.floor(tonumber(media_data.length) / 1000000)
		widgets.length:set_text(format_time(current_length_seconds))
	else
		current_length_seconds = 0
		widgets.length:set_text("00:00")
	end

	-- Update position widget and progress bar
	if media_data.position then
		current_position_seconds = math.floor(tonumber(media_data.position) / 1000000)
		widgets.position:set_text(format_time(current_position_seconds))
		if current_length_seconds > 0 then
			widgets.progress_bar.value = (current_position_seconds / current_length_seconds) * 100
		end
	else
		current_position_seconds = 0
		widgets.position:set_text("00:00")
		widgets.progress_bar.value = 0
	end

	is_playing = media_data.status == "Playing"
	if is_playing and current_length_seconds > 0 then
		ensure_progress_timer()
	else
		stop_progress_timer()
	end

	-- Handle album art URL
	if media_data.artUrl and widgets.album_art then
		local image_path = media_data.artUrl:gsub("^file://", "")
		if gears.filesystem.file_readable(image_path) then
			widgets.album_art:set_image(image_path)
		end
	end

	-- Check if track has changed and emit signal with delay
	if track_changed and current_track_id then
		playing_trackid = current_track_id

		if show_timer then
			show_timer:stop()
		end

		show_timer = gears.timer({
			timeout = 0.1,
			single_shot = true,
			callback = function()
				awesome.emit_signal("panel::musicplayer:show")
			end,
		})
		show_timer:start()
	elseif not current_track_id and playing_trackid then
		playing_trackid = nil
		awesome.emit_signal("panel::musicplayer:hide")
	end
end

local function get_media_info()
	awful.spawn.easy_async_with_shell(cmd, function(stdout)
		local first_line = stdout:gsub("%s+$", "")
		if first_line == "" then
			return
		end
		apply_media_info(parse_media_line(first_line))
	end)
end

local function start_follow_subscription()
	if follow_pid then
		return
	end

	follow_pid = awful.spawn.with_line_callback(follow_cmd, {
		stdout = function(line)
			if line and line ~= "" then
				apply_media_info(parse_media_line(line))
			end
		end,
		exit = function()
			follow_pid = nil
			if restart_timer then
				restart_timer:stop()
			end
			restart_timer = gears.timer({
				timeout = 2,
				single_shot = true,
				callback = function()
					start_follow_subscription()
				end,
			})
			restart_timer:start()
		end,
	})
end

-- Register widget references for updating
function music_updater.register_widgets(widget_refs)
	widgets = widget_refs
	get_media_info()
	start_follow_subscription()
end

-- Manual update function (for signals)
function music_updater.update_now()
	get_media_info()
end

-- Stop the update timer (for cleanup)
function music_updater.stop_updates()
	if follow_pid then
		awful.spawn("kill " .. tostring(follow_pid))
		follow_pid = nil
	end
	if show_timer then
		show_timer:stop()
		show_timer = nil
	end
	if restart_timer then
		restart_timer:stop()
		restart_timer = nil
	end
	stop_progress_timer()
end

-- Get current media info without updating widgets (for external use)
function music_updater.get_current_media_info(callback)
	awful.spawn.easy_async_with_shell(cmd, function(stdout)
		local media_data = parse_media_line(stdout:gsub("%s+$", ""))

		-- Convert length and position to seconds
		if media_data.length then
			media_data.length_seconds = math.floor(tonumber(media_data.length) / 1000000)
		end
		if media_data.position then
			media_data.position_seconds = math.floor(tonumber(media_data.position) / 1000000)
		end

		callback(media_data)
	end)
end

-- Connect to awesome signals
awesome.connect_signal("music", function()
	music_updater.update_now()
end)

return music_updater
