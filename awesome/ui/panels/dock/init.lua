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

	function panel:toggle()
		self.visible = true
	end

	return panel
end

local hide_dock = gears.timer({
	timeout = 1,
	autostart = true,
	callback = function()
		local focused = awful.screen.focused()
		if not focused.dockpanel.hover then
			focused.dockpanel.visible = false
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
	focused.dockpanel.visible = true
	awesome.emit_signal("panel::dock:rerun")
end)

return create_dock
