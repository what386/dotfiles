local awful = require("awful")
local wibox = require("wibox")
local gears = require("gears")
local beautiful = require("beautiful")
local dpi = beautiful.xresources.apply_dpi
local clickable_container = require("ui.clickable-container")
local icons = require("theme.icons")

return function(panel)
	local search_widget = wibox.widget({
		{
			{
				{
					image = icons.system.search,
					resize = true,
					widget = wibox.widget.imagebox,
				},
				top = dpi(12),
				bottom = dpi(12),
				widget = wibox.container.margin,
			},
			{
				text = "Global Search",
				font = "Inter Regular 12",
				align = "left",
				valign = "center",
				widget = wibox.widget.textbox,
			},
			spacing = dpi(24),
			layout = wibox.layout.fixed.horizontal,
		},
		left = dpi(24),
		right = dpi(24),
		forced_height = dpi(48),
		widget = wibox.container.margin,
	})

	local search_button = wibox.widget({
		{
			search_widget,
			widget = clickable_container,
		},
		bg = beautiful.groups_bg,
		shape = function(cr, width, height)
			gears.shape.rounded_rect(cr, width, height, beautiful.groups_radius)
		end,
		widget = wibox.container.background,
	})

	search_button:buttons(awful.util.table.join(awful.button({}, 1, function()
		panel:run_rofi()
	end)))

	return wibox.widget({
		{
			{
				layout = wibox.layout.fixed.vertical,
				spacing = dpi(5),
				search_button,
				require("ui.panels.dashboard.hardware-monitor"),
				require("ui.panels.dashboard.quick-settings"),
			},
			nil,
			require("ui.panels.dashboard.end-session"),
			layout = wibox.layout.align.vertical,
		},
		margins = { top = dpi(6), bottom = dpi(16), left = dpi(16), right = dpi(16) },
		widget = wibox.container.margin,
	})
end
