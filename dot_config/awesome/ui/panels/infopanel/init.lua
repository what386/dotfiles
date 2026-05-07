local wibox = require("wibox")
local awful = require("awful")
local beautiful = require("beautiful")
local gears = require("gears")
local rubato = require("dependencies.rubato")
local dpi = beautiful.xresources.apply_dpi
panel_visible = false

local infopanel = function(s)
	-- Set right panel geometry
	local panel_width = dpi(290)
	local panel_x = s.geometry.x + s.geometry.width - panel_width
	local hidden_x = s.geometry.x + s.geometry.width + dpi(8)

	local panel = wibox({
		ontop = true,
		screen = s,
		visible = false,
		type = "dock",
		width = panel_width,
		height = s.geometry.height - dpi(36) + 1,
		x = panel_x,
		y = s.geometry.y + dpi(36) - 1,
		bg = beautiful.background,
		fg = beautiful.fg_normal,
	})

	panel.opened = false
	panel.opacity = 0
	panel.x = hidden_x
	local animation_token = 0

	local slide_anim = rubato.timed({
		rate = 60,
		intro = 0.08,
		outro = 0.12,
		duration = 0.22,
		easing = rubato.easing.quadratic,
		subscribed = function(pos)
			panel.x = pos
		end,
	})

	local fade_anim = rubato.timed({
		rate = 60,
		intro = 0.06,
		outro = 0.1,
		duration = 0.16,
		easing = rubato.easing.linear,
		subscribed = function(opacity)
			panel.opacity = opacity
		end,
	})

	s.backdrop_rdb = wibox({
		ontop = true,
		screen = s,
		bg = beautiful.transparent,
		type = "utility",
		x = s.geometry.x,
		y = s.geometry.y,
		width = s.geometry.width,
		height = s.geometry.height,
	})

	panel:struts({
		right = 0,
	})

	local open_panel = function()
		local focused = awful.screen.focused()
		animation_token = animation_token + 1
		panel_visible = true

		focused.backdrop_rdb.visible = true
		focused.infopanel.visible = true
		focused.infopanel.x = hidden_x
		focused.infopanel.opacity = 0
		slide_anim.target = panel_x
		fade_anim.target = 1

		panel:emit_signal("opened")
	end

	local close_panel = function()
		local focused = awful.screen.focused()
		animation_token = animation_token + 1
		local token = animation_token
		panel_visible = false

		slide_anim.target = hidden_x
		fade_anim.target = 0
		gears.timer({
			timeout = 0.24,
			autostart = true,
			single_shot = true,
			callback = function()
				if token == animation_token then
					focused.infopanel.visible = false
					focused.backdrop_rdb.visible = false
				end
			end,
		})

		panel:emit_signal("closed")
	end

	-- Hide this panel when app dashboard is called.
	function panel:hide_dashboard()
		close_panel()
	end

	function panel:toggle()
		self.opened = not self.opened
		if self.opened then
			open_panel()
		else
			close_panel()
		end
	end

	function panel:switch_pane(mode)
		if mode == "notif_mode" then
			-- Update Content
			panel:get_children_by_id("notif_id")[1].visible = true
			panel:get_children_by_id("pane_id")[1].visible = false
		elseif mode == "today_mode" then
			-- Update Content
			panel:get_children_by_id("notif_id")[1].visible = false
			panel:get_children_by_id("pane_id")[1].visible = true
		end
	end

	s.backdrop_rdb:buttons(awful.util.table.join(awful.button({}, 1, function()
		panel:toggle()
	end)))

	local separator = wibox.widget({
		orientation = "horizontal",
		opacity = 0.0,
		forced_height = 15,
		widget = wibox.widget.separator,
	})

	local line_separator = wibox.widget({
		orientation = "horizontal",
		forced_height = dpi(1),
		span_ratio = 1.0,
		color = beautiful.groups_title_bg,
		widget = wibox.widget.separator,
	})

	panel:setup({
		{
			expand = "none",
			layout = wibox.layout.fixed.vertical,
			{
				layout = wibox.layout.align.horizontal,
				expand = "none",
				nil,
				require("ui.panels.infopanel.info-center-switch"),
				nil,
			},
			separator,
			line_separator,
			separator,
			{
				layout = wibox.layout.stack,
				-- Today Pane
				{
					id = "pane_id",
					visible = true,
					layout = wibox.layout.fixed.vertical,
					{
						layout = wibox.layout.fixed.vertical,
						spacing = dpi(7),
						require("ui.panels.infopanel.user-profile"),
						require("ui.panels.infopanel.agenda"),
						require("ui.panels.infopanel.weather"),
						require("ui.panels.infopanel.calculator"),
					},
				},
				-- Notification Center
				{
					id = "notif_id",
					visible = false,
					--require("widget.notif-center"),
					require("ui.panels.infopanel.notif-center")(s),
					layout = wibox.layout.fixed.vertical,
				},
			},
		},
		margins = dpi(16),
		widget = wibox.container.margin,
	})

	return panel
end

return infopanel
