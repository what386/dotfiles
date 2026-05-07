local gears = require("gears")
local media = require("services.media")

local music_updater = {}
local widgets = {}

local function format_time(seconds)
	seconds = tonumber(seconds) or 0
	local mins = math.floor(seconds / 60)
	local secs = seconds % 60
	return string.format("%d:%02d", mins, secs)
end

local function apply_state(state)
	if not widgets.title then return end
	if state.title then widgets.title:set_text(state.title) end
	if state.artist then widgets.artist:set_text(state.artist) end
	widgets.length:set_text(format_time(state.length))
	widgets.position:set_text(format_time(state.position))
	if (state.length or 0) > 0 then widgets.progress_bar.value = ((state.position or 0) / state.length) * 100 else widgets.progress_bar.value = 0 end
	if state.artUrl and widgets.album_art then
		local image_path = state.artUrl:gsub("^file://", "")
		if gears.filesystem.file_readable(image_path) then widgets.album_art:set_image(image_path) end
	end
end

function music_updater.register_widgets(widget_refs)
	widgets = widget_refs
	apply_state(media.get_state())
	media.refresh()
end

function music_updater.update_now() media.refresh() end
function music_updater.stop_updates() end
function music_updater.get_current_media_info(callback) callback(media.get_state()) end

awesome.connect_signal("media::state", apply_state)
awesome.connect_signal("media::progress", function(position, length)
	if not widgets.position or not widgets.progress_bar then return end
	widgets.position:set_text(format_time(position))
	if (length or 0) > 0 then widgets.progress_bar.value = ((position or 0) / length) * 100 end
end)
awesome.connect_signal("music", media.refresh)

return music_updater
