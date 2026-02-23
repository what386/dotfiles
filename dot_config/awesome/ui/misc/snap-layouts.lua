local awful = require("awful")
local gears = require("gears")
local wibox = require("wibox")
local beautiful = require("beautiful")

local dpi = beautiful.xresources.apply_dpi

local TOP_TRIGGER_HEIGHT = dpi(18)
local POPUP_TOP_MARGIN = dpi(12)
local CARD_WIDTH = dpi(120)
local CARD_HEIGHT = dpi(76)
local CARD_SPACING = dpi(10)

local layouts = {
	{
		name = "Half",
		slots = {
			{ x = 0.00, y = 0.00, w = 0.50, h = 1.00 },
			{ x = 0.50, y = 0.00, w = 0.50, h = 1.00 },
		},
	},
	{
		name = "Thirds",
		slots = {
			{ x = 0.00, y = 0.00, w = 0.33, h = 1.00 },
			{ x = 0.33, y = 0.00, w = 0.34, h = 1.00 },
			{ x = 0.67, y = 0.00, w = 0.33, h = 1.00 },
		},
	},
	{
		name = "Focus",
		slots = {
			{ x = 0.00, y = 0.00, w = 0.67, h = 1.00 },
			{ x = 0.67, y = 0.00, w = 0.33, h = 0.50 },
			{ x = 0.67, y = 0.50, w = 0.33, h = 0.50 },
		},
	},
	{
		name = "Grid",
		slots = {
			{ x = 0.00, y = 0.00, w = 0.50, h = 0.50 },
			{ x = 0.50, y = 0.00, w = 0.50, h = 0.50 },
			{ x = 0.00, y = 0.50, w = 0.50, h = 0.50 },
			{ x = 0.50, y = 0.50, w = 0.50, h = 0.50 },
		},
	},
}

local state = {
	popup = nil,
	cards_row = nil,
	hitboxes = {},
	slot_widgets = {},
	active_client = nil,
	hover_layout = nil,
	hover_slot = nil,
	tracking_timer = nil,
}

local function update_visual_selection()
	for layout_index, slots in pairs(state.slot_widgets) do
		for slot_index, slot_widget in pairs(slots) do
			if layout_index == state.hover_layout and slot_index == state.hover_slot then
				slot_widget.bg = "#6da5ffaa"
			else
				slot_widget.bg = "#ffffff24"
			end
		end
	end
end

local function ensure_popup()
	if state.popup then
		return
	end

	state.cards_row = wibox.widget({
		layout = wibox.layout.fixed.horizontal,
		spacing = CARD_SPACING,
	})

	state.slot_widgets = {}
	for layout_index, entry in ipairs(layouts) do
		state.slot_widgets[layout_index] = {}

		local mini = wibox.widget({
			layout = wibox.layout.manual,
			forced_width = CARD_WIDTH - dpi(14),
			forced_height = CARD_HEIGHT - dpi(24),
		})

		for slot_index, slot in ipairs(entry.slots) do
			local slot_widget = wibox.widget({
				bg = "#ffffff24",
				shape = gears.shape.rounded_rect,
				widget = wibox.container.background,
			})
			state.slot_widgets[layout_index][slot_index] = slot_widget
			mini:add_at(slot_widget, {
				x = math.floor(slot.x * mini.forced_width),
				y = math.floor(slot.y * mini.forced_height),
				width = math.max(2, math.floor(slot.w * mini.forced_width) - dpi(2)),
				height = math.max(2, math.floor(slot.h * mini.forced_height) - dpi(2)),
			})
		end

		local card = wibox.widget({
			{
				mini,
				margins = { top = dpi(7), left = dpi(7), right = dpi(7), bottom = dpi(3) },
				widget = wibox.container.margin,
			},
			{
				markup = string.format('<span font="Inter 9" color="#d7deea">%s</span>', entry.name),
				align = "center",
				widget = wibox.widget.textbox,
			},
			spacing = dpi(2),
			layout = wibox.layout.fixed.vertical,
		})

		state.cards_row:add(wibox.widget({
			card,
			forced_width = CARD_WIDTH,
			forced_height = CARD_HEIGHT,
			bg = "#0f141ddd",
			shape = gears.shape.rounded_rect,
			border_width = dpi(1),
			border_color = "#ffffff18",
			widget = wibox.container.background,
		}))
	end

	state.popup = awful.popup({
		ontop = true,
		visible = false,
		type = "utility",
		bg = "#00000000",
		widget = {
			{
				state.cards_row,
				margins = dpi(6),
				widget = wibox.container.margin,
			},
			bg = "#070b10db",
			shape = gears.shape.rounded_rect,
			border_width = dpi(1),
			border_color = "#ffffff1f",
			widget = wibox.container.background,
		},
	})
end

local function clear_hover()
	state.hover_layout = nil
	state.hover_slot = nil
	update_visual_selection()
end

local function hide_popup()
	if state.tracking_timer then
		state.tracking_timer:stop()
		state.tracking_timer = nil
	end
	if state.popup then
		state.popup.visible = false
	end
	clear_hover()
	state.active_client = nil
end

local function compute_hitboxes()
	state.hitboxes = {}
	if not (state.popup and state.popup.visible and state.popup.screen) then
		return
	end

	local popup_x = state.popup.x
	local popup_y = state.popup.y
	local content_x = popup_x + dpi(6)
	local content_y = popup_y + dpi(6)

	for layout_index, entry in ipairs(layouts) do
		local card_x = content_x + (layout_index - 1) * (CARD_WIDTH + CARD_SPACING)
		local mini_x = card_x + dpi(7)
		local mini_y = content_y + dpi(7)
		local mini_w = CARD_WIDTH - dpi(14)
		local mini_h = CARD_HEIGHT - dpi(24)

		for slot_index, slot in ipairs(entry.slots) do
			table.insert(state.hitboxes, {
				layout_index = layout_index,
				slot_index = slot_index,
				x = mini_x + math.floor(slot.x * mini_w),
				y = mini_y + math.floor(slot.y * mini_h),
				w = math.max(1, math.floor(slot.w * mini_w) - dpi(2)),
				h = math.max(1, math.floor(slot.h * mini_h) - dpi(2)),
			})
		end
	end
end

local function hit_test(mouse)
	for _, hb in ipairs(state.hitboxes) do
		if mouse.x >= hb.x and mouse.x <= (hb.x + hb.w) and mouse.y >= hb.y and mouse.y <= (hb.y + hb.h) then
			return hb.layout_index, hb.slot_index
		end
	end
	return nil, nil
end

local function apply_snap(c, layout_index, slot_index)
	if not (c and c.valid and c.screen) then
		return
	end

	local slot = layouts[layout_index] and layouts[layout_index].slots[slot_index]
	if not slot then
		return
	end

	local wa = c.screen.workarea
	local x = wa.x + math.floor(slot.x * wa.width)
	local y = wa.y + math.floor(slot.y * wa.height)
	local w = math.max(dpi(220), math.floor(slot.w * wa.width))
	local h = math.max(dpi(140), math.floor(slot.h * wa.height))

	c.floating = true
	c.maximized = false
	c.maximized_vertical = false
	c.maximized_horizontal = false
	c.fullscreen = false
	local target = { x = x, y = y, width = w, height = h }
	c:geometry(target)
	-- Guard against occasional post-drag race where geometry is overwritten.
	gears.timer({
		timeout = 0.03,
		single_shot = true,
		autostart = true,
		callback = function()
			if c and c.valid then
				c:geometry(target)
			end
		end,
	})
	c:emit_signal("request::activate", "snap_layout", { raise = true })
	c:raise()
end

local function update_hover_from_mouse(mouse)
	local lidx, sidx = hit_test(mouse)
	if lidx ~= state.hover_layout or sidx ~= state.hover_slot then
		state.hover_layout = lidx
		state.hover_slot = sidx
		update_visual_selection()
	end
end

local function begin_drag_tracking()
	if state.tracking_timer then
		state.tracking_timer:stop()
	end

	state.tracking_timer = gears.timer({
		timeout = 1 / 60,
		autostart = true,
		callback = function()
			if not state.popup or not state.popup.visible then
				if state.tracking_timer then
					state.tracking_timer:stop()
					state.tracking_timer = nil
				end
				return
			end

			local m = mouse.coords()
			update_hover_from_mouse(m)

			if not (m and m.buttons and m.buttons[1]) then
				local c = state.active_client
				local lidx = state.hover_layout
				local sidx = state.hover_slot
				hide_popup()
				if c and lidx and sidx then
					apply_snap(c, lidx, sidx)
				end
				if state.tracking_timer then
					state.tracking_timer:stop()
					state.tracking_timer = nil
				end
			end
		end,
	})
end

local function show_popup_for_client(c)
	if not (c and c.valid and c.screen) then
		return
	end

	ensure_popup()
	state.active_client = c
	clear_hover()

	state.popup.screen = c.screen
	state.popup.visible = true
	awful.placement.top(state.popup, {
		parent = c.screen,
		honor_workarea = true,
		margins = { top = POPUP_TOP_MARGIN },
	})

	compute_hitboxes()
	begin_drag_tracking()
end

local function should_offer_snap(c)
	if not (c and c.valid and c.screen) then
		return false
	end
	if c.fullscreen then
		return false
	end
	local m = mouse.coords()
	if not (m and m.buttons and m.buttons[1]) then
		return false
	end
	return m.y <= (c.screen.geometry.y + TOP_TRIGGER_HEIGHT)
end

client.connect_signal("property::geometry", function(c)
	if should_offer_snap(c) then
		show_popup_for_client(c)
	end
end)

client.connect_signal("unmanage", function(c)
	if state.active_client == c then
		hide_popup()
	end
end)

awesome.connect_signal("flyout::snap_layouts:hide", function()
	hide_popup()
end)
