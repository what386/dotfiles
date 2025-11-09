local gears = require("gears")
local awful = require("awful")
local beautiful = require("beautiful")

-- set wallpaper on request
if beautiful.wallpaper then
	local wallpaper = beautiful.wallpaper
	-- If wallpaper is a function, call it with the screen
	if type(wallpaper) == "function" then
		wallpaper = wallpaper(s)
	end
	gears.wallpaper.maximized(wallpaper, s, true)
end

gears.wallpaper.maximized(beautiful.wallpaper, s, true)

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

--require("theme.wallpapers.dynamic-wallpaper")
