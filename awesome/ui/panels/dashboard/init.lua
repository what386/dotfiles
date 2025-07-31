local wibox = require("wibox")
local awful = require("awful")
local gears = require("gears")
local beautiful = require("beautiful")
local dpi = beautiful.xresources.apply_dpi
local apps = require("config.user.preferences")
panel_visible = false

local create_dashboard = function(screen)
	local panel_width = dpi(350)

	local panel = wibox({
		ontop = true,
		visible = false,
		screen = screen,
		type = "dock",
		width = panel_width,
		position = "left",
		height = screen.geometry.height - dpi(36) + 1,
		x = screen.geometry.x,
		y = screen.geometry.y + dpi(36) - 1,
		shape = gears.shape.rectangle,
		bg = beautiful.background,
		fg = beautiful.fg_normal,
	})

	panel.opened = false

	panel:setup({
		layout = wibox.layout.align.horizontal,
		nil,
		{
			id = "panel_content",
			bg = beautiful.transparent,
			widget = wibox.container.background,
			visible = false,
			forced_width = panel_width,
			{
				require("ui.panels.dashboard.pane")(panel),
				layout = wibox.layout.stack,
			},
		},
	})

	function panel:run_rofi()
		awesome.spawn(apps.default.rofi_global, false, false, false, false, function()
			panel:toggle()
		end)

		-- Hide panel content if rofi global search is opened
		panel:get_children_by_id("panel_content")[1].visible = false
	end

	local open_panel = function(should_run_rofi)
		panel.visible = true
		panel:get_children_by_id("panel_content")[1].visible = true
		if should_run_rofi then
			panel:run_rofi()
		end
		panel:emit_signal("opened")
	end

	local close_panel = function()
		panel:get_children_by_id("panel_content")[1].visible = false
		panel.visible = false
		panel:emit_signal("closed")
	end

	function panel:toggle(should_run_rofi)
		self.opened = not self.opened
		if self.opened then
			open_panel(should_run_rofi)
		else
			close_panel()
		end
	end

	return panel
end

return create_dashboard
