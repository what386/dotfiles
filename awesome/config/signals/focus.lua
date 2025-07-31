beautiful = require("beautiful")

-- autofocus urgent windows
client.connect_signal("property::urgent", function(c)
    c.minimized = false
    c:jump_to()
end)

-- make focus follow mouse (sloppy focus)
client.connect_signal("mouse::enter", function(c)
    c:activate({ context = "mouse_enter", raise = false })
end)

-- set focus borders
client.connect_signal("focus", function(c)
    c.border_color = beautiful.border_focus
end)
client.connect_signal("unfocus", function(c)
    c.border_color = beautiful.border_normal
end)
