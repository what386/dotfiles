local beautiful = require("beautiful")

-- autofocus urgent windows
client.connect_signal("property::urgent", function(c)
	if not c.urgent or c.hidden or not c.screen then return end
	c.minimized = false
	c:jump_to()
end)

-- set focus borders
client.connect_signal("focus", function(c)
	c.border_color = beautiful.border_focus
end)
client.connect_signal("unfocus", function(c)
	c.border_color = beautiful.border_normal
end)
