local awful = require("awful")
local gears = require("gears")

local clipboard_history = {
	items = {},
	max_items = 50,
	max_item_length = 12000,
	last_value = "",
	poll_interval = 0.8,
	started = false,
}

local function shell_quote(s)
	return "'" .. tostring(s):gsub("'", [['"'"']]) .. "'"
end

local function normalize_text(text)
	if not text then
		return ""
	end
	text = text:gsub("\r", "")
	text = text:gsub("%s+$", "")
	return text
end

local function preview_text(text)
	local oneline = text:gsub("\n", " "):gsub("%s+", " ")
	if #oneline > 90 then
		return oneline:sub(1, 87) .. "..."
	end
	return oneline
end

local function push_item(text)
	text = normalize_text(text)
	if text == "" or #text > clipboard_history.max_item_length then
		return
	end

	local existing_index = nil
	for i, entry in ipairs(clipboard_history.items) do
		if entry.text == text then
			existing_index = i
			break
		end
	end

	if existing_index then
		table.remove(clipboard_history.items, existing_index)
	end

	table.insert(clipboard_history.items, 1, {
		text = text,
		preview = preview_text(text),
		ts = os.time(),
	})

	while #clipboard_history.items > clipboard_history.max_items do
		table.remove(clipboard_history.items)
	end

	awesome.emit_signal("clipboard::history:updated", clipboard_history.items)
end

local function read_clipboard_once(callback)
	awful.spawn.easy_async_with_shell("xclip -o -selection clipboard 2>/dev/null", function(stdout)
		callback(normalize_text(stdout))
	end)
end

function clipboard_history.start()
	if clipboard_history.started then
		return
	end

	clipboard_history.started = true
	clipboard_history.timer = gears.timer({
		timeout = clipboard_history.poll_interval,
		autostart = true,
		call_now = true,
		callback = function()
			read_clipboard_once(function(current)
				if current ~= "" and current ~= clipboard_history.last_value then
					clipboard_history.last_value = current
					push_item(current)
				end
			end)
		end,
	})
end

function clipboard_history.stop()
	if clipboard_history.timer then
		clipboard_history.timer:stop()
		clipboard_history.timer = nil
	end
	clipboard_history.started = false
end

function clipboard_history.get_items()
	return clipboard_history.items
end

function clipboard_history.clear()
	clipboard_history.items = {}
	clipboard_history.last_value = ""
	awesome.emit_signal("clipboard::history:updated", clipboard_history.items)
end

function clipboard_history.copy_text(text, done)
	text = normalize_text(text)
	if text == "" then
		if done then
			done(false)
		end
		return
	end

	local cmd = "printf %s " .. shell_quote(text) .. " | xclip -selection clipboard -in"
	awful.spawn.easy_async_with_shell(cmd, function()
		clipboard_history.last_value = text
		push_item(text)
		if done then
			done(true)
		end
	end)
end

function clipboard_history.use_item(item, paste_after, done)
	if not item or not item.text then
		if done then
			done(false)
		end
		return
	end

	clipboard_history.copy_text(item.text, function(ok)
		if ok and paste_after then
			awful.spawn("xdotool key --clearmodifiers ctrl+v", false)
		end
		if done then
			done(ok)
		end
	end)
end

clipboard_history.start()

return clipboard_history
