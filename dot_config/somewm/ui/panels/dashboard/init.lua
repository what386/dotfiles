local awful = require("awful")
local wibox = require("wibox")
local gears = require("gears")
local beautiful = require("beautiful")
local icons = require("theme.icons")

return function(s)
	local function dp(value) return beautiful.xresources.apply_dpi(value, s) end
	local ui = require("ui.panels.components")(dp)
	local calendar = require("ui.panels.dashboard.calendar")(dp, ui)
	local viewport = ui.viewport()
	local mode = "overview"
	local tab_order = { "overview", "settings", "resources" }
	local panel, navigation
	local pages, monitors, nav_buttons = {}, {}, {}
	local controls = { overview = {}, settings = {}, resources = {} }
	local building_page = "overview"
	local key_hints = wibox.widget({
		text = "move: hjkl / arrows\nopen: enter",
		font = "Inter Regular 9", align = "center", valign = "center",
		wrap = "word", ellipsize = "end", widget = wibox.widget.textbox,
	})
	local selection = require("ui.panels.dashboard.selection")(function(selected, editing)
		local action = selected and (selected.control.keyboard_action or (selected.control.keyboard_adjust and "adjust" or "toggle")) or "open"
		key_hints:set_text(editing
			and "adjust: hl / left-right\ndone: enter / esc"
			or "move: hjkl / arrows\n" .. action .. ": enter")
		for _, items in pairs(controls) do
			for _, item in ipairs(items) do
				item.widget.border_color = item == selected and (editing and beautiful.fg_normal or beautiful.accent) or beautiful.transparent
				item.widget.bg = item == selected and editing and beautiful.groups_bg or beautiful.transparent
			end
		end
		for name, button in pairs(nav_buttons) do
			button.border_width = dp(2)
			button.border_color = not selected and name == mode and beautiful.fg_normal or beautiful.transparent
		end
		if selected then viewport:reveal(selected.widget) end
	end, function(widget) return viewport:get_bounds(widget) end)
	local function selectable(control, items, group)
		local wrapper = wibox.widget({
			{ control, margins = dp(3), widget = wibox.container.margin },
			border_width = dp(2), border_color = beautiful.transparent,
			shape = function(cr, w, h) gears.shape.rounded_rect(cr, w, h, dp(6)) end,
			widget = wibox.container.background,
		})
		items = items or controls[building_page]
		local item = { widget = wrapper, control = control, id = control.keyboard_id, group = group }
		items[#items + 1] = item
		wrapper:connect_signal("button::press", function()
			for index, candidate in ipairs(selection.items) do
				if candidate == item then selection:select(index); break end
			end
		end)
		return wrapper
	end
	local function devices(kind, title)
		return require("ui.panels.dashboard.settings.audio-device-switcher")({
			kind = kind, title = title,
			wrap_rows = function(rows)
				local items, widgets = {}, {}
				for _, item in ipairs(controls.settings) do
					if item.group ~= kind then items[#items + 1] = item end
				end
				for _, row in ipairs(rows) do widgets[#widgets + 1] = selectable(row, items, kind) end
				controls.settings = items
				if mode == "settings" then selection:refresh_items(items) end
				return widgets
			end,
		})
	end

	local function setting(name) return selectable(require("ui.panels.dashboard.settings." .. name)) end
	local columns = ui.columns
	local quick = ui.card("Quick controls", ui.column(
		columns(setting("airplane-toggle"), setting("bluetooth-toggle"), 360),
		columns(setting("dont-disturb-toggle"), setting("redshift-toggle"), 360),
		setting("brightness-slider"), setting("volume-slider")))
	pages.overview = columns(
		ui.column(ui.card(nil, selectable(calendar))),
		ui.column(quick))
	building_page = "settings"
	pages.settings = columns(
		ui.column(ui.card("Display & appearance", ui.column(
			setting("brightness-slider"), setting("autobacklight-toggle"), setting("blur-toggle"), setting("blur-slider"))),
			ui.card("Session", setting("sessionsave-toggle"))),
		ui.column(ui.card("Sound", ui.column(setting("volume-slider"), setting("microphone-slider"),
			devices("sink", "Output device"), devices("source", "Input device")))))
	local meters = {}
	for _, name in ipairs({
		"cpu-usage", "ram-usage", "gpu-usage",
		"disk-usage", "temp-meter", "fan-meter",
	}) do
		local meter = require("ui.panels.dashboard.sys-monitor." .. name)()
		monitors[#monitors + 1] = meter
		meters[#meters + 1] = ui.card(nil, meter)
	end
	pages.resources = columns(
		ui.column(meters[1], meters[3]),
		ui.column(meters[2], meters[4], meters[5], meters[6])
	)

	local function update_monitors()
		for _, meter in ipairs(monitors) do
			if panel and panel.visible and mode == "resources" then
				if meter.start then meter:start() end
			elseif meter.stop then meter:stop() end
		end
	end
	local function select_page(name)
		if not pages[name] then return end
		mode = name
		viewport:set_content(pages[name])
		for key, button in pairs(nav_buttons) do
			button.bg = key == name and beautiful.accent or beautiful.groups_bg
		end
		selection:set_items(controls[name])
		if name == "settings" then awesome.emit_signal("audio::devices:refresh") end
		update_monitors()
	end
	navigation = wibox.layout.fixed.horizontal()
	navigation.spacing = dp(8)
	for _, item in ipairs({
		{ "overview", "Overview", icons.system.menu },
		{ "settings", "Settings", icons.dashboard.switch.gear },
		{ "resources", "Resources", icons.dashboard.switch.chart },
	}) do
		local button = ui.button(item[2], function() select_page(item[1]) end, item[3])
		nav_buttons[item[1]] = button
		navigation:add(button)
	end
	local compact_navigation = wibox.widget({
		{ navigation, height = dp(42), strategy = "exact", widget = wibox.container.constraint },
		valign = "center", widget = wibox.container.place,
	})
	local body = wibox.widget({
		{ { compact_navigation,
			{ key_hints, left = dp(12), right = dp(12), widget = wibox.container.margin },
			ui.card(nil, require("ui.panels.dashboard.user-profile")(dp), 8), layout = wibox.layout.align.horizontal },
			bottom = dp(12), widget = wibox.container.margin },
		viewport,
		nil,
		layout = wibox.layout.align.vertical,
	})
	s.backdrop_dashboard = wibox({
		ontop = true, screen = s, bg = beautiful.transparent, type = "utility", visible = false,
		x = s.geometry.x, y = s.geometry.y, width = s.geometry.width, height = s.geometry.height,
	})
	panel = awful.popup({
		widget = { body, margins = dp(12), widget = wibox.container.margin },
		screen = s, type = "dock", visible = false, ontop = true,
		bg = beautiful.background, fg = beautiful.fg_normal,
		shape = function(cr, w, h) gears.shape.rounded_rect(cr, w, h, dp(16)) end,
	})
	local function geometry()
		local area = s.workarea or s.geometry
		local margin = dp(12)
		-- Workarea is already in physical pixels; scale only design dimensions.
		local width = math.max(1, math.min(dp(940), area.width - 2 * margin))
		local height = math.max(1, math.min(dp(600), area.height - 2 * margin))
		panel.minimum_width, panel.maximum_width = width, width
		panel.minimum_height, panel.maximum_height = height, height
		panel.width, panel.height = width, height
		panel.x = area.x + math.floor((area.width - width) / 2)
		panel.y = area.y + area.height - height - margin
		local g = s.geometry
		s.backdrop_dashboard.x, s.backdrop_dashboard.y = g.x, g.y
		s.backdrop_dashboard.width, s.backdrop_dashboard.height = g.width, g.height
	end
	panel.opened = false
	local keyboard = require("ui.panels.dashboard.keyboard")(function(direction)
		for index, name in ipairs(tab_order) do
			if name == mode then
				select_page(tab_order[(index - 1 + direction) % #tab_order + 1])
				return
			end
		end
	end, function() panel:hide_dashboard() end, selection)
	local refresh_timer = gears.timer({
		timeout = 60, autostart = false,
		callback = function()
			if mode == "overview" then calendar:refresh() end
		end,
	})
	function panel:hide_dashboard()
		keyboard:stop()
		self.opened = false
		self.visible = false
		s.backdrop_dashboard.visible = false
		refresh_timer:stop()
		update_monitors()
		self:emit_signal("closed")
	end
	function panel:toggle()
		if self.opened then self:hide_dashboard(); return end
		geometry()
		self.opened = true
		s.backdrop_dashboard.visible = true
		self.visible = true
		select_page("overview")
		calendar:refresh()
		refresh_timer:start()
		keyboard:start()
		self:emit_signal("opened")
	end
	function panel:switch_pane(name) select_page(name) end
	s.backdrop_dashboard:buttons({ awful.button({}, 1, function() panel:hide_dashboard() end) })
	s:connect_signal("property::geometry", geometry)
	s:connect_signal("property::workarea", geometry)
	select_page("overview")
	geometry()
	return panel
end
