local awful = require("awful")
local gears = require("gears")
local wibox = require("wibox")
local beautiful = require("beautiful")

awesome.set_preferred_icon_size(64)

-- Middle-click to close
local tasklist_buttons = gears.table.join(
	awful.button({}, 1, function(c)
		if c == client.focus then
			c.minimized = true
		else
			c:emit_signal("request::activate", "tasklist", { raise = true })
		end
	end),
	awful.button({}, 2, function(c)
		c:kill()
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
					{
						id = "icon_role",
						widget = wibox.widget.imagebox,
					},
					margins = 2,
					widget = wibox.container.margin,
				},
				{
					{
						id = "text_role",
						widget = wibox.widget.textbox,
					},
					left = 2,
					right = 2,
					widget = wibox.container.margin,
				},
				layout = wibox.layout.fixed.horizontal,
			},
			left = 4,
			right = 4,
			top = 1,
			bottom = 1,
			widget = wibox.container.margin,
		},
		id = "background_role",
		widget = wibox.container.background,
	},
	top = 2,
	bottom = 3,
	widget = wibox.container.margin,

	-- Add feedback on hover and focus
	create_callback = function(self, c, index, objects)
		self:get_children_by_id("icon_role")[1].forced_width = 20
		self:get_children_by_id("icon_role")[1].forced_height = 20

		self:connect_signal("mouse::enter", function()
			if c.name then
				awesome.emit_signal("widget::tooltip", {
					text = c.name,
					timeout = 0,
				})
			end
		end)

		-- Update background on focus/unfocus
		local update_callback = function()
			if c == client.focus then
				self:get_children_by_id("background_role")[1].bg = beautiful.tasklist_bg_focus
					or beautiful.bg_focus
					or "#535d6c"
				self:get_children_by_id("text_role")[1].markup = '<span weight="bold">'
					.. (c.name or "Unknown")
					.. "</span>"
			elseif c.urgent then
				self:get_children_by_id("background_role")[1].bg = beautiful.tasklist_bg_urgent
					or beautiful.bg_urgent
					or "#ff0000"
			elseif c.minimized then
				self:get_children_by_id("background_role")[1].bg = beautiful.tasklist_bg_minimize
					or beautiful.bg_minimize
					or "#444444"
				self:get_children_by_id("text_role")[1].opacity = 0.6
			else
				self:get_children_by_id("background_role")[1].bg = beautiful.tasklist_bg_normal
					or beautiful.bg_normal
					or "#222222"
				self:get_children_by_id("text_role")[1].opacity = 1.0
			end
		end

		update_callback()
		c:connect_signal("property::minimized", update_callback)
		c:connect_signal("focus", update_callback)
		c:connect_signal("unfocus", update_callback)
	end,
}

local function tasklist(s)
	return awful.widget.tasklist({
		screen = s,
		filter = awful.widget.tasklist.filter.currenttags,
		buttons = tasklist_buttons,
		layout = {
			spacing = 2,
			layout = wibox.layout.fixed.horizontal,
		},
		widget_template = widget_template_tasklist,
		-- Limit text length to prevent overflow
		style = {
			shape = gears.shape.rounded_rect,
		},
	})
end

return tasklist
