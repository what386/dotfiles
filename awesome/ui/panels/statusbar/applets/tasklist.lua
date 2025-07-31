awful = require("awful")
gears = require("gears")
wibox = require("wibox")

awesome.set_preferred_icon_size(64)

local tasklist_buttons = gears.table.join(
	awful.button({}, 1, function(c)
		if c == client.focus then
			c.minimized = true
		else
			c:emit_signal("request::activate", "tasklist", { raise = true })
		end
	end),
	awful.button({}, 3, function()
		awful.menu.client_list({ theme = { width = 250 } })
	end),
	awful.button({}, 4, function()
		awful.client.focus.byidx(1)
	end),
	awful.button({}, 5, function()
		awful.client.focus.byidx(-1)
	end)
)

local widget_template_tasklist = {
	{
		{
			{
				{
					id = "icon_role",
					widget = wibox.widget.imagebox,
				},
				margins = 1,
				widget = wibox.container.margin,
			},
			--{
			--	id     = 'text_role',
			--	widget = wibox.widget.textbox,
			--},
			layout = wibox.layout.fixed.horizontal,
		},
		left = 2,
		right = 2,
		top = 2,
		bottom = 2,
		widget = wibox.container.margin,
	},
	id = "background_role",
	widget = wibox.container.background,
}

local function tasklist(s)
	-- Create a tasklist widget
	return awful.widget.tasklist({
		screen = s,
		filter = awful.widget.tasklist.filter.currenttags,
		buttons = tasklist_buttons,
		layout = wibox.layout.fixed.horizontal(),
		widget_template = widget_template_tasklist,
	})
end

return tasklist
