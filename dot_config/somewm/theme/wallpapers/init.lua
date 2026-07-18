local gears = require("gears")
local beautiful = require("beautiful")

-- Re-set wallpaper when a screen's geometry changes (e.g. different resolution)
screen.connect_signal("property::geometry", function(s)
	local wallpaper = beautiful.wallpaper

	if type(wallpaper) == "function" then
		wallpaper = wallpaper(s)
	end
	gears.wallpaper.maximized(wallpaper, s, true)
end)

-- Set wallpaper when requested
screen.connect_signal("request::wallpaper", function(s)
	if not beautiful.wallpaper then
		return
	end

	local wallpaper = beautiful.wallpaper

	-- If wallpaper is a function, call it with the screen
	if type(wallpaper) == "function" then
		wallpaper(s)
	elseif type(wallpaper) == "string" then
		-- Check if it's a color (starts with #) or image path
		if wallpaper:sub(1, 1) == "#" then
			gears.wallpaper.set(wallpaper)
		else
			-- Assume it's an image path
			gears.wallpaper.maximized(wallpaper, s, true)
		end
	end
end)

require("theme.wallpapers.dynamic-wallpaper")

-- The dynamic module selects the current image during startup, before Awesome
-- has finished creating all screens. Re-apply it on the next main-loop turn.
gears.timer.delayed_call(function()
	local wallpaper = beautiful.wallpaper
	if type(wallpaper) ~= "string" then
		return
	end

	for s in screen do
		gears.wallpaper.maximized(wallpaper, s, true)
	end
end)
