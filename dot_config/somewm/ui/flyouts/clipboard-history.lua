local awful = require("awful")
local wibox = require("wibox")
local gears = require("gears")
local beautiful = require("beautiful")
local dpi = beautiful.xresources.apply_dpi

local clipboard_history = require("modules.clipboard-history")

local max_rows = 8
local selected_index = 1
local visible_items = {}
local query = ""
local grabber = nil
local prompt = awful.widget.prompt()

local function xml_escape(text)
	text = tostring(text or "")
	text = text:gsub("&", "&amp;")
	text = text:gsub("<", "&lt;")
	text = text:gsub(">", "&gt;")
	text = text:gsub('"', "&quot;")
	text = text:gsub("'", "&apos;")
	return text
end

local function has_ctrl(mods)
	for _, mod in ipairs(mods or {}) do
		if mod == "Control" then
			return true
		end
	end
	return false
end

local function has_shift(mods)
	for _, mod in ipairs(mods or {}) do
		if mod == "Shift" then
			return true
		end
	end
	return false
end

local function move_selection(delta)
	local count = #visible_items
	if count == 0 then
		selected_index = 1
		return
	end
	selected_index = selected_index + delta
	if selected_index < 1 then
		selected_index = count
	elseif selected_index > count then
		selected_index = 1
	end
	rebuild_list()
end

local title = wibox.widget({
	markup = '<span font="Inter Bold 12">Clipboard History</span>',
	align = "left",
	valign = "center",
	widget = wibox.widget.textbox,
})

local hint = wibox.widget({
	markup = '<span font="Inter 9" color="#b5bdc5">Enter: paste | Ctrl+Enter: copy | Esc: close</span>',
	align = "right",
	valign = "center",
	widget = wibox.widget.textbox,
})

local list_layout = wibox.widget({
	layout = wibox.layout.fixed.vertical,
	spacing = dpi(5),
})

local popup = awful.popup({
	ontop = true,
	visible = false,
	type = "dialog",
	shape = function(cr, w, h)
		gears.shape.rounded_rect(cr, w, h, dpi(9))
	end,
	bg = "#11161de8",
	fg = beautiful.fg_normal,
	minimum_width = dpi(660),
	maximum_width = dpi(660),
	placement = function(c)
		awful.placement.bottom(c, {
			margins = { bottom = dpi(70) },
		})
	end,
	widget = {
		{
			{
				layout = wibox.layout.align.horizontal,
				title,
				nil,
				hint,
			},
			{
				{
					prompt,
					margins = { left = dpi(8), right = dpi(8), top = dpi(6), bottom = dpi(6) },
					widget = wibox.container.margin,
				},
				bg = "#00000066",
				shape = gears.shape.rounded_rect,
				widget = wibox.container.background,
			},
			list_layout,
			spacing = dpi(8),
			layout = wibox.layout.fixed.vertical,
		},
		margins = dpi(14),
		widget = wibox.container.margin,
	},
})

local function close_popup()
	if grabber then
		grabber:stop()
		grabber = nil
	end
	popup.visible = false
end

local function item_matches(item, q)
	if q == "" then
		return true
	end
	local text = item.text:lower()
	return text:find(q:lower(), 1, true) ~= nil
end

local function rebuild_list()
	list_layout:reset()
	visible_items = {}

	for _, item in ipairs(clipboard_history.get_items()) do
		if item_matches(item, query) then
			table.insert(visible_items, item)
		end
		if #visible_items >= max_rows then
			break
		end
	end

	if #visible_items == 0 then
		list_layout:add(wibox.widget({
			markup = '<span color="#99a1aa">No clipboard entries</span>',
			align = "center",
			valign = "center",
			widget = wibox.widget.textbox,
		}))
		selected_index = 1
		return
	end

	if selected_index > #visible_items then
		selected_index = #visible_items
	end
	if selected_index < 1 then
		selected_index = 1
	end

	for i, item in ipairs(visible_items) do
		local selected = i == selected_index
		local bg = selected and "#4f8cff44" or "#ffffff10"
		local text_color = selected and "#d8e7ff" or "#c7d0da"
		list_layout:add(wibox.widget({
			{
				{
					markup = string.format('<span color="%s" font="Inter 10">%s</span>', text_color, xml_escape(item.preview)),
					align = "left",
					valign = "center",
					widget = wibox.widget.textbox,
				},
				margins = { left = dpi(8), right = dpi(8), top = dpi(6), bottom = dpi(6) },
				widget = wibox.container.margin,
			},
			bg = bg,
			shape = gears.shape.rounded_rect,
			widget = wibox.container.background,
		}))
	end
end

local function choose_selected(paste)
	local item = visible_items[selected_index]
	if not item then
		return
	end
	clipboard_history.use_item(item, paste)
	close_popup()
end

local function start_prompt()
	awful.prompt.run({
		prompt = "Search: ",
		textbox = prompt.widget,
		history_path = awful.util.get_cache_dir() .. "/history_clipboard_search",
		exe_callback = function()
			choose_selected(true)
		end,
		done_callback = function()
			close_popup()
		end,
		changed_callback = function(text)
			query = text or ""
			selected_index = 1
			rebuild_list()
		end,
	})
end

local function show_popup()
	popup.screen = awful.screen.focused()
	query = ""
	selected_index = 1
	popup.visible = true
	rebuild_list()
	start_prompt()

	grabber = awful.keygrabber({
		auto_start = true,
		stop_event = "release",
		keypressed_callback = function(_, mods, key)
			if not popup.visible then
				return
			end
			if key == "Escape" then
				close_popup()
				return
			end
			if key == "Up" then
				move_selection(-1)
				return
			end
			if key == "Down" then
				move_selection(1)
				return
			end
			if key == "Left" then
				move_selection(-1)
				return
			end
			if key == "Right" then
				move_selection(1)
				return
			end
			if key == "Tab" then
				if has_shift(mods) then
					move_selection(-1)
				else
					move_selection(1)
				end
				return
			end
			if key == "ISO_Left_Tab" or key == "BackTab" then
				move_selection(-1)
				return
			end
			if key == "Return" then
				local copy_only = has_ctrl(mods)
				choose_selected(not copy_only)
			end
		end,
	})
end

awesome.connect_signal("flyout::clipboard_history:toggle", function()
	if popup.visible then
		close_popup()
	else
		show_popup()
	end
end)

awesome.connect_signal("clipboard::history:updated", function()
	if popup.visible then
		rebuild_list()
	end
end)
