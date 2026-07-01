local awful = require("awful")
local wibox = require("wibox")
local gears = require("gears")
local beautiful = require("beautiful")
local dpi = beautiful.xresources.apply_dpi
local clipboard = require("services.clipboard")

local MAX_ROWS = 8

-- ── State ─────────────────────────────────────────────────────────────────────

local selected_index = 1
local visible_items  = {}
local query          = ""
local prompt         = awful.widget.prompt()

-- ── Helpers ───────────────────────────────────────────────────────────────────

local function xml_escape(text)
	text = tostring(text or "")
	text = text:gsub("&",  "&amp;")
	text = text:gsub("<",  "&lt;")
	text = text:gsub(">",  "&gt;")
	text = text:gsub('"',  "&quot;")
	text = text:gsub("'",  "&apos;")
	return text
end

local function has_mod(mods, mod)
	for _, m in ipairs(mods or {}) do
		if m == mod then return true end
	end
	return false
end

local function is_boundary(text, pos)
	if pos <= 1 then return true end

	local prev = text:sub(pos - 1, pos - 1)

	return prev == " "
		or prev == "\n"
		or prev == "\t"
		or prev == "-"
		or prev == "_"
		or prev == "/"
		or prev == "."
		or prev == ":"
		or prev == ";"
		or prev == "("
		or prev == "["
		or prev == "{"
end

local function fuzzy_score(text, q)
	text = tostring(text or ""):lower()
	q    = tostring(q or ""):lower()

	if q == "" then
		return 0
	end

	-- Prefer normal substring matches strongly.
	local exact_pos = text:find(q, 1, true)
	if exact_pos then
		return exact_pos - 1000
	end

	local score = 0
	local last_pos = 0

	for i = 1, #q do
		local ch = q:sub(i, i)
		local pos = text:find(ch, last_pos + 1, true)

		if not pos then
			return nil
		end

		local gap = pos - last_pos - 1

		-- Penalize scattered matches.
		score = score + gap * 3

		-- Prefer consecutive matches.
		if pos == last_pos + 1 then
			score = score - 10
		end

		-- Prefer matches at word/path/code-ish boundaries.
		if is_boundary(text, pos) then
			score = score - 8
		end

		-- Prefer matches that start earlier.
		if i == 1 then
			score = score + pos
		end

		last_pos = pos
	end

	return score
end

-- ── Widgets ───────────────────────────────────────────────────────────────────

local title = wibox.widget({
	markup = '<span font="Inter Bold 12">Clipboard History</span>',
	align  = "left",
	valign = "center",
	widget = wibox.widget.textbox,
})

local hint = wibox.widget({
	markup = '<span font="Inter 9" color="#b5bdc5">Enter: paste | Ctrl+Enter: copy | Esc: close</span>',
	align  = "right",
	valign = "center",
	widget = wibox.widget.textbox,
})

local list_layout = wibox.widget({
	layout  = wibox.layout.fixed.vertical,
	spacing = dpi(5),
})

local popup = awful.popup({
	ontop   = true,
	visible = false,
	type    = "dialog",
	shape   = function(cr, w, h) gears.shape.rounded_rect(cr, w, h, dpi(9)) end,
	bg      = "#11161de8",
	fg      = beautiful.fg_normal,
	minimum_width = dpi(660),
	maximum_width = dpi(660),
	placement = function(c)
		awful.placement.bottom(c, { margins = { bottom = dpi(70) } })
	end,
	widget = {
		{
			{
				layout = wibox.layout.align.horizontal,
				title, nil, hint,
			},
			{
				{
					prompt,
					margins = { left = dpi(8), right = dpi(8), top = dpi(6), bottom = dpi(6) },
					widget  = wibox.container.margin,
				},
				bg     = "#00000066",
				shape  = gears.shape.rounded_rect,
				widget = wibox.container.background,
			},
			list_layout,
			spacing = dpi(8),
			layout  = wibox.layout.fixed.vertical,
		},
		margins = dpi(14),
		widget  = wibox.container.margin,
	},
})

-- ── List ──────────────────────────────────────────────────────────────────────

local function rebuild_list()
	list_layout:reset()
	visible_items = {}

	local matches = {}

	for order, item in ipairs(clipboard.get_items()) do
		local searchable = item.text or item.preview or ""
		local score = fuzzy_score(searchable, query)

		if score then
			table.insert(matches, {
				item  = item,
				score = score,
				order = order,
			})
		end
	end

	table.sort(matches, function(a, b)
		if a.score == b.score then
			return a.order < b.order
		end

		return a.score < b.score
	end)

	for i, match in ipairs(matches) do
		if i > MAX_ROWS then break end
		table.insert(visible_items, match.item)
	end

	if #visible_items == 0 then
		list_layout:add(wibox.widget({
			markup = '<span color="#99a1aa">No clipboard entries</span>',
			align  = "center",
			valign = "center",
			widget = wibox.widget.textbox,
		}))
		selected_index = 1
		return
	end

	selected_index = math.max(1, math.min(selected_index, #visible_items))

	for i, item in ipairs(visible_items) do
		local sel        = i == selected_index
		local bg_color   = sel and "#4f8cff44" or "#ffffff10"
		local text_color = sel and "#d8e7ff"   or "#c7d0da"

		list_layout:add(wibox.widget({
			{
				{
					markup = string.format(
						'<span color="%s" font="Inter 10">%s</span>',
						text_color, xml_escape(item.preview)
					),
					align  = "left",
					valign = "center",
					widget = wibox.widget.textbox,
				},
				margins = { left = dpi(8), right = dpi(8), top = dpi(6), bottom = dpi(6) },
				widget  = wibox.container.margin,
			},
			bg     = bg_color,
			shape  = gears.shape.rounded_rect,
			widget = wibox.container.background,
		}))
	end
end

local function move_selection(delta)
	if #visible_items == 0 then selected_index = 1; return end
	selected_index = ((selected_index - 1 + delta) % #visible_items) + 1
	rebuild_list()
end

-- ── Actions ───────────────────────────────────────────────────────────────────

local function close_popup()
	popup.visible = false
end

local function choose_selected(paste)
	local item = visible_items[selected_index]
	if not item then return end
	clipboard.use_item(item, paste)
	close_popup()
end

local function start_prompt()
	awful.prompt.run({
		prompt       = "Search: ",
		textbox      = prompt.widget,
		history_path = gears.filesystem.get_cache_dir() .. "/history_clipboard_search",

		exe_callback = function()
			choose_selected(true)
		end,

		done_callback = function()
			close_popup()
		end,

		changed_callback = function(text)
			query          = text or ""
			selected_index = 1
			rebuild_list()
		end,

		keypressed_callback = function(_, mods, key)
			if key == "Tab" then
				move_selection(has_mod(mods, "Shift") and -1 or 1)
				return true
			elseif key == "ISO_Left_Tab" or key == "BackTab" then
				move_selection(-1)
				return true
			elseif key == "Up" or key == "Left" then
				move_selection(-1)
				return true
			elseif key == "Down" or key == "Right" then
				move_selection(1)
				return true
			elseif key == "Escape" then
				close_popup()
				return true
			elseif key == "Return" then
				choose_selected(not has_mod(mods, "Control"))
				return true
			end
		end,
	})
end

local function show_popup()
	popup.screen   = awful.screen.focused()
	query          = ""
	selected_index = 1
	popup.visible  = true

	rebuild_list()
	start_prompt()
end

-- ── Signals ───────────────────────────────────────────────────────────────────

awesome.connect_signal("flyout::clipboard_history:toggle", function()
	if popup.visible then close_popup() else show_popup() end
end)

awesome.connect_signal("clipboard::updated", function()
	if popup.visible then rebuild_list() end
end)
