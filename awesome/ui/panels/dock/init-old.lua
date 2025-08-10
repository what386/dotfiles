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
	panel:connect_signal("mouse::enter", function()
		panel.hover = true
	end)
	panel:connect_signal("mouse::leave", function()
		panel.hover = false
		awesome.emit_signal("panel::dock:rerun")
	end)
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
	dock_trigger:connect_signal("mouse::enter", function()
		awesome.emit_signal("panel::dock:show")
	end)

	-- Function to check if dock should always be visible
	local function should_always_show_dock()
		local current_tag = s.selected_tag
		if not current_tag then
			return true -- No tag selected, show dock
		end

		-- Get dock geometry (approximate, since it might not be visible)
		local dock_area = {
			x = 0,
			y = s.geometry.height - dock_height - dock_margins,
			width = s.geometry.width,
			height = dock_height + dock_margins,
		}

		-- Check if any visible clients overlap with dock area
		local clients = current_tag:clients()
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
					return false -- Client overlaps dock area
				end
			end
		end

		return true -- No overlapping clients, show dock
	end

	-- Store the original function
	panel._original_toggle = panel.toggle

	function panel:toggle()
		if should_always_show_dock() then
			self.visible = true
		else
			self.visible = true
		end
	end

	-- Add function to check visibility state
	function panel:should_be_persistent()
		return should_always_show_dock()
	end

	return panel
end

local hide_dock = gears.timer({
	timeout = 1,
	autostart = true,
	callback = function()
		local focused = awful.screen.focused()
		if focused.dockpanel then
			-- Check if dock should be persistent
			if focused.dockpanel:should_be_persistent() then
				focused.dockpanel.visible = true
			elseif not focused.dockpanel.hover then
				focused.dockpanel.visible = false
			end
		end
	end,
})

awesome.connect_signal("panel::dock:rerun", function()
	if hide_dock.started then
		hide_dock:again()
	else
		hide_dock:start()
	end
end)

awesome.connect_signal("panel::dock:show", function()
	local focused = awful.screen.focused()
	if focused.dockpanel then
		focused.dockpanel.visible = true
		awesome.emit_signal("panel::dock:rerun")
	end
end)

-- Connect to tag and client signals to update dock visibility
local function update_dock_visibility()
	awesome.emit_signal("panel::dock:rerun")
end

-- Update when tag selection changes
tag.connect_signal("property::selected", update_dock_visibility)

-- Update when tag layout changes
tag.connect_signal("property::layout", update_dock_visibility)

-- Update when clients are added/removed from tags
client.connect_signal("tagged", update_dock_visibility)
client.connect_signal("untagged", update_dock_visibility)
client.connect_signal("manage", update_dock_visibility)
client.connect_signal("unmanage", update_dock_visibility)

-- Update when client geometry changes (move/resize)
client.connect_signal("property::geometry", update_dock_visibility)
client.connect_signal("property::hidden", update_dock_visibility)
client.connect_signal("property::minimized", update_dock_visibility)

-- Update when client focus changes (in case of stacking changes)
client.connect_signal("focus", update_dock_visibility)
client.connect_signal("unfocus", update_dock_visibility)

return create_dock
