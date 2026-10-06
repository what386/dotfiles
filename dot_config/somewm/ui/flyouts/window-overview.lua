local awful = require("awful")
local wibox = require("wibox")
local gears = require("gears")
local beautiful = require("beautiful")
local glib = require("lgi").GLib
local windowing = require("utilities.windowing")
local dpi = beautiful.xresources.apply_dpi

local MARGIN = dpi(44)
local TILE_GAP = dpi(14)
local TILE_MIN_WIDTH = dpi(280)
local TILE_MIN_HEIGHT = dpi(190)
local TILE_MAX_WIDTH = dpi(440)
local TILE_MAX_HEIGHT = dpi(300)
local BACKDROP_COLOR = beautiful.overlay_backdrop
local TILE_COLOR = "#172331"
local TRANSITION_DURATION = 0.18
local FRAME_INTERVAL = 1 / 60

local overlays = {}
local pages = {}
local selections = {}
local entries_by_screen = {}
local columns_by_screen = {}
local page_sizes = {}
local preview_widgets_by_screen = {}
local preview_loader
local grids = {}
local query = ""
local selection_screen
local search_screen
local search_prompt = wibox.widget.textbox()
local open = false
local prompt_active = false
local transition_progress = 0
local transition_timer

local function apply_motion(s)
	local overlay = overlays[s]
	if not overlay then return end
	overlay.opacity = transition_progress
	local grid = grids[s]
	if not grid then return end
	for i, tile in ipairs(grid.tiles) do
		local x = tile.x + (grid.center_x - tile.x) * (1 - transition_progress) * 0.14
		local y = tile.y + ((grid.center_y - tile.y) * 0.14 + dpi(16)) * (1 - transition_progress)
		grid.layout:move(i, {
			x = math.floor(x + 0.5),
			y = math.floor(y + 0.5),
			width = tile.width,
			height = tile.height,
		})
	end
end

local function finish_hide()
	preview_loader:clear()
	preview_widgets_by_screen = {}
	entries_by_screen = {}
	grids = {}
	for _, overlay in pairs(overlays) do
		overlay.visible = false
		overlay.widget = nil -- Release window snapshots until the next opening.
	end
end

local function animate_to(target)
	if transition_timer then transition_timer:stop(); transition_timer = nil end
	local start = transition_progress
	if start == target then
		if target == 0 then finish_hide() end
		return
	end
	local started_at = glib.get_monotonic_time()
	local duration = TRANSITION_DURATION * math.abs(target - start)
	transition_timer = gears.timer({
		timeout = FRAME_INTERVAL,
		callback = function()
			local elapsed = (glib.get_monotonic_time() - started_at) / 1000000
			local fraction = math.min(1, elapsed / duration)
			local eased = target == 1 and (1 - (1 - fraction) ^ 3) or fraction ^ 3
			transition_progress = start + (target - start) * eased
			for s in pairs(overlays) do apply_motion(s) end
			if fraction == 1 then
				transition_timer:stop()
				transition_timer = nil
				if target == 0 and not open then finish_hide() end
			end
		end,
	})
	transition_timer:start()
end

local function xml_escape(value)
	local escaped = tostring(value or "")
	escaped = escaped:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;")
	return escaped
end

local function text_widget(value, font, color, align)
	return wibox.widget({
		markup = string.format('<span foreground="%s">%s</span>', color, xml_escape(value)),
		font = font,
		align = align or "left",
		valign = "center",
		ellipsize = "end",
		widget = wibox.widget.textbox,
	})
end

local function collect_entries(s)
	local entries, seen = {}, {}
	local tags = {}
	if s.selected_tag then tags[#tags + 1] = s.selected_tag end
	for _, t in ipairs(s.tags) do
		if t ~= s.selected_tag then tags[#tags + 1] = t end
	end

	for _, t in ipairs(tags) do
		local has_window = false
		for _, c in ipairs(t:clients()) do
			if c.valid and c.screen == s and not c.hidden and not c.skip_taskbar then
				has_window = true
				if not seen[c] then
					entries[#entries + 1] = { client = c, tag = t }
					seen[c] = true
				end
			end
		end
		if t == s.selected_tag and not has_window then
			entries[#entries + 1] = { tag = t }
		end
	end

	return entries
end

local function fuzzy_score(value, search)
	local haystack = tostring(value or ""):lower()
	local needle = search:lower()
	local exact = haystack:find(needle, 1, true)
	if exact then return exact - 1000 end
	local score, last = 0, 0
	for i = 1, #needle do
		local position = haystack:find(needle:sub(i, i), last + 1, true)
		if not position then return nil end
		local previous = haystack:sub(position - 1, position - 1)
		score = score + (position - last - 1) * 3
		if position == last + 1 then score = score - 10 end
		if position == 1 or previous:match("[%s%p]") then score = score - 8 end
		if i == 1 then score = score + position end
		last = position
	end
	return score
end

local function matching_entries(s)
	local entries = collect_entries(s)
	if query == "" then return entries, {} end
	local ranked = {}
	for index, entry in ipairs(entries) do
		local c = entry.client
		if c then
			local fields = { c.name, c.class, c.instance, c.app_id }
			local best
			for _, field in pairs(fields) do
				local score = fuzzy_score(field, query)
				if score and (not best or score < best) then best = score end
			end
			if best then ranked[#ranked + 1] = { entry = entry, score = best, order = index } end
		end
	end
	table.sort(ranked, function(a, b)
		if a.score ~= b.score then return a.score < b.score end
		return a.order < b.order
	end)
	local results, scores = {}, {}
	for _, match in ipairs(ranked) do
		results[#results + 1] = match.entry
		scores[#scores + 1] = match.score
	end
	return results, scores
end

local function show_preview(c, surface)
	for _, widgets in pairs(preview_widgets_by_screen) do
		for _, preview in ipairs(widgets[c] or {}) do
			preview.holder:set_widget(wibox.widget({
				image = surface,
				resize = true,
				forced_width = preview.width,
				forced_height = preview.height,
				widget = wibox.widget.imagebox,
			}))
		end
	end
end

preview_loader = windowing.preview_loader({
	is_relevant = function(c)
		if not open then return false end
		for _, widgets in pairs(preview_widgets_by_screen) do
			if widgets[c] then return true end
		end
		return false
	end,
	on_preview = show_preview,
})

local function hide()
	if not open then return end
	open = false
	preview_loader:stop()
	if prompt_active then
		awful.keygrabber.stop()
		prompt_active = false
	end
	animate_to(0)
end

local function activate(entry)
	hide()
	local c, t = entry.client, entry.tag
	if not t or not t.screen then return end
	if c and c.valid then
		awful.screen.focus(c.screen)
		if not t.selected then t:view_only() end
		c:emit_signal("request::activate", "window_overview", { raise = true })
		c:raise()
	else
		awful.screen.focus(t.screen)
		t:view_only()
	end
end

local function make_tile(entry, width, height, selected, preview_widgets)
	local c, t = entry.client, entry.tag
	local focused = c and c == client.focus
	local title = c and (c.name or c.class or "Untitled") or "Empty workspace"
	local workspace = "Workspace " .. tostring(t.name or t.index or "")
	local preview_height = math.max(dpi(70), height - dpi(68))
	local surface = c and preview_loader:get(c)
	local image = surface or (c and c.icon)
	local preview = image and wibox.widget({
		image = image,
		resize = true,
		forced_width = surface and width - dpi(20) or dpi(64),
		forced_height = surface and preview_height or dpi(64),
		widget = wibox.widget.imagebox,
	}) or text_widget(c and (c.class or "Window") or "No windows", "Inter Regular 12", "#ffffff88", "center")
	local preview_holder = wibox.widget({ preview, halign = "center", valign = "center", widget = wibox.container.place })
	if c then
		preview_widgets[c] = preview_widgets[c] or {}
		preview_widgets[c][#preview_widgets[c] + 1] = {
			holder = preview_holder,
			width = width - dpi(20),
			height = preview_height,
		}
		preview_loader:queue(c)
	end

	local tile = wibox.widget({
		{
			{
				preview_holder,
				bg = "#00000066",
				shape = function(cr, w, h) gears.shape.rounded_rect(cr, w, h, dpi(7)) end,
				forced_height = preview_height,
				widget = wibox.container.background,
			},
			{
				text_widget(title, "Inter Medium 10", beautiful.fg_normal),
				text_widget(workspace, "Inter Regular 9", "#ffffff99"),
				layout = wibox.layout.fixed.vertical,
			},
			spacing = dpi(7),
			layout = wibox.layout.fixed.vertical,
		},
		margins = dpi(10),
		widget = wibox.container.margin,
	})
	local card = wibox.widget({
		tile,
		bg = TILE_COLOR,
		shape = function(cr, w, h) gears.shape.rounded_rect(cr, w, h, dpi(12)) end,
		border_width = dpi(2),
		border_color = selected and beautiful.accent or (focused and "#ffffff88" or "#ffffff25"),
		forced_width = width,
		forced_height = height,
		widget = wibox.container.background,
	})
	card:connect_signal("button::release", function() activate(entry) end)
	card:connect_signal("mouse::enter", function()
		card.border_color = beautiful.accent or "#4f8cff"
	end)
	card:connect_signal("mouse::leave", function()
		card.border_color = selected and beautiful.accent or (focused and "#ffffff88" or "#ffffff25")
	end)
	return card
end

local function page_button(label, enabled, callback)
	local button = wibox.widget({
		text_widget(label, "Inter Medium 12", enabled and beautiful.fg_normal or "#ffffff55", "center"),
		bg = enabled and TILE_COLOR or "#111a25",
		shape = function(cr, w, h) gears.shape.rounded_rect(cr, w, h, dpi(7)) end,
		forced_width = dpi(38),
		forced_height = dpi(30),
		widget = wibox.container.background,
	})
	if enabled then button:connect_signal("button::release", callback) end
	return button
end

local rebuild_screen

local function change_page(s, delta)
	if not open or not s or not overlays[s] then return end
	pages[s] = (pages[s] or 1) + delta
	selections[s] = math.max(1, (pages[s] - 1) * (page_sizes[s] or 1) + 1)
	local previous_screen = selection_screen
	selection_screen = s
	if previous_screen and previous_screen ~= s then rebuild_screen(previous_screen) end
	rebuild_screen(s)
end

local function step_selection(s, delta)
	local entries = s and entries_by_screen[s]
	if not entries or #entries == 0 then return end
	selections[s] = ((selections[s] or 1) - 1 + delta) % #entries + 1
	pages[s] = math.ceil(selections[s] / (page_sizes[s] or 1))
	local previous_screen = selection_screen
	selection_screen = s
	if previous_screen and previous_screen ~= s then rebuild_screen(previous_screen) end
	rebuild_screen(s)
end

local function activate_selected(s)
	local entries = s and entries_by_screen[s]
	local entry = entries and entries[selections[s] or 1]
	if entry then activate(entry) end
end

rebuild_screen = function(s)
	local overlay = overlays[s]
	if not overlay then return end
	local geometry = s.geometry
	overlay.x, overlay.y = geometry.x, geometry.y
	overlay.width, overlay.height = geometry.width, geometry.height

	local entries = entries_by_screen[s] or {}
	local available_width = math.max(dpi(240), geometry.width - MARGIN * 2)
	local available_height = math.max(dpi(200), geometry.height - MARGIN * 2 - dpi(92))
	local columns = math.min(5, math.max(1, math.floor((available_width + TILE_GAP) / (TILE_MIN_WIDTH + TILE_GAP))))
	local rows = math.min(3, math.max(1, math.floor((available_height + TILE_GAP) / (TILE_MIN_HEIGHT + TILE_GAP))))
	local page_size = columns * rows
	columns_by_screen[s] = columns
	page_sizes[s] = page_size
	if not selections[s] then
		selections[s] = 1
		if query == "" then
			for i, entry in ipairs(entries) do
				if entry.client == client.focus then selections[s] = i; break end
			end
		end
	end
	selections[s] = math.max(1, math.min(selections[s], math.max(1, #entries)))
	local page_count = math.max(1, math.ceil(#entries / page_size))
	local page = math.max(1, math.min(pages[s] or math.ceil(selections[s] / page_size), page_count))
	pages[s] = page
	local first = (page - 1) * page_size + 1
	local visible_count = math.max(0, math.min(page_size, #entries - first + 1))
	local visible_columns = math.max(1, math.min(columns, visible_count))
	local visible_rows = math.max(1, math.ceil(visible_count / visible_columns))
	local max_width = visible_count == 1 and dpi(840) or TILE_MAX_WIDTH
	local max_height = visible_count == 1 and dpi(520) or TILE_MAX_HEIGHT
	local tile_width = math.floor(math.min(max_width, (available_width - (visible_columns - 1) * TILE_GAP) / visible_columns))
	local tile_height = math.floor(math.min(max_height, (available_height - (visible_rows - 1) * TILE_GAP) / visible_rows))

	local grid_width = visible_columns * tile_width + (visible_columns - 1) * TILE_GAP
	local grid_height = visible_rows * tile_height + (visible_rows - 1) * TILE_GAP
	local grid = wibox.layout.manual()
	local preview_widgets = {}
	preview_widgets_by_screen[s] = preview_widgets
	grid.forced_width = grid_width
	grid.forced_height = grid_height
	local tiles = {}
	for row = 1, visible_rows do
		for column = 1, visible_columns do
			local entry = entries[first + (row - 1) * visible_columns + column - 1]
			if entry then
				local index = first + (row - 1) * visible_columns + column - 1
				local point = {
					x = (column - 1) * (tile_width + TILE_GAP),
					y = (row - 1) * (tile_height + TILE_GAP),
					width = tile_width,
					height = tile_height,
				}
				grid:add_at(make_tile(entry, tile_width, tile_height, s == selection_screen and index == selections[s], preview_widgets), point)
				tiles[#tiles + 1] = point
			end
		end
	end
	grids[s] = {
		layout = grid,
		tiles = tiles,
		center_x = (grid_width - tile_width) / 2,
		center_y = (grid_height - tile_height) / 2,
	}

	local search_box = wibox.widget({
		{
			s == search_screen and search_prompt or text_widget("Search: " .. query, "Inter Regular 12", beautiful.fg_normal),
			margins = { left = dpi(14), right = dpi(14), top = dpi(8), bottom = dpi(8) },
			widget = wibox.container.margin,
		},
		bg = TILE_COLOR,
		shape = function(cr, w, h) gears.shape.rounded_rect(cr, w, h, dpi(9)) end,
		forced_width = dpi(420),
		widget = wibox.container.background,
	})
	local header = wibox.widget({
		{ search_box, halign = "center", widget = wibox.container.place },
		{ text_widget("Overview", "Inter Bold 22", beautiful.fg_normal), halign = "left", widget = wibox.container.place },
		layout = wibox.layout.stack,
	})
	local footer = wibox.widget({
		page_button("‹", page > 1, function() change_page(s, -1) end),
		text_widget(string.format("%d / %d", page, page_count), "Inter Medium 10", "#ffffffaa", "center"),
		page_button("›", page < page_count, function() change_page(s, 1) end),
		spacing = dpi(10),
		layout = wibox.layout.fixed.horizontal,
	})

	local content = grid
	if #entries == 0 then
		content = text_widget(query ~= "" and "No matching windows" or "No windows", "Inter Medium 14", "#ffffffaa", "center")
	end
	overlay:setup({
		{
			header,
			{ content, halign = "center", valign = "center", widget = wibox.container.place },
			{ footer, halign = "center", widget = wibox.container.place },
			layout = wibox.layout.align.vertical,
		},
		margins = MARGIN,
		widget = wibox.container.margin,
	})
	apply_motion(s)
end

local function refresh_results()
	local best_screen, best_score
	for s in screen do
		local entries, scores = matching_entries(s)
		entries_by_screen[s] = entries
		pages[s] = nil
		selections[s] = nil
		if query ~= "" and scores[1] and (not best_score or scores[1] < best_score) then
			best_screen, best_score = s, scores[1]
		end
	end
	selection_screen = best_screen or search_screen
	for s in screen do rebuild_screen(s) end
end

local function ensure_overlay(s)
	if overlays[s] then return overlays[s] end
	local geometry = s.geometry
	local overlay = wibox({
		screen = s,
		type = "notification",
		ontop = true,
		visible = false,
		x = geometry.x,
		y = geometry.y,
		width = geometry.width,
		height = geometry.height,
		bg = BACKDROP_COLOR,
		fg = beautiful.fg_normal,
		opacity = 0,
	})
	overlays[s] = overlay
	return overlay
end

local function show()
	if open then return end
	open = true
	query = ""
	search_screen = awful.screen.focused()
	for s in screen do
		ensure_overlay(s)
		overlays[s].visible = true
	end
	refresh_results()
	animate_to(1)
	prompt_active = true
	awful.prompt.run({
		prompt = "Search: ",
		textbox = search_prompt,
		font = "Inter Regular 12",
		fg_cursor = beautiful.fg_normal,
		bg_cursor = beautiful.accent,
		changed_callback = function(value)
			if not open or value == query then return end
			query = value or ""
			refresh_results()
		end,
		exe_callback = function()
			prompt_active = false
			activate_selected(selection_screen)
		end,
		done_callback = function()
			prompt_active = false
			if open then hide() end
		end,
		keypressed_callback = function(modifiers, key)
			local s = selection_screen or search_screen
			if key == "e" and modifiers.Mod4 then
				hide()
				return true
			elseif key == "Tab" then
				step_selection(s, modifiers.Shift and -1 or 1)
				return true
			elseif key == "ISO_Left_Tab" or key == "BackTab" then
				step_selection(s, -1)
				return true
			elseif key == "Up" then
				step_selection(s, -(columns_by_screen[s] or 1))
				return true
			elseif key == "Down" then
				step_selection(s, columns_by_screen[s] or 1)
				return true
			elseif key == "Page_Down" then
				change_page(s, 1)
				return true
			elseif key == "Page_Up" then
				change_page(s, -1)
				return true
			end
		end,
	})
end

awesome.connect_signal("flyout::window_overview:toggle", function()
	if open then hide() else show() end
end)

screen.connect_signal("removed", function(s)
	if open then hide() end
	overlays[s] = nil
	pages[s] = nil
	selections[s] = nil
	entries_by_screen[s] = nil
	columns_by_screen[s] = nil
	page_sizes[s] = nil
	grids[s] = nil
	preview_widgets_by_screen[s] = nil
end)

return { show = show, hide = hide, is_open = function() return open end }
