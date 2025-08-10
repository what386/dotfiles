-- Dependency: xdotool
--
-- Usage:
-- 1. Save as "virtual_keyboard.lua" in ~/.config/awesome/
-- 2. Toggle by using: awesome.emit_signal("module::virtual_keyboard:toggle")
local awful = require("awful")
local wibox = require("wibox")
local dpi = require("beautiful").xresources.apply_dpi
local gears = require("gears")
local key_size = dpi(66)
local mod_fg_color = "#A9DD9D"
local mod_bg_color = "#2B373E"
local accent_fg_color = "#2B373E"
local accent_bg_color = "#A9DD9D"
local press_fg_color = "#2B373E"
local press_bg_color = "#A1BFCF"
local virtual_keyboard = {}
local current_bar = nil
local keyboard_visible = false -- Track visibility state

-- Function to get current screen geometry
local function get_screen_geometry()
	local focused_screen = awful.screen.focused()
	local screen_geom = focused_screen.workarea
	return {
		screen = focused_screen,
		workarea = screen_geom,
		screen_height = screen_geom.height,
		screen_width = screen_geom.width,
	}
end

local function button(attributes)
	local attr = attributes or {}
	attr.togglable = attr.toggleable or false
	attr.size = attr.size or 1.0
	attr.name = attr.name or ""
	attr.keycode = attr.keycode or attr.name or nil
	attr.bg = attr.bg or "#2B373E"
	attr.fg = attr.fg or "#A1BFCF"
	attr.spacing = attr.spacing or dpi(3)
	local textbox = wibox.widget.textbox(attr.name)
	textbox.font = "Terminus 12"
	local box = wibox.widget.base.make_widget_declarative({
		{
			{
				{
					{
						textbox,
						fill_vertical = false,
						fill_horizontal = false,
						valign = true,
						halign = true,
						widget = wibox.container.place,
					},
					widget = wibox.container.margin,
				},
				id = "bg",
				opacity = (string.len(attr.name) == 0) and 0 or 1,
				fg = attr.fg,
				bg = attr.bg,
				widget = wibox.container.background,
			},
			right = attr.spacing,
			top = attr.spacing,
			forced_height = key_size,
			forced_width = key_size * attr.size,
			widget = wibox.container.margin,
		},
		widget = wibox.container.background,
		bg = "#56666f",
	})
	local boxbg = box:get_children_by_id("bg")[1]
	boxbg:connect_signal("button::press", function()
		if not attr.keycode then
			awful.spawn("xdotool key " .. attr.name)
		else
			awful.spawn("xdotool key " .. attr.keycode)
		end
		boxbg.bg = press_bg_color
		boxbg.fg = press_fg_color
		awful.spawn.easy_async_with_shell("sleep 0.3", function()
			boxbg.bg = attr.bg
			boxbg.fg = attr.fg
		end)
	end)
	return box
end

-- Function to create the keyboard layout
local function create_keyboard_layout()
	return {
		widget = wibox.container.margin,
		{
			widget = wibox.container.background,
			{
				layout = wibox.layout.fixed.vertical,
				spacing = 0,
				{
					layout = wibox.layout.align.horizontal,
					expand = "none",
					{ layout = wibox.layout.fixed.horizontal },
					{
						layout = wibox.layout.grid,
						orientation = "horizontal",
						horizontal_expand = false,
						homogeneous = false,
						spacing = 0,
						forced_height = key_size,
						button({
							name = "Esc",
							keycode = "Escape",
							fg = accent_fg_color,
							bg = accent_bg_color,
						}),
						button({ name = "1" }),
						button({ name = "2" }),
						button({ name = "3" }),
						button({ name = "4" }),
						button({ name = "5" }),
						button({ name = "6" }),
						button({ name = "7" }),
						button({ name = "8" }),
						button({ name = "9" }),
						button({ name = "0" }),
						button({ name = "-", keycode = "minus" }),
						button({ name = "=", keycode = "equal" }),
						button({
							name = "Backspace",
							size = 2.0,
							keycode = "BackSpace",
							fg = mod_fg_color,
							bg = mod_bg_color,
						}),
					},
					{ layout = wibox.layout.fixed.horizontal },
				},
				{
					layout = wibox.layout.align.horizontal,
					expand = "none",
					{ layout = wibox.layout.fixed.horizontal },
					{
						layout = wibox.layout.grid,
						orientation = "horizontal",
						horizontal_expand = false,
						homogeneous = false,
						spacing = 0,
						forced_height = key_size,
						button({
							name = "Tab",
							size = 1.5,
							keycode = "Tab",
							fg = mod_fg_color,
							bg = mod_bg_color,
						}),
						button({ name = "q" }),
						button({ name = "w" }),
						button({ name = "e" }),
						button({ name = "r" }),
						button({ name = "t" }),
						button({ name = "y" }),
						button({ name = "u" }),
						button({ name = "i" }),
						button({ name = "o" }),
						button({ name = "p" }),
						button({ name = "[", keycode = "bracketleft" }),
						button({ name = "]", keycode = "bracketright" }),
						button({
							name = "\\",
							size = 1.5,
							keycode = "backslash",
							fg = mod_fg_color,
							bg = mod_bg_color,
						}),
					},
					{ layout = wibox.layout.fixed.horizontal },
				},
				{
					layout = wibox.layout.align.horizontal,
					expand = "none",
					{ layout = wibox.layout.fixed.horizontal },
					{
						layout = wibox.layout.grid,
						orientation = "horizontal",
						horizontal_expand = false,
						homogeneous = false,
						spacing = 0,
						button({
							name = "Caps",
							size = 1.75,
							keycode = "Caps_Lock",
							fg = mod_fg_color,
							bg = mod_bg_color,
						}),
						button({ name = "a" }),
						button({ name = "s" }),
						button({ name = "d" }),
						button({ name = "f" }),
						button({ name = "g" }),
						button({ name = "h" }),
						button({ name = "j" }),
						button({ name = "k" }),
						button({ name = "l" }),
						button({ name = ";", keycode = "semicolon" }),
						button({ name = "'", keycode = "apostrophe" }),
						button({
							name = "Enter",
							size = 2.25,
							keycode = "Return",
							fg = accent_fg_color,
							bg = accent_bg_color,
						}),
					},
					{ layout = wibox.layout.fixed.horizontal },
				},
				{
					layout = wibox.layout.align.horizontal,
					expand = "none",
					{ layout = wibox.layout.fixed.horizontal },
					{
						layout = wibox.layout.grid,
						orientation = "horizontal",
						horizontal_expand = false,
						homogeneous = false,
						spacing = 0,
						button({
							name = "Shift",
							size = 2.25,
							keycode = "Shift_Lock",
							fg = mod_fg_color,
							bg = mod_bg_color,
						}),
						button({ name = "z" }),
						button({ name = "x" }),
						button({ name = "c" }),
						button({ name = "v" }),
						button({ name = "b" }),
						button({ name = "n" }),
						button({ name = "m" }),
						button({ name = ",", keycode = "comma" }),
						button({ name = ".", keycode = "period" }),
						button({ name = "/", keycode = "slash" }),
						button({
							name = "Shift",
							size = 2.75,
							fg = mod_fg_color,
							bg = mod_bg_color,
						}),
					},
					{ layout = wibox.layout.fixed.horizontal },
				},
				{
					layout = wibox.layout.align.horizontal,
					expand = "none",
					{ layout = wibox.layout.fixed.horizontal },
					{
						layout = wibox.layout.grid,
						orientation = "horizontal",
						horizontal_expand = false,
						homogeneous = false,
						spacing = 0,
						button({
							name = "Ctrl",
							keycode = "Control_L",
							size = 1.25,
							fg = mod_fg_color,
							bg = mod_bg_color,
						}),
						button({
							name = "Win",
							keycode = "Super_L",
							size = 1.25,
							fg = mod_fg_color,
							bg = mod_bg_color,
						}),
						button({
							name = "Alt",
							keycode = "Alt_L",
							size = 1.25,
							fg = mod_fg_color,
							bg = mod_bg_color,
						}),
						button({
							name = " ",
							size = 6.25,
							keycode = "space",
						}),
						button({
							name = "Alt",
							keycode = "Alt_R",
							size = 1.25,
							fg = mod_fg_color,
							bg = mod_bg_color,
						}),
						button({
							name = "Win",
							keycode = "Super_R",
							size = 1.25,
							fg = mod_fg_color,
							bg = mod_bg_color,
						}),
						button({
							name = "Menu",
							keycode = "Hyper_R",
							size = 1.25,
							fg = mod_fg_color,
							bg = mod_bg_color,
						}),
						button({
							name = "Ctrl",
							keycode = "Ctrl_R",
							size = 1.25,
							fg = mod_fg_color,
							bg = mod_bg_color,
						}),
					},
					{ layout = wibox.layout.fixed.horizontal },
				},
			},
		},
	}
end

-- Function to create or update the keyboard bar for current screen
local function create_keyboard_bar()
	local geom = get_screen_geometry()
	local keyboard_height = 5 * key_size

	-- Clean up existing bar if it exists
	if current_bar then
		current_bar.visible = false
		current_bar = nil
	end

	-- Create new bar on focused screen
	current_bar = awful.wibar({
		position = "bottom",
		screen = geom.screen,
		height = keyboard_height,
		bg = "#56666f",
		visible = false,
	})

	current_bar:setup(create_keyboard_layout())
	return current_bar
end

-- Show/hide function
local function show_keyboard(show)
	if not current_bar then
		create_keyboard_bar()
	end

	local geom = get_screen_geometry()

	-- Make sure keyboard is on the right screen
	if current_bar.screen ~= geom.screen then
		create_keyboard_bar()
	end

	-- Simply show or hide the keyboard
	current_bar.visible = show
	keyboard_visible = show
end

-- Toggle function
local function toggle()
	if not current_bar then
		show_keyboard(true)
	else
		show_keyboard(not keyboard_visible)
	end
end

-- Connect to toggle signal
awesome.connect_signal("flyout::osd_keyboard:toggle", function()
	toggle()
end)
