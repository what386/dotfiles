local awful = require("awful")

local modkey = "Mod4"
local alt = "Mod1"

-- Client
client.connect_signal("request::default_keybindings", function()
	awful.keyboard.append_client_keybindings({
		awful.key({ modkey, "Shift" }, "h", function()
			awful.client.swap.bydirection("left")
		end, { description = "swap left", group = "client" }),
		awful.key({ modkey, "Shift" }, "l", function()
			awful.client.swap.bydirection("right")
		end, { description = "swap right", group = "client" }),
		awful.key({ modkey, "Shift" }, "j", function()
			awful.client.swap.bydirection("down")
		end, { description = "swap down", group = "client" }),
		awful.key({ modkey, "Shift" }, "k", function()
			awful.client.swap.bydirection("up")
		end, { description = "swap up", group = "client" }),
		awful.key({ modkey }, "j", function()
			awful.client.focus.bydirection("down")
		end, { description = "focus down", group = "client" }),
		awful.key({ modkey }, "k", function()
			awful.client.focus.bydirection("up")
		end, { description = "focus up", group = "client" }),
		awful.key({ modkey }, "l", function()
			awful.client.focus.bydirection("right")
		end, { description = "focus right", group = "client" }),
		awful.key({ modkey }, "h", function()
			awful.client.focus.bydirection("left")
		end, { description = "focus left", group = "client" }),
		awful.key({ modkey }, "f", function(c)
			c.fullscreen = not c.fullscreen
			c:raise()
		end, { description = "toggle fullscreen", group = "client" }),

		awful.key({ modkey }, "q", function(c)
			c:kill()
		end, { description = "close", group = "client" }),

		awful.key(
			{ modkey, "Control" },
			"space",
			awful.client.floating.toggle,
			{ description = "toggle floating", group = "client" }
		),

		awful.key({ modkey, "Control" }, "Return", function(c)
			c:swap(awful.client.getmaster())
		end, { description = "move to master", group = "client" }),

		awful.key({ modkey }, "o", function(c)
			c:move_to_screen()
		end, { description = "move to screen", group = "client" }),

		awful.key({ modkey }, "n", function(c)
			-- The client currently has the input focus, so it cannot be
			-- minimized, since minimized clients can't have the focus.
			c.minimized = true
		end, { description = "minimize", group = "client" }),
		awful.key({ modkey }, "m", function(c)
			c.maximized = not c.maximized
			c:raise()
		end, { description = "(un)maximize", group = "client" }),
		awful.key({ modkey, "Control" }, "m", function(c)
			c.maximized_vertical = not c.maximized_vertical
			c:raise()
		end, { description = "(un)maximize vertically", group = "client" }),
		awful.key({ modkey, "Shift" }, "m", function(c)
			c.maximized_horizontal = not c.maximized_horizontal
			c:raise()
		end, { description = "(un)maximize horizontally", group = "client" }),
		awful.key({ modkey }, "Tab", function()
			awful.client.focus.history.previous()
			if client.focus then
				client.focus:raise()
			end
		end, { description = "go back", group = "client" }),
		awful.key({ modkey, "Control" }, "n", function()
			local c = awful.client.restore()
			-- Focus restored client
			--if c then
			--    c:activate { raise = true, context = "key.unminimize" }
			--end
			if c then
				c:emit_signal("request::activate", "key.unminimize", { raise = true })
			end
		end, { description = "restore minimized", group = "client" }),
	})
end)
