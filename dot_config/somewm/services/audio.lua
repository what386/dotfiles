local awful = require("awful")
local gears = require("gears")
local icons = require("theme.icons")

local audio = {}

local state = {
	available = false,
	backend = "unknown",
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

local function shell_quote(value)
	return "'" .. tostring(value):gsub("'", "'\\''") .. "'"
end

local function trim(value)
	return tostring(value or ""):match("^%s*(.-)%s*$")
end

local function command_exists(command, callback)
	awful.spawn.easy_async_with_shell("command -v " .. command .. " >/dev/null 2>&1", function(_, _, _, exit_code)
		callback(exit_code == 0)
	end)
end

local function emit_error(message)
	state.available = false
	state.last_error = message
	awesome.emit_signal("audio::error", message)
end

local function shallow_copy(source)
	local copy = {}
	for key, value in pairs(source) do
		copy[key] = value
	end
	return copy
end

local function state_snapshot()
	local snapshot = shallow_copy(state)
	snapshot.devices = {
		sinks = state.devices.sinks,
		sources = state.devices.sources,
	}
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

	-- Compatibility for older widgets/signals during the service migration.
	awesome.emit_signal("volume::update", state.output_volume)
	awesome.emit_signal("widget::microphone:update", state.input_volume)
end

local function emit_devices()
	awesome.emit_signal("audio::devices", state.devices)
end

local function parse_volume(output)
	return tonumber(tostring(output or ""):match("(%d+)%%")) or 0
end

local function parse_mute(output)
	return tostring(output or ""):match("Mute:%s*yes") ~= nil
end

local function split_sections(stdout, marker)
	local sections = {}
	local start_at = 1
	stdout = tostring(stdout or "")

	while true do
		local marker_start, marker_end = stdout:find(marker, start_at, true)
		if not marker_start then
			table.insert(sections, stdout:sub(start_at))
			break
		end

		table.insert(sections, stdout:sub(start_at, marker_start - 1))
		start_at = marker_end + 1
	end

	return sections
end

local function parse_devices(stdout, kind)
	local devices = {}
	local current = nil
	local header_pattern = kind == "sink" and "^Sink #%d+" or "^Source #%d+"

	local function commit_device()
		if not current or trim(current.name) == "" then
			return
		end

		current.name = trim(current.name)
		current.description = trim(current.description ~= "" and current.description or current.name)
		current.state = trim(current.state)

		if kind ~= "source" or not current.name:match("%.monitor$") then
			table.insert(devices, current)
		end
	end

	for line in tostring(stdout or ""):gmatch("[^\r\n]+") do
		if line:match(header_pattern) then
			commit_device()
			current = { name = "", description = "", state = "" }
		elseif current then
			local name = line:match("^%s*Name:%s*(.+)$")
			local description = line:match("^%s*Description:%s*(.+)$")
			local device_state = line:match("^%s*State:%s*(.+)$")

			if name and current.name == "" then
				current.name = name
			elseif description and current.description == "" then
				current.description = description
			elseif device_state and current.state == "" then
				current.state = device_state
			end
		end
	end

	commit_device()
	return devices
end

local function run_backend(command, callback)
	awful.spawn.easy_async_with_shell(command, function(stdout, stderr, reason, exit_code)
		if exit_code ~= 0 then
			emit_error(trim(stderr) ~= "" and trim(stderr) or "Audio command failed: " .. command)
		end
		if callback then
			callback(stdout, stderr, reason, exit_code)
		end
	end)
end

local function run_wpctl_or_pactl(wpctl_command, pactl_command, callback)
	local command = "(command -v wpctl >/dev/null 2>&1 && "
		.. wpctl_command
		.. ") || "
		.. pactl_command
	run_backend(command, callback)
end

function audio.get_state()
	return state_snapshot()
end

function audio.refresh_state(callback)
	if refreshing_state then
		if callback then
			callback(state_snapshot())
		end
		return
	end

	refreshing_state = true
	local command = table.concat({
		"pactl get-sink-volume @DEFAULT_SINK@ 2>/dev/null",
		"pactl get-sink-mute @DEFAULT_SINK@ 2>/dev/null",
		"pactl get-source-volume @DEFAULT_SOURCE@ 2>/dev/null",
		"pactl get-source-mute @DEFAULT_SOURCE@ 2>/dev/null",
		"pactl get-default-sink 2>/dev/null",
		"pactl get-default-source 2>/dev/null",
	}, "; printf '\\n---audio-service-section---\\n'; ")

	awful.spawn.easy_async_with_shell(command, function(stdout, stderr, _, exit_code)
		refreshing_state = false

		if exit_code ~= 0 or trim(stdout) == "" then
			emit_error(trim(stderr) ~= "" and trim(stderr) or "Audio backend unavailable")
			if callback then
				callback(state_snapshot())
			end
			return
		end

		local sections = split_sections(stdout, "\n---audio-service-section---\n")

		state.output_volume = parse_volume(sections[1])
		state.output_muted = parse_mute(sections[2])
		state.input_volume = parse_volume(sections[3])
		state.input_muted = parse_mute(sections[4])
		state.default_sink = trim(sections[5])
		state.default_source = trim(sections[6])
		state.available = true
		state.last_error = nil

		emit_state()
		if callback then
			callback(state_snapshot())
		end
	end)
end

function audio.refresh_devices(callback)
	if refreshing_devices then
		if callback then
			callback(state.devices)
		end
		return
	end

	refreshing_devices = true
	local command = "pactl list sinks 2>/dev/null; printf '\n---audio-service-devices---\n'; pactl list sources 2>/dev/null"

	awful.spawn.easy_async_with_shell(command, function(stdout, stderr, _, exit_code)
		refreshing_devices = false

		if exit_code ~= 0 then
			emit_error(trim(stderr) ~= "" and trim(stderr) or "Audio devices unavailable")
			if callback then
				callback(state.devices)
			end
			return
		end

		local sink_output, source_output = tostring(stdout):match("^(.-)\n%-%-%-audio%-service%-devices%-%-%-\n(.*)$")
		state.devices.sinks = parse_devices(sink_output or "", "sink")
		state.devices.sources = parse_devices(source_output or "", "source")
		state.available = true
		state.last_error = nil

		emit_devices()
		if callback then
			callback(state.devices)
		end
	end)
end

function audio.refresh(callback)
	audio.refresh_state(function(snapshot)
		audio.refresh_devices(function()
			if callback then
				callback(snapshot)
			end
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
	run_wpctl_or_pactl(
		"wpctl set-volume @DEFAULT_AUDIO_SINK@ " .. tostring(percent) .. "%",
		"pactl set-sink-volume @DEFAULT_SINK@ " .. tostring(percent) .. "%",
		function(...)
			audio.refresh_state()
			if callback then
				callback(...)
			end
		end
	)
end

function audio.change_output_volume(delta, callback)
	delta = tonumber(delta) or 0
	local suffix = delta >= 0 and "+" or "-"
	local amount = tostring(math.abs(delta)) .. "%" .. suffix
	run_wpctl_or_pactl(
		"wpctl set-volume @DEFAULT_AUDIO_SINK@ " .. amount,
		"pactl set-sink-volume @DEFAULT_SINK@ " .. amount,
		function(...)
			audio.refresh_state()
			if callback then
				callback(...)
			end
		end
	)
end

function audio.toggle_output_mute(callback)
	run_wpctl_or_pactl(
		"wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle",
		"pactl set-sink-mute @DEFAULT_SINK@ toggle",
		function(...)
			audio.refresh_state()
			if callback then
				callback(...)
			end
		end
	)
end

function audio.set_input_volume(percent, callback)
	percent = math.max(0, math.min(100, math.floor(tonumber(percent) or 0)))
	run_wpctl_or_pactl(
		"wpctl set-volume @DEFAULT_AUDIO_SOURCE@ " .. tostring(percent) .. "%",
		"pactl set-source-volume @DEFAULT_SOURCE@ " .. tostring(percent) .. "%",
		function(...)
			audio.refresh_state()
			if callback then
				callback(...)
			end
		end
	)
end

function audio.change_input_volume(delta, callback)
	delta = tonumber(delta) or 0
	local suffix = delta >= 0 and "+" or "-"
	local amount = tostring(math.abs(delta)) .. "%" .. suffix
	run_wpctl_or_pactl(
		"wpctl set-volume @DEFAULT_AUDIO_SOURCE@ " .. amount,
		"pactl set-source-volume @DEFAULT_SOURCE@ " .. amount,
		function(...)
			audio.refresh_state()
			if callback then
				callback(...)
			end
		end
	)
end

function audio.toggle_input_mute(callback)
	run_wpctl_or_pactl(
		"wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle",
		"pactl set-source-mute @DEFAULT_SOURCE@ toggle",
		function(...)
			audio.refresh_state()
			if callback then
				callback(...)
			end
		end
	)
end

function audio.set_default_device(kind, name, callback)
	if not name or name == "" then
		return
	end

	local quoted_name = shell_quote(name)
	local command
	if kind == "sink" then
		command = "pactl set-default-sink "
			.. quoted_name
			.. "; pactl list short sink-inputs | cut -f1 | while read input; do [ -n \"$input\" ] && pactl move-sink-input \"$input\" "
			.. quoted_name
			.. "; done"
	elseif kind == "source" then
		command = "pactl set-default-source "
			.. quoted_name
			.. "; pactl list short source-outputs | cut -f1 | while read output; do [ -n \"$output\" ] && pactl move-source-output \"$output\" "
			.. quoted_name
			.. "; done"
	else
		return
	end

	run_backend(command, function(...)
		audio.refresh()
		if callback then
			callback(...)
		end
	end)
end

local refresh_timer = gears.timer({
	timeout = 0.08,
	single_shot = true,
	autostart = false,
	callback = function()
		audio.refresh()
	end,
})

function audio.schedule_refresh()
	refresh_timer:again()
end

function audio.start()
	if started then
		return
	end
	started = true

	command_exists("wpctl", function(has_wpctl)
		command_exists("pactl", function(has_pactl)
			if has_wpctl then
				state.backend = "wpctl+pactl"
			elseif has_pactl then
				state.backend = "pactl"
			else
				state.backend = "unavailable"
				emit_error("Neither wpctl nor pactl is installed")
				return
			end

			audio.refresh()

			if has_pactl then
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
		end)
	end)
end

awesome.connect_signal("audio::devices:refresh", function()
	audio.refresh_devices()
end)

awesome.connect_signal("widget::volume", function()
	audio.refresh_state()
end)

awesome.connect_signal("widget::microphone", function()
	audio.refresh_state()
end)

return audio
