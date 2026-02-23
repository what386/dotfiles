-- Required libraries
local awful = require("awful")
local gears = require("gears")

-- Root window mouse bindings
root.buttons(gears.table.join(
	-- Right-click on the desktop to toggle the main menu
	awful.button({}, 3, function()
		mymainmenu:toggle()
	end),

	-- Scroll up / down to view previous / next tag
	awful.button({}, 4, awful.tag.viewnext),
	awful.button({}, 5, awful.tag.viewprev)
))
