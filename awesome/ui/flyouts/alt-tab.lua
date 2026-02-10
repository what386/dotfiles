local awful = require("awful")
local wibox = require("wibox")
local gears = require("gears")
local beautiful = require("beautiful")
local dpi = beautiful.xresources.apply_dpi

local state = {
	popup = nil,
	preview_row = nil,
	grabber = nil,
	clients = {},
	selected = 1,
	screenshots = {},
	thumbnail_cache = {},
	refresh_timer = nil,
}

local PREVIEW_CARD_WIDTH = dpi(196)
local PREVIEW_ROW_SPACING = dpi(10)
local POPUP_HORIZONTAL_MARGIN = dpi(10)

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
	local raw_clients = client.get()
	local clients = {}

	for _, c in ipairs(raw_clients) do
		if c.valid and not c.hidden and not c.minimized and not c.skip_taskbar then
			table.insert(clients, c)
		end
	end

	if #clients <= 1 then
		return clients
	end

	local focused = client.focus
	if focused then
		for i, c in ipairs(clients) do
			if c == focused then
				table.remove(clients, i)
				table.insert(clients, 1, focused)
				break
			end
		end
	end

	return clients
end

local function is_client_visibly_rendered(c)
	if not c or not c.valid then
		return false
	end
	local ok, visible = pcall(function()
		return c:isvisible()
	end)
	return ok and visible or false
end

local function get_screenshot(c)
	local ss = state.screenshots[c]
	if ss then
		return ss
	end

	ss = awful.screenshot({
		client = c,
	})
	state.screenshots[c] = ss
	return ss
end

local function start_refresh_timer()
	if state.refresh_timer then
		state.refresh_timer:stop()
	end

	state.refresh_timer = gears.timer({
		timeout = 0.35,
		autostart = true,
		callback = function()
			if not (state.popup and state.popup.visible) then
				return
			end
			for _, c in ipairs(state.clients) do
				local ss = state.screenshots[c]
				if ss then
					ss:refresh()
					if is_client_visibly_rendered(c) and ss.surface then
						state.thumbnail_cache[c] = ss.surface
					end
				end
			end
		end,
	})
end

local function ensure_popup()
	if state.popup then
		return
	end

	state.preview_row = wibox.widget({
		layout = wibox.layout.fixed.horizontal,
		spacing = PREVIEW_ROW_SPACING,
	})

	state.popup = awful.popup({
		ontop = true,
		visible = false,
		type = "utility",
		bg = "#00000000",
		fg = beautiful.fg_normal,
		shape = function(cr, w, h)
			gears.shape.rounded_rect(cr, w, h, dpi(9))
		end,
		minimum_width = dpi(360),
		maximum_width = dpi(1200),
		placement = function(c)
			awful.placement.centered(c, { parent = awful.screen.focused() })
		end,
		widget = {
			{
				{
					state.preview_row,
					halign = "center",
					valign = "center",
					widget = wibox.container.place,
				},
				layout = wibox.layout.fixed.vertical,
			},
			margins = dpi(10),
			widget = wibox.container.margin,
		},
	})
end

local function update_list()
	state.preview_row:reset()

	for i, c in ipairs(state.clients) do
		local selected = i == state.selected
		local fg = selected and "#e5efff" or "#d2d9e2"
		local title = c.name or c.class or "Untitled"
		local subtitle = c.class and c.class ~= title and c.class or ""
		local border_color = selected and "#4f8cffcc" or "#ffffff22"
		local screenshot = get_screenshot(c)
		local preview_widget
		local visible_now = is_client_visibly_rendered(c)
		if visible_now then
			screenshot:refresh()
			if screenshot.surface then
				state.thumbnail_cache[c] = screenshot.surface
			end
			preview_widget = screenshot.content_widget
		else
			preview_widget = wibox.widget({
				image = state.thumbnail_cache[c] or c.icon,
				resize = true,
				widget = wibox.widget.imagebox,
			})
		end
		preview_widget.halign = "center"
		preview_widget.valign = "center"

		local preview_base = wibox.widget({
			preview_widget,
			halign = "center",
			valign = "center",
			widget = wibox.container.place,
		})

		local preview_card = wibox.widget({
			preview_base,
			bg = selected and "#16243d" or "#0d131a",
			shape = gears.shape.rounded_rect,
			forced_width = dpi(178),
			forced_height = dpi(104),
			widget = wibox.container.background,
		})

		local icon_overlay = wibox.widget({
			{
				image = c.icon,
				resize = true,
				forced_width = dpi(18),
				forced_height = dpi(18),
				widget = wibox.widget.imagebox,
			},
			halign = "right",
			valign = "top",
			widget = wibox.container.place,
		})

		local preview_stack = wibox.widget({
			layout = wibox.layout.stack,
			preview_card,
			icon_overlay,
		})

		local labels = wibox.widget({
			layout = wibox.layout.fixed.vertical,
			{
				markup = string.format('<span color="%s" font="Inter 10">%s</span>', fg, xml_escape(title)),
				align = "center",
				widget = wibox.widget.textbox,
			},
			{
				markup = string.format('<span color="#9aa5b1" font="Inter 9">%s</span>', xml_escape(subtitle)),
				align = "center",
				widget = wibox.widget.textbox,
			},
		})

		local inner = wibox.widget({
			layout = wibox.layout.fixed.vertical,
			spacing = dpi(8),
			preview_stack,
			labels,
		})

		state.preview_row:add(wibox.widget({
			{
				inner,
				margins = { left = dpi(10), right = dpi(10), top = dpi(9), bottom = dpi(9) },
				widget = wibox.container.margin,
			},
			bg = selected and "#4f8cff33" or "#ffffff0f",
			shape = gears.shape.rounded_rect,
			border_width = dpi(2),
			border_color = border_color,
			forced_width = PREVIEW_CARD_WIDTH,
			widget = wibox.container.background,
		}))
	end
end

local function step_selection(step)
	local count = #state.clients
	if count == 0 then
		state.selected = 1
		return
	end
	state.selected = state.selected + step
	if state.selected < 1 then
		state.selected = count
	elseif state.selected > count then
		state.selected = 1
	end
	update_list()
end

local function close_popup()
	if state.grabber then
		state.grabber:stop()
		state.grabber = nil
	end
	if state.refresh_timer then
		state.refresh_timer:stop()
		state.refresh_timer = nil
	end
	if state.popup then
		state.popup.visible = false
	end
end

local function activate_selected()
	local c = state.clients[state.selected]
	close_popup()
	if c and c.valid then
		if c.screen then
			awful.screen.focus(c.screen)
		end
		if c.first_tag then
			c.first_tag:view_only()
		end
		c:emit_signal("request::activate", "alt_tab", { raise = true })
		c:raise()
	end
end

local function start_grabber()
	if state.grabber then
		state.grabber:stop()
	end

	state.grabber = awful.keygrabber({
		auto_start = false,
		keypressed_callback = function(_, mods, key)
			if key == "Tab" then
				local backward = has_shift(mods)
				step_selection(backward and -1 or 1)
				return
			end
			if key == "ISO_Left_Tab" or key == "BackTab" then
				step_selection(-1)
				return
			end
			if key == "Left" or key == "Up" then
				step_selection(-1)
				return
			end
			if key == "Right" or key == "Down" then
				step_selection(1)
				return
			end
			if key == "Return" then
				activate_selected()
				return
			end
			if key == "Escape" then
				close_popup()
			end
		end,
		keyreleased_callback = function(_, _, key)
			if
				key == "Alt_L"
				or key == "Alt_R"
				or key == "Super_L"
				or key == "Super_R"
				or key == "Mod4_L"
				or key == "Mod4_R"
			then
				activate_selected()
			end
		end,
	})

	state.grabber:start()
end

local function show_switcher(reverse)
	ensure_popup()

	if state.popup.visible then
		step_selection(reverse and -1 or 1)
		return
	end

	state.clients = collect_clients()

	if #state.clients == 0 then
		return
	end

	if #state.clients == 1 then
		local c = state.clients[1]
		if c and c.valid then
			c:emit_signal("request::activate", "alt_tab", { raise = true })
			c:raise()
		end
		return
	end

	if reverse then
		state.selected = #state.clients
	else
		state.selected = 2
	end

	local scr = awful.screen.focused()
	local work_w = (scr and scr.workarea and scr.workarea.width) or dpi(1920)
	local content_width = (#state.clients * PREVIEW_CARD_WIDTH)
		+ (math.max(0, #state.clients - 1) * PREVIEW_ROW_SPACING)
		+ (POPUP_HORIZONTAL_MARGIN * 2)
	local popup_width = math.max(dpi(320), math.min(content_width, work_w - dpi(60)))
	state.popup.minimum_width = popup_width
	state.popup.maximum_width = popup_width

	update_list()
	state.popup.screen = awful.screen.focused()
	state.popup.visible = true
	start_grabber()
	start_refresh_timer()
end

awesome.connect_signal("flyout::alt_tab:next", function()
	show_switcher(false)
end)

awesome.connect_signal("flyout::alt_tab:prev", function()
	show_switcher(true)
end)

client.connect_signal("unmanage", function(c)
	state.screenshots[c] = nil
	state.thumbnail_cache[c] = nil
end)
