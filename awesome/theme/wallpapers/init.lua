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

screen.connect_signal("request::wallpaper", function(s)
	-- If wallpaper is a function, call it with the screen
	if beautiful.wallpaper then
		if type(beautiful.wallpaper) == "string" then
			-- Check if beautiful.wallpaper is color/image
			if beautiful.wallpaper:sub(1, #"#") == "#" then
				-- If beautiful.wallpaper is color
				gears.wallpaper.set(beautiful.wallpaper)
			elseif beautiful.wallpaper:sub(1, #"/") == "/" then
				-- If beautiful.wallpaper is path/image
				gears.wallpaper.maximized(beautiful.wallpaper, s)
			end
		else
			beautiful.wallpaper(s)
		end
	end
end)

--require("theme.wallpapers.dynamic-wallpaper")
