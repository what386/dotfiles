local awful = require("awful")
local wibox = require("wibox")
local gears = require("gears")
local beautiful = require("beautiful")
local dpi = beautiful.xresources.apply_dpi
panel_visible = false

local format_item = function(widget)
	return wibox.widget({
		{
			{
				layout = wibox.layout.align.vertical,
				expand = "none",
				nil,
				widget,
				nil,
			},
			margins = dpi(10),
			widget = wibox.container.margin,
		},
		forced_height = dpi(88),
		bg = beautiful.groups_bg,
		shape = function(cr, width, height)
			gears.shape.rounded_rect(cr, width, height, beautiful.groups_radius)
		end,
		widget = wibox.container.background,
	})
end

local format_item_no_fix_height = function(widget)
	return wibox.widget({
		{
			{
				layout = wibox.layout.align.vertical,
				expand = "none",
				nil,
				widget,
				nil,
			},
			margins = dpi(10),
			widget = wibox.container.margin,
		},
		bg = beautiful.groups_bg,
		shape = function(cr, width, height)
			gears.shape.rounded_rect(cr, width, height, beautiful.groups_radius)
		end,
		widget = wibox.container.background,
	})
end

local vertical_separator = wibox.widget({
	orientation = "vertical",
	forced_height = dpi(1),
	forced_width = dpi(1),
	span_ratio = 0.55,
	widget = wibox.widget.separator,
})

local control_center_row_one = wibox.widget({
	layout = wibox.layout.align.horizontal,
	forced_height = dpi(55),
	nil,
	format_item(require("ui.panels.dashboard.user-profile")()),
	{
		format_item({
			layout = wibox.layout.fixed.horizontal,
			spacing = dpi(10),
			require("ui.panels.dashboard.switch")(),
			vertical_separator,
			require("ui.panels.dashboard.end-session")(),
		}),
		left = dpi(10),
		widget = wibox.container.margin,
	},
})

local main_control_row_two = wibox.widget({
	layout = wibox.layout.flex.horizontal,
	spacing = dpi(10),
	format_item_no_fix_height({
		layout = wibox.layout.fixed.vertical,
		spacing = dpi(5),
		require("ui.panels.dashboard.settings.airplane-toggle"),
		require("ui.panels.dashboard.settings.bluetooth-toggle"),
		require("ui.panels.dashboard.settings.redshift-toggle"),
		require("ui.panels.dashboard.settings.autobacklight-toggle"),
	}),
	{
		layout = wibox.layout.flex.vertical,
		spacing = dpi(10),
		format_item_no_fix_height({
			layout = wibox.layout.align.vertical,
			expand = "none",
			nil,
			require("ui.panels.dashboard.settings.dont-disturb-toggle"),
			nil,
		}),
		format_item_no_fix_height({
			layout = wibox.layout.align.vertical,
			expand = "none",
			nil,
			require("ui.panels.dashboard.settings.blur-toggle"),
			nil,
		}),
	},
})

local main_control_row_sliders = wibox.widget({
	layout = wibox.layout.fixed.vertical,
	spacing = dpi(10),
	format_item({
		require("ui.panels.dashboard.settings.blur-slider"),
		margins = dpi(10),
		widget = wibox.container.margin,
	}),
	format_item({
		require("ui.panels.dashboard.settings.brightness-slider"),
		margins = dpi(10),
		widget = wibox.container.margin,
	}),
	format_item({
		require("ui.panels.dashboard.settings.volume-slider"),
		margins = dpi(10),
		widget = wibox.container.margin,
	}),
	format_item({
		require("ui.panels.dashboard.settings.microphone-slider"),
		margins = dpi(10),
		widget = wibox.container.margin,
	}),
})

local monitor_control_row_progressbars = wibox.widget({
	layout = wibox.layout.fixed.vertical,
	spacing = dpi(10),
	format_item(require("ui.panels.dashboard.sys-monitor.cpu-usage")),
	format_item(require("ui.panels.dashboard.sys-monitor.gpu-usage")),
	format_item(require("ui.panels.dashboard.sys-monitor.ram-usage")),
	format_item(require("ui.panels.dashboard.sys-monitor.disk-usage")),
	format_item(require("ui.panels.dashboard.sys-monitor.fan-meter")),
	format_item(require("ui.panels.dashboard.sys-monitor.temp-meter")),
})

local dashboard = function(s)
	-- Set the control center geometry
	local panel_width = dpi(550)
	local panel_margins = dpi(15)

	local panel = awful.popup({
		widget = {
			{
				{
					layout = wibox.layout.fixed.vertical,
					spacing = dpi(10),
					control_center_row_one,
					{
						layout = wibox.layout.stack,
						{
							id = "main_control",
							visible = true,
							layout = wibox.layout.fixed.vertical,
							spacing = dpi(10),
							main_control_row_two,
							main_control_row_sliders,
						},
						{
							id = "monitor_control",
							visible = false,
							layout = wibox.layout.fixed.vertical,
							spacing = dpi(10),
							monitor_control_row_progressbars,
						},
					},
				},
				margins = dpi(16),
				widget = wibox.container.margin,
			},
			id = "dashboard",
			bg = beautiful.background,
			shape = function(cr, w, h)
				gears.shape.rounded_rect(cr, w, h, beautiful.groups_radius)
			end,
			widget = wibox.container.background,
		},
		screen = s,
		type = "dock",
		visible = false,
		ontop = true,
		width = dpi(panel_width),
		maximum_width = dpi(panel_width),
		maximum_height = dpi(s.geometry.height - 38),
		bg = beautiful.transparent,
		fg = beautiful.fg_normal,
		shape = gears.shape.rectangle,
	})

	awful.placement.top_left(panel, {
		honor_workarea = true,
		parent = s,
		margins = {
			top = dpi(36) + panel_margins,
			left = panel_margins,
		},
	})

	panel.opened = false

	s.backdrop_dashboard = wibox({
		ontop = true,
		screen = s,
		bg = beautiful.transparent,
		type = "utility",
		x = s.geometry.x,
		y = s.geometry.y,
		width = s.geometry.width,
		height = s.geometry.height,
	})

	local open_panel = function()
		local focused = awful.screen.focused()
		panel_visible = true

		focused.backdrop_dashboard.visible = true
		focused.dashboard.visible = true

		panel:emit_signal("opened")
	end

	local close_panel = function()
		local focused = awful.screen.focused()
		panel_visible = false

		focused.dashboard.visible = false
		focused.backdrop_dashboard.visible = false

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

	s.backdrop_dashboard:buttons(awful.util.table.join(awful.button({}, 1, nil, function()
		panel:toggle()
	end)))

	return panel
end

return dashboard
