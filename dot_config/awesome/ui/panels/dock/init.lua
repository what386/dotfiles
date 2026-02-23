local awful = require("awful")
local wibox = require("wibox")
local gears = require("gears")
local beautiful = require("beautiful")
local dpi = beautiful.xresources.apply_dpi
local tag_list = require("ui.panels.dock.tag-list")

local create_dock = function(s)
	local separator = wibox.widget({
		orientation = "vertical",
		forced_height = dpi(1),
		forced_width = dpi(1),
		span_ratio = 0.55,
		widget = wibox.widget.separator,
	})
	local dock_height = dpi(60)
	local dock_margins = dpi(4)
	local panel = awful.popup({
		widget = {
			-- Removing this block will cause an error...
		},
		ontop = true,
		opened = false,
		visible = false,
		type = "dock",
		screen = s,
		height = dock_height,
		maximum_height = dock_height,
		offset = dpi(5),
		placement = function(w)
			awful.placement.bottom(w, { offset = { y = -dock_margins } })
		end,
		shape = function(cr, w, h)
			gears.shape.rounded_rect(cr, w, h, beautiful.groups_radius)
		end,
		preferred_anchors = "middle",
		preferred_positions = { "left", "right", "top", "bottom" },
	})
	panel:setup({
		widget = wibox.container.background,
		bg = beautiful.transparent,
		{
			layout = wibox.layout.fixed.horizontal,
			require("ui.panels.dock.search-apps"),
			separator,
			tag_list(s),
			separator,
			require("ui.panels.dock.xdg-folders"),
		},
	})
	panel.hover = false

	local dock_trigger = wibox({
		ontop = true,
		visible = true,
		screen = s,
		type = "dock",
		width = s.geometry.width,
		height = 5,
		y = s.geometry.height - 5,
		shape = gears.shape.rectangle,
		bg = "#ff0000ff",
		opacity = 0,
		position = "bottom",
	})

	-- Function to check if dock should always be visible
	local function should_always_show_dock()
		local current_tag = s.selected_tag

		if not current_tag then
			return true -- No tag selected, show dock
		end

		-- Get all clients on the current tag
		local clients = current_tag:clients()

		-- If no clients on the tag, always show dock
		if #clients == 0 then
			return true
		end

		-- Get dock geometry (approximate, since it might not be visible)
		local dock_area = {
			x = 0,
			y = s.geometry.height - dock_height - dock_margins,
			width = s.geometry.width,
			height = dock_height + dock_margins,
		}

		-- Check if any visible clients overlap with dock area
		for _, c in ipairs(clients) do
			if c.valid and not c.hidden and not c.minimized and c.screen == s then
				local cg = c:geometry()

				-- Check for overlap
				if
					cg.x < dock_area.x + dock_area.width
					and cg.x + cg.width > dock_area.x
					and cg.y < dock_area.y + dock_area.height
					and cg.y + cg.height > dock_area.y
				then
					return false -- Client overlaps dock area, hide dock
				end
			end
		end

		return true -- No overlapping clients, show dock
	end

	local hide_dock = gears.timer({
		timeout = 1,
		autostart = true,
		callback = function()
			-- Check if dock should be persistent
			-- TODO: fix should_always_show_dock for multi-screens
			if not s.dockpanel.hover then -- and not should_always_show_dock() then
				s.dockpanel.visible = false
			end
		end,
	})

	panel.start_hide = function()
		if hide_dock.started then
			hide_dock:again()
		else
			hide_dock:start()
		end
	end

	panel:connect_signal("mouse::enter", function()
		panel.hover = true
	end)

	dock_trigger:connect_signal("mouse::enter", function()
		s.dockpanel.visible = true
	end)

	panel:connect_signal("mouse::leave", function()
		panel.hover = false
		if hide_dock.started then
			hide_dock:again()
		else
			hide_dock:start()
		end
	end)

	-- Connect to tag and client signals to update dock visibility
	local function update_dock_visibility()
		if hide_dock.started then
			hide_dock:again()
		else
			hide_dock:start()
		end

		if should_always_show_dock() then
			if not s.dockpanel.visible then
				s.dockpanel.visible = true
			end
		else
			if hide_dock.started then
				hide_dock:again()
			else
				hide_dock:start()
			end
		end
	end

	-- Update when tag selection changes (screen-specific)
	screen.connect_signal("tag::history::update", function(scr)
		if scr == s then
			update_dock_visibility()
		end
	end)

	-- Update when clients are added/removed from tags
	local function client_update_handler(c)
		-- Only update if the client is on this screen
		if c.screen == s then
			update_dock_visibility()
		end
	end

	client.connect_signal("tagged", client_update_handler)
	client.connect_signal("untagged", client_update_handler)
	client.connect_signal("manage", client_update_handler)
	client.connect_signal("unmanage", client_update_handler)
	client.connect_signal("property::hidden", client_update_handler)
	client.connect_signal("property::minimized", client_update_handler)
	client.connect_signal("focus", client_update_handler)
	client.connect_signal("unfocus", client_update_handler)

	return panel
end

awesome.connect_signal("panel::dock:show", function()
	local focused = awful.screen.focused()
	if focused.dockpanel then
		focused.dockpanel.visible = true
		focused.dockpanel:start_hide()
	end
end)

return create_dock
