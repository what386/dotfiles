local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("beautiful")

require("theme.wallpapers.dynamic-wallpaper")

local function set_wallpaper(s)
	if not beautiful.wallpaper then
		return
	end

	local wallpaper = beautiful.wallpaper

	-- If wallpaper is a function, call it with the screen
	if type(wallpaper) == "function" then
		wallpaper = wallpaper(s)
	end
	if type(wallpaper) == "string" then
		-- Check if it's a color (starts with #) or image path
		if wallpaper:sub(1, 1) == "#" then
			awful.wallpaper({ screen = s, bg = wallpaper })
		else
			-- Assume it's an image path
			awful.wallpaper({
				screen = s,
				widget = {
					image = wallpaper,
					horizontal_fit_policy = "fit",
					vertical_fit_policy = "fit",
					widget = wibox.widget.imagebox,
				},
			})
		end
	end
end

screen.connect_signal("property::geometry", set_wallpaper)
screen.connect_signal("request::wallpaper", set_wallpaper)
