local awful = require("awful")
local gears = require("gears")
local icons = require("theme.icons")

local audio = {}

local state = {
	available = false,
	last_error = nil,
	output_volume = 0,
	output_muted = false,
	input_volume = 0,
	input_muted = false,
	default_sink = nil,
	default_source = nil,
	devices = {
		sinks = {},
		sources = {},
	},
}

local started = false
local subscriber_pid = nil
local refreshing_state = false
local refreshing_devices = false

local function trim(value)
	return tostring(value or ""):match("^%s*(.-)%s*$")
end

local function shell_quote(value)
	return "'" .. tostring(value):gsub("'", "'\\''") .. "'"
end

local function emit_error(message)
	state.available = false
	state.last_error = message
	awesome.emit_signal("audio::error", message)
end

local function shallow_copy(source)
	local copy = {}
	for k, v in pairs(source) do copy[k] = v end
	return copy
end

local function state_snapshot()
	local snapshot = shallow_copy(state)
	snapshot.devices = { sinks = state.devices.sinks, sources = state.devices.sources }
	return snapshot
end

local function get_output_icon()
	local sink = tostring(state.default_sink or ""):lower()
	local headphones = sink:find("headphone") or sink:find("headset")
	if headphones then
		return state.output_muted and icons.widgets.volume.headphones_muted or icons.widgets.volume.headphones
	end
	if state.output_muted then
		return icons.widgets.volume.volume_muted
	elseif state.output_volume >= 75 then
		return icons.widgets.volume.volume_high
	elseif state.output_volume >= 50 then
		return icons.widgets.volume.volume_medium
	elseif state.output_volume >= 25 then
		return icons.widgets.volume.volume_low
	else
		return icons.widgets.volume.volume_off
	end
end

local function get_input_icon()
	if state.input_muted then
		return icons.widgets.microphone.mic_muted
	elseif state.input_volume >= 75 then
		return icons.widgets.microphone.mic_high
	elseif state.input_volume >= 50 then
		return icons.widgets.microphone.mic_medium
	else
		return icons.widgets.microphone.mic_low
	end
end

local function emit_state()
	local snapshot = state_snapshot()
	awesome.emit_signal("audio::state", snapshot)
	awesome.emit_signal("audio::output-volume", state.output_volume, state.output_muted)
	awesome.emit_signal("audio::input-volume", state.input_volume, state.input_muted)
	awesome.emit_signal("audio::output-mute", state.output_muted)
	awesome.emit_signal("audio::input-mute", state.input_muted)
	awesome.emit_signal("audio::default-device", "sink", state.default_sink)
	awesome.emit_signal("audio::default-device", "source", state.default_source)
	awesome.emit_signal("widget::volume:icon", get_output_icon())
	awesome.emit_signal("widget::microphone:icon", get_input_icon())
	-- Compatibility signals
	awesome.emit_signal("volume::update", state.output_volume)
	awesome.emit_signal("widget::microphone:update", state.input_volume)
end

local function emit_devices()
	awesome.emit_signal("audio::devices", state.devices)
end

-- Parse "Volume: 75% [MUTED]" from wpctl get-volume output
local function parse_wpctl_volume(output)
	local vol = tonumber(output:match("Volume:%s*([%d%.]+)"))
	local muted = output:find("%[MUTED%]") ~= nil
	local percent = vol and math.floor(vol * 100 + 0.5) or 0
	return percent, muted
end

-- Parse wpctl status for device list and defaults
-- wpctl status output has sections like:
--  Audio
--   ├─ Sinks:
--   │   51. Device Name          [vol: 0.75]
--   │ * 52. Default Device       [vol: 1.00]
local function parse_wpctl_status(stdout)
	local sinks, sources = {}, {}
	local default_sink, default_source = nil, nil
	local section = nil

	for line in stdout:gmatch("[^\r\n]+") do
		if line:match("Sinks:") then
			section = "sink"
		elseif line:match("Sources:") then
			section = "source"
		elseif line:match("Sink endpoints:") or line:match("Source endpoints:") or line:match("Filters:") or line:match("Streams:") then
			section = nil
		elseif section then
			-- Lines look like: "   *  52. Device Name   [vol: 1.00]"
			-- or:              "      51. Device Name   [vol: 0.75]"
			local is_default = line:match("%*") ~= nil
			local id, name = line:match("%s*%*?%s*(%d+)%.%s+(.-)%s+%[")
			if not id then
				id, name = line:match("%s*%*?%s*(%d+)%.%s+(.-)%s*$")
			end
			if id and name and trim(name) ~= "" then
				local entry = { id = id, name = trim(name), description = trim(name) }
				if section == "sink" then
					table.insert(sinks, entry)
					if is_default then default_sink = entry.name end
				elseif section == "source" then
					-- skip monitors
					if not name:lower():find("monitor") then
						table.insert(sources, entry)
						if is_default then default_source = entry.name end
					end
				end
			end
		end
	end

	return sinks, sources, default_sink, default_source
end

function audio.get_state()
	return state_snapshot()
end

function audio.refresh_state(callback)
	if refreshing_state then
		if callback then callback(state_snapshot()) end
		return
	end
	refreshing_state = true

	-- Get output and input volume/mute in one shot
	local cmd = "wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null"
		.. "; printf '\\n---sep---\\n'"
		.. "; wpctl get-volume @DEFAULT_AUDIO_SOURCE@ 2>/dev/null"

	awful.spawn.easy_async_with_shell(cmd, function(stdout, stderr, _, exit_code)
		refreshing_state = false
		if exit_code ~= 0 or trim(stdout) == "" then
			emit_error(trim(stderr) ~= "" and trim(stderr) or "wpctl unavailable")
			if callback then callback(state_snapshot()) end
			return
		end

		local sink_out, source_out = stdout:match("^(.-)\n%-%-%-sep%-%-%-\n(.*)$")
		local out_vol, out_muted = parse_wpctl_volume(sink_out or "")
		local in_vol, in_muted = parse_wpctl_volume(source_out or "")

		state.output_volume = out_vol
		state.output_muted = out_muted
		state.input_volume = in_vol
		state.input_muted = in_muted
		state.available = true
		state.last_error = nil

		emit_state()
		if callback then callback(state_snapshot()) end
	end)
end

function audio.refresh_devices(callback)
	if refreshing_devices then
		if callback then callback(state.devices) end
		return
	end
	refreshing_devices = true

	awful.spawn.easy_async_with_shell("wpctl status 2>/dev/null", function(stdout, stderr, _, exit_code)
		refreshing_devices = false
		if exit_code ~= 0 then
			emit_error(trim(stderr) ~= "" and trim(stderr) or "wpctl status unavailable")
			if callback then callback(state.devices) end
			return
		end

		local sinks, sources, default_sink, default_source = parse_wpctl_status(stdout)
		state.devices.sinks = sinks
		state.devices.sources = sources
		if default_sink then state.default_sink = default_sink end
		if default_source then state.default_source = default_source end
		state.available = true
		state.last_error = nil

		emit_devices()
		if callback then callback(state.devices) end
	end)
end

function audio.refresh(callback)
	audio.refresh_state(function(snapshot)
		audio.refresh_devices(function()
			if callback then callback(snapshot) end
		end)
	end)
end

function audio.get_devices(kind, callback)
	if callback then
		if kind == "sink" then
			callback(state.devices.sinks, state.default_sink)
		elseif kind == "source" then
			callback(state.devices.sources, state.default_source)
		else
			callback(state.devices)
		end
	end
	audio.refresh_devices(function(devices)
		if callback then
			if kind == "sink" then
				callback(devices.sinks, state.default_sink)
			elseif kind == "source" then
				callback(devices.sources, state.default_source)
			else
				callback(devices)
			end
		end
	end)
end

function audio.set_output_volume(percent, callback)
	percent = math.max(0, math.min(100, math.floor(tonumber(percent) or 0)))
	awful.spawn.easy_async_with_shell(
		"wpctl set-volume @DEFAULT_AUDIO_SINK@ " .. percent .. "%",
		function(...)
			audio.refresh_state()
			if callback then callback(...) end
		end
	)
end

function audio.change_output_volume(delta, callback)
	delta = tonumber(delta) or 0
	local amount = tostring(math.abs(delta)) .. "%" .. (delta >= 0 and "+" or "-")
	awful.spawn.easy_async_with_shell(
		"wpctl set-volume @DEFAULT_AUDIO_SINK@ " .. amount,
		function(...)
			audio.refresh_state()
			if callback then callback(...) end
		end
	)
end

function audio.toggle_output_mute(callback)
	awful.spawn.easy_async_with_shell(
		"wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle",
		function(...)
			audio.refresh_state()
			if callback then callback(...) end
		end
	)
end

function audio.set_input_volume(percent, callback)
	percent = math.max(0, math.min(100, math.floor(tonumber(percent) or 0)))
	awful.spawn.easy_async_with_shell(
		"wpctl set-volume @DEFAULT_AUDIO_SOURCE@ " .. percent .. "%",
		function(...)
			audio.refresh_state()
			if callback then callback(...) end
		end
	)
end

function audio.change_input_volume(delta, callback)
	delta = tonumber(delta) or 0
	local amount = tostring(math.abs(delta)) .. "%" .. (delta >= 0 and "+" or "-")
	awful.spawn.easy_async_with_shell(
		"wpctl set-volume @DEFAULT_AUDIO_SOURCE@ " .. amount,
		function(...)
			audio.refresh_state()
			if callback then callback(...) end
		end
	)
end

function audio.toggle_input_mute(callback)
	awful.spawn.easy_async_with_shell(
		"wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle",
		function(...)
			audio.refresh_state()
			if callback then callback(...) end
		end
	)
end

function audio.set_default_device(kind, name, callback)
	if not name or name == "" then return end
	local quoted = shell_quote(name)
	local cmd
	if kind == "sink" then
		cmd = "wpctl set-default " .. quoted
			.. "; pactl list short sink-inputs | cut -f1 | while read i; do [ -n \"$i\" ] && pactl move-sink-input \"$i\" " .. quoted .. "; done"
	elseif kind == "source" then
		cmd = "wpctl set-default " .. quoted
			.. "; pactl list short source-outputs | cut -f1 | while read o; do [ -n \"$o\" ] && pactl move-source-output \"$o\" " .. quoted .. "; done"
	else
		return
	end
	awful.spawn.easy_async_with_shell(cmd, function(...)
		audio.refresh()
		if callback then callback(...) end
	end)
end

-- Debounced refresh timer
local refresh_timer = gears.timer({
	timeout = 0.08,
	single_shot = true,
	autostart = false,
	callback = function() audio.refresh() end,
})

function audio.schedule_refresh()
	refresh_timer:again()
end

function audio.start()
	if started then return end
	started = true

	audio.refresh()

	-- Use pactl subscribe for change events since it's simpler than pw-cli
	subscriber_pid = awful.spawn.with_line_callback("pactl subscribe", {
		stdout = function(line)
			if line:match(" on sink")
				or line:match(" on source")
				or line:match(" on server")
				or line:match(" on sink%-input")
				or line:match(" on source%-output")
			then
				audio.schedule_refresh()
			end
		end,
		exit = function()
			subscriber_pid = nil
		end,
	})
end

awesome.connect_signal("audio::devices:refresh", function() audio.refresh_devices() end)
awesome.connect_signal("widget::volume", function() audio.refresh_state() end)
awesome.connect_signal("widget::microphone", function() audio.refresh_state() end)

return audio
