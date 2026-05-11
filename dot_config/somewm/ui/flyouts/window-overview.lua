local awful = require("awful")
local wibox = require("wibox")
local gears = require("gears")
local beautiful = require("beautiful")
local dpi = beautiful.xresources.apply_dpi

local state = {
	popup = nil,
	grid = nil,
	grabber = nil,
	clients = {},
	selected = 1,
	cols = 1,
}

local function xml_escape(text)
	text = tostring(text or "")
	text = text:gsub("&", "&amp;")
	text = text:gsub("<", "&lt;")
	text = text:gsub(">", "&gt;")
	text = text:gsub('"', "&quot;")
	text = text:gsub("'", "&apos;")
	return text
end

local function has_shift(mods)
	for _, mod in ipairs(mods or {}) do
		if mod == "Shift" then
			return true
		end
	end
	return false
end

local function collect_clients()
	local s = awful.screen.focused()
	if not s or not s.selected_tag then
		return {}
	end

	local clients = {}
	for _, c in ipairs(s.selected_tag:clients()) do
		if c.valid and not c.hidden and not c.minimized and not c.skip_taskbar then
			table.insert(clients, c)
		end
	end
	return clients
end

local function close_overview()
	if state.grabber then
		state.grabber:stop()
		state.grabber = nil
	end
	if state.popup then
		state.popup.visible = false
	end
end

local function activate_selected()
	local c = state.clients[state.selected]
	close_overview()
	if c and c.valid then
		c:emit_signal("request::activate", "window_overview", { raise = true })
		c:raise()
	end
end

local function move_selection(delta)
	local count = #state.clients
	if count == 0 then
		state.selected = 1
		return
	end
	state.selected = state.selected + delta
	if state.selected < 1 then
		state.selected = count
	elseif state.selected > count then
		state.selected = 1
	end
end

local function ensure_popup()
	if state.popup then
		return
	end

	state.grid = wibox.layout.grid()
	state.grid.spacing = dpi(12)
	state.grid.expand = true

	state.popup = awful.popup({
		ontop = true,
		visible = false,
		type = "dialog",
		screen = awful.screen.focused(),
		bg = "#0b1016de",
		fg = beautiful.fg_normal,
		placement = awful.placement.maximize,
		widget = {
			{
				{
					markup = '<span font="Inter Bold 13">Window Overview</span>',
					align = "left",
					widget = wibox.widget.textbox,
				},
				{
					markup = '<span font="Inter 9" color="#aeb7c0">Arrows/Tab to move, Enter to select, Esc to close</span>',
					align = "left",
					widget = wibox.widget.textbox,
				},
				state.grid,
				spacing = dpi(10),
				layout = wibox.layout.fixed.vertical,
			},
			margins = { top = dpi(24), left = dpi(24), right = dpi(24), bottom = dpi(24) },
			widget = wibox.container.margin,
		},
	})

	state.popup:buttons(gears.table.join(awful.button({}, 1, nil, function()
		close_overview()
	end)))
end

local function rebuild_grid()
	state.grid:reset()

	local count = #state.clients
	if count == 0 then
		state.grid:add(wibox.widget({
			markup = '<span color="#99a1aa" font="Inter 11">No windows on this workspace</span>',
			align = "center",
			valign = "center",
			widget = wibox.widget.textbox,
		}))
		return
	end

	if state.selected < 1 then
		state.selected = 1
	elseif state.selected > count then
		state.selected = count
	end

	state.cols = math.max(1, math.ceil(math.sqrt(count)))
	state.grid.forced_num_cols = state.cols

	for i, c in ipairs(state.clients) do
		local selected = i == state.selected
		local border = selected and "#4f8cffaa" or "#ffffff20"
		local bg = selected and "#4f8cff33" or "#10161d99"
		local title = c.name or c.class or "Untitled"

		local card = wibox.widget({
			{
				{
					{
						image = c.icon,
						resize = true,
						forced_width = dpi(22),
						forced_height = dpi(22),
						widget = wibox.widget.imagebox,
					},
					{
						markup = string.format('<span font="Inter 10" color="#d5dee8">%s</span>', xml_escape(title)),
						ellipsize = "end",
						widget = wibox.widget.textbox,
					},
					spacing = dpi(8),
					layout = wibox.layout.fixed.horizontal,
				},
				{
					markup = string.format('<span font="Inter 9" color="#99a4af">%s</span>', xml_escape(c.class or "")),
					widget = wibox.widget.textbox,
				},
				spacing = dpi(8),
				layout = wibox.layout.fixed.vertical,
			},
			margins = dpi(10),
			widget = wibox.container.margin,
		})

		local card_bg = wibox.widget({
			card,
			forced_width = dpi(280),
			forced_height = dpi(90),
			bg = bg,
			shape = gears.shape.rounded_rect,
			border_width = dpi(2),
			border_color = border,
			widget = wibox.container.background,
		})

		card_bg:buttons(gears.table.join(awful.button({}, 1, nil, function()
			state.selected = i
			activate_selected()
		end)))

		state.grid:add(card_bg)
	end
end

local function start_grabber()
	if state.grabber then
		state.grabber:stop()
	end

	state.grabber = awful.keygrabber({
		auto_start = true,
		stop_event = "release",
		keypressed_callback = function(_, mods, key)
			if key == "Escape" then
				close_overview()
				return
			end
			if key == "Return" then
				activate_selected()
				return
			end
			if key == "Tab" then
				local backward = has_shift(mods)
				move_selection(backward and -1 or 1)
				rebuild_grid()
				return
			end
			if key == "ISO_Left_Tab" or key == "BackTab" then
				move_selection(-1)
				rebuild_grid()
				return
			end
			if key == "Left" then
				move_selection(-1)
				rebuild_grid()
				return
			end
			if key == "Right" then
				move_selection(1)
				rebuild_grid()
				return
			end
			if key == "Up" then
				move_selection(-state.cols)
				rebuild_grid()
				return
			end
			if key == "Down" then
				move_selection(state.cols)
				rebuild_grid()
			end
		end,
	})
end

local function toggle_overview()
	ensure_popup()
	if state.popup.visible then
		close_overview()
		return
	end

	state.clients = collect_clients()
	state.selected = 1
	state.popup.screen = awful.screen.focused()
	rebuild_grid()
	state.popup.visible = true
	start_grabber()
end

awesome.connect_signal("flyout::window_overview:toggle", function()
	toggle_overview()
end)
