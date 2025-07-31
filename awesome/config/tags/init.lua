local awful = require("awful")
local gears = require("gears")
local beautiful = require("beautiful")
local icons = require("theme.icons")
local apps = require("config.user.preferences")

local tags = {
	{
		type = "terminal",
		icon = icons.tags.terminal,
		default_app = apps.default.terminal,
		gap = beautiful.useless_gap,
	},
	{
		type = "internet",
		icon = icons.tags.web_browser,
		default_app = apps.default.web_browser,
		gap = beautiful.useless_gap,
	},
	{
		type = "files",
		icon = icons.tags.file_manager,
		default_app = apps.default.file_manager,
		gap = beautiful.useless_gap,
		layout = awful.layout.suit.tile,
	},
	{
		type = "text",
		icon = icons.tags.text_editor,
		default_app = apps.default.text_editor,
		gap = beautiful.useless_gap,
	},
	{
		type = "multimedia",
		icon = icons.tags.multimedia,
		default_app = apps.default.multimedia,
		gap = beautiful.useless_gap,
		layout = awful.layout.suit.floating,
	},
	{
		type = "graphics",
		icon = icons.tags.graphics,
		default_app = apps.default.graphics,
		gap = beautiful.useless_gap,
	},
	{
		type = "sandbox",
		icon = icons.tags.sandbox,
		default_app = apps.default.sandbox,
		layout = awful.layout.suit.max,
		gap = 0,
	},

	{
		type = "messaging",
		icon = icons.tags.social,
		default_app = "vesktop",
		gap = beautiful.useless_gap,
	},
	{
		type = "mail",
		icon = icons.tags.mail,
		default_app = "betterbird",
		gap = beautiful.useless_gap,
	},
	{
		type = "music",
		icon = icons.tags.music,
		default_app = "youtube",
		gap = beautiful.useless_gap,
		layout = awful.layout.suit.floating,
	},
}

-- Set tags layout
tag.connect_signal("request::default_layouts", function()
	awful.layout.append_default_layouts({
		awful.layout.suit.spiral.dwindle,
		awful.layout.suit.tile,
		awful.layout.suit.floating,
		awful.layout.suit.max,
	})
end)

-- Create tags for each screen
screen.connect_signal("request::desktop_decoration", function(s)
	for i, tag in pairs(tags) do
		awful.tag.add(i, {
			icon = tag.icon,
			icon_only = true,
			layout = tag.layout or awful.layout.suit.spiral.dwindle,
			gap_single_client = true,
			gap = tag.gap,
			screen = s,
			default_app = tag.default_app,
			selected = i == 1,
		})
	end
end)

local update_gap_and_shape = function(t)
	-- Get current tag layout
	local current_layout = awful.tag.getproperty(t, "layout")
	-- If the current layout is awful.layout.suit.max
	if current_layout == awful.layout.suit.max then
		-- Set clients gap to 0 and shape to rectangle if maximized
		t.gap = 0
		for _, c in ipairs(t:clients()) do
			if not c.floating or not c.round_corners or c.maximized or c.fullscreen then
				c.shape = beautiful.client_shape_rectangle
			else
				c.shape = beautiful.client_shape_rounded
			end
		end
	else
		t.gap = beautiful.useless_gap
		for _, c in ipairs(t:clients()) do
			if not c.round_corners or c.maximized or c.fullscreen then
				c.shape = beautiful.client_shape_rectangle
			else
				c.shape = beautiful.client_shape_rounded
			end
		end
	end
end

-- Change tag's client's shape and gap on change
tag.connect_signal("property::layout", function(t)
	update_gap_and_shape(t)
end)

-- Change tag's client's shape and gap on move to tag
tag.connect_signal("tagged", function(t)
	update_gap_and_shape(t)
end)

-- Focus on urgent clients
awful.tag.attached_connect_signal(s, "property::selected", function()
	local urgent_clients = function(c)
		return awful.rules.match(c, { urgent = true })
	end
	for c in awful.client.iterate(urgent_clients) do
		if c.first_tag == mouse.screen.selected_tag then
			c:emit_signal("request::activate")
			c:raise()
		end
	end
end)
