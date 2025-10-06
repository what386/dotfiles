local awful = require("awful")
local gears = require("gears")
local naughty = require("naughty")
local playing_trackid = nil
local music_updater = {}
-- Store references to widgets that need updating
local widgets = {}
local update_timer = nil
local show_timer = nil -- Add timer for delayed show signal

-- Helper function to format time from seconds
local function format_time(seconds)
	if not seconds or seconds == 0 then
		return "00:00"
	end
	local mins = math.floor(seconds / 60)
	local secs = seconds % 60
	return string.format("%d:%02d", mins, secs)
end

-- Playerctl command to get media metadata
local cmd = [[playerctl metadata --format '
artUrl:{{ mpris:artUrl }}
length:{{ mpris:length }}
position:{{ mpris:position }}
trackid:{{ mpris:trackid }}
artist:{{ xesam:artist }}
title:{{ xesam:title }}']]

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
local function get_media_info()
	-- Check if widgets are available
	if not widgets.title then
		return
	end

	awful.spawn.easy_async_with_shell(cmd, function(stdout)
		local media_data = {}

		-- Parse the playerctl output
		for line in stdout:gmatch("[^\n]+") do
			local key, value = line:match("^([^:]+):(.*)$")
			if key and value and value ~= "" then
				-- Trim whitespace from value
				media_data[key] = value:match("^%s*(.-)%s*$")
			end
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
			local length_num = math.floor(tonumber(media_data.length) / 1000000)
			widgets.length:set_text(format_time(length_num))
		else
			widgets.length:set_text("00:00")
		end

		-- Update position widget and progress bar
		if media_data.position then
			local position_num = math.floor(tonumber(media_data.position) / 1000000)
			widgets.position:set_text(format_time(position_num))

			-- Update progress bar if we have both position and length
			if media_data.length then
				local length_num = math.floor(tonumber(media_data.length) / 1000000)
				if length_num > 0 then
					local progress = (position_num / length_num) * 100
					widgets.progress_bar.value = progress
				end
			end
		else
			widgets.position:set_text("00:00")
			widgets.progress_bar.value = 0
		end

		-- Handle album art URL
		if media_data.artUrl and widgets.album_art then
			-- Remove 'file://' prefix if present
			local image_path = media_data.artUrl:gsub("^file://", "")
			-- Check if file exists before setting it
			if gears.filesystem.file_readable(image_path) then
				widgets.album_art:set_image(image_path)
			end
		end

		-- Check if track has changed and emit signal with delay
		if track_changed and current_track_id then
			playing_trackid = current_track_id

			-- Cancel any existing show timer
			if show_timer then
				show_timer:stop()
			end

			-- Delay the show signal to allow all widgets to update
			show_timer = gears.timer({
				timeout = 0.1, -- Small delay (100ms)
				single_shot = true,
				callback = function()
					awesome.emit_signal("panel::musicplayer:show")
				end,
			})
			show_timer:start()
		elseif not current_track_id and playing_trackid then
			-- Music stopped playing
			playing_trackid = nil
			awesome.emit_signal("panel::musicplayer:hide")
		end
	end)
end

-- Register widget references for updating
function music_updater.register_widgets(widget_refs)
	widgets = widget_refs
	-- Start the update timer once widgets are registered
	if update_timer then
		update_timer:stop()
	end
	update_timer = gears.timer({
		timeout = 2,
		call_now = true,
		autostart = true,
		callback = get_media_info,
	})
end

-- Manual update function (for signals)
function music_updater.update_now()
	get_media_info()
end

-- Stop the update timer (for cleanup)
function music_updater.stop_updates()
	if update_timer then
		update_timer:stop()
		update_timer = nil
	end
	if show_timer then
		show_timer:stop()
		show_timer = nil
	end
end

-- Get current media info without updating widgets (for external use)
function music_updater.get_current_media_info(callback)
	awful.spawn.easy_async_with_shell(cmd, function(stdout)
		local media_data = {}
		for line in stdout:gmatch("[^\n]+") do
			local key, value = line:match("^([^:]+):(.*)$")
			if key and value and value ~= "" then
				media_data[key] = value:match("^%s*(.-)%s*$")
			end
		end

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
