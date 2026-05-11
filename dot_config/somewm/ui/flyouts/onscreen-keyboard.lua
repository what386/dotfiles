-- Dependency: xdotool
--
-- Usage:
-- 1. Save as "virtual_keyboard.lua" in ~/.config/awesome/
-- 2. Toggle by using: awesome.emit_signal("module::virtual_keyboard:toggle")
local awful = require("awful")
local wibox = require("wibox")
local dpi = require("beautiful").xresources.apply_dpi
local gears = require("gears")
local key_size = dpi(50) -- Reduced size for more compact layout
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
	attr.spacing = attr.spacing or dpi(2)

	local textbox = wibox.widget.textbox(attr.name)
	textbox.font = "Terminus 10"
	textbox.align = "center"
	textbox.valign = "center"

	local box = wibox.widget.base.make_widget_declarative({
		{
			{
				{
					textbox,
					widget = wibox.container.place,
				},
				margins = dpi(2),
				widget = wibox.container.margin,
			},
			id = "bg",
			opacity = (string.len(attr.name) == 0) and 0 or 1,
			fg = attr.fg,
			bg = attr.bg,
			shape = function(cr, width, height)
				gears.shape.rounded_rect(cr, width, height, dpi(3))
			end,
			widget = wibox.container.background,
		},
		margins = attr.spacing,
		forced_height = key_size,
		forced_width = key_size * attr.size,
		widget = wibox.container.margin,
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

		layout = wibox.layout.fixed.horizontal,

		{
			layout = wibox.layout.fixed.vertical,
			spacing = dpi(3),

			-- Function keys row
			{
				layout = wibox.layout.fixed.horizontal,
				forced_height = key_size / 2,
				spacing = 0,
				button({
					name = "Esc",
					keycode = "Escape",
					fg = accent_fg_color,
					bg = accent_bg_color,
				}),
				button({ name = "", size = 0.5 }), -- Small gap
				button({ name = "F1", keycode = "F1", fg = mod_fg_color, bg = mod_bg_color }),
				button({ name = "F2", keycode = "F2", fg = mod_fg_color, bg = mod_bg_color }),
				button({ name = "F3", keycode = "F3", fg = mod_fg_color, bg = mod_bg_color }),
				button({ name = "F4", keycode = "F4", fg = mod_fg_color, bg = mod_bg_color }),
				button({ name = "", size = 0.3 }), -- Small gap
				button({ name = "F5", keycode = "F5", fg = mod_fg_color, bg = mod_bg_color }),
				button({ name = "F6", keycode = "F6", fg = mod_fg_color, bg = mod_bg_color }),
				button({ name = "F7", keycode = "F7", fg = mod_fg_color, bg = mod_bg_color }),
				button({ name = "F8", keycode = "F8", fg = mod_fg_color, bg = mod_bg_color }),
				button({ name = "", size = 0.3 }), -- Small gap
				button({ name = "F9", keycode = "F9", fg = mod_fg_color, bg = mod_bg_color }),
				button({ name = "F10", keycode = "F10", fg = mod_fg_color, bg = mod_bg_color }),
				button({ name = "F11", keycode = "F11", fg = mod_fg_color, bg = mod_bg_color }),
				button({ name = "F12", keycode = "F12", fg = mod_fg_color, bg = mod_bg_color }),
				button({ name = "", size = 0.5 }), -- Gap before nav cluster
				button({
					name = "PrSc",
					keycode = "Print",
					fg = mod_fg_color,
					bg = mod_bg_color,
				}),
				button({
					name = "ScrLk",
					keycode = "Scroll_Lock",
					fg = mod_fg_color,
					bg = mod_bg_color,
				}),
				button({
					name = "Pause",
					keycode = "Pause",
					fg = mod_fg_color,
					bg = mod_bg_color,
				}),
			},

			-- Number row
			{
				layout = wibox.layout.fixed.horizontal,
				spacing = 0,
				button({ name = "`", keycode = "grave" }),
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
				button({ name = "", size = 0.5 }), -- Gap
				button({ name = "Num", keycode = "Num_Lock", fg = mod_fg_color, bg = mod_bg_color }),
				button({ name = "/", keycode = "KP_Divide" }),
				button({ name = "*", keycode = "KP_Multiply" }),
			},

			-- Tab row
			{
				layout = wibox.layout.fixed.horizontal,
				spacing = 0,
				button({ name = "Tab", size = 1.5, keycode = "Tab", fg = mod_fg_color, bg = mod_bg_color }),
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
				button({ name = "\\", size = 1.5, keycode = "backslash" }),
				button({ name = "", size = 0.5 }), -- Gap
				button({ name = "7", keycode = "KP_7" }),
				button({ name = "8", keycode = "KP_8" }),
				button({ name = "9", keycode = "KP_9" }),
			},

			-- Caps Lock row
			{
				layout = wibox.layout.fixed.horizontal,
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
				button({ name = "", size = 0.5 }),
				button({ name = "4", keycode = "KP_4" }),
				button({ name = "5", keycode = "KP_5" }),
				button({ name = "6", keycode = "KP_6" }),
			},

			-- Shift row
			{
				layout = wibox.layout.fixed.horizontal,
				spacing = 0,
				button({
					name = "Shift",
					size = 2.25,
					keycode = "Shift_L",
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
					keycode = "Shift_R",
					fg = mod_fg_color,
					bg = mod_bg_color,
				}),

				button({ name = "", size = 0.5 }), -- Gap
				button({ name = "1", keycode = "KP_1" }),
				button({ name = "2", keycode = "KP_2" }),
				button({ name = "3", keycode = "KP_3" }),
			},

			-- Bottom row
			{
				layout = wibox.layout.fixed.horizontal,
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
				button({ name = " ", size = 6.25, keycode = "space" }),
				button({
					name = "Alt",
					keycode = "Alt_R",
					size = 1.25,
					fg = mod_fg_color,
					bg = mod_bg_color,
				}),
				button({
					name = "Ctrl",
					keycode = "Control_R",
					size = 1.25,
					fg = mod_fg_color,
					bg = mod_bg_color,
				}),
				-- Compact arrow key cluster
				{
					layout = wibox.layout.fixed.horizontal,
					spacing = 0,
					button({
						name = "←",
						keycode = "Left",
						size = 0.825,
						fg = accent_fg_color,
						bg = accent_bg_color,
					}),
					{
						layout = wibox.layout.fixed.vertical,
						spacing = dpi(1),
						{
							margins = { top = dpi(1), bottom = 0, left = dpi(1), right = dpi(1) },
							forced_height = key_size / 2 - dpi(5),
							forced_width = key_size * 0.825,
							{
								{
									{
										widget = wibox.widget.textbox,
										text = "↑",
										font = "Terminus 8",
										align = "center",
										valign = "center",
									},
									widget = wibox.container.place,
								},
								margins = dpi(1),
								widget = wibox.container.margin,
							},
							bg = accent_bg_color,
							fg = accent_fg_color,
							shape = function(cr, width, height)
								gears.shape.rounded_rect(cr, width, height, dpi(2))
							end,
							widget = wibox.container.background,
							buttons = awful.button({}, 1, function()
								awful.spawn("xdotool key Up")
							end),
						},
						{
							margins = { top = 0, bottom = dpi(1), left = dpi(1), right = dpi(1) },
							forced_height = key_size / 2 - dpi(5),
							forced_width = key_size * 0.825,
							{
								{
									{
										widget = wibox.widget.textbox,
										text = "↓",
										font = "Terminus 8",
										align = "center",
										valign = "center",
									},
									widget = wibox.container.place,
								},
								margins = dpi(1),
								widget = wibox.container.margin,
							},
							id = "down_bg",
							fg = accent_fg_color,
							bg = accent_bg_color,
							shape = function(cr, width, height)
								gears.shape.rounded_rect(cr, width, height, dpi(2))
							end,
							widget = wibox.container.background,
							buttons = awful.button({}, 1, function()
								awful.spawn("xdotool key Down")
							end),
						},
					},
					button({
						name = "→",
						keycode = "Right",
						size = 0.825,
						fg = accent_fg_color,
						bg = accent_bg_color,
					}),
				},
				button({ name = "", size = 0.5 }), -- Gap
				button({ name = "0", keycode = "KP_0", size = 2.0 }),
				button({ name = ".", keycode = "KP_Decimal" }),
			},
		},
		{
			layout = wibox.layout.fixed.vertical,
			spacing = dpi(5),
			-- Number row

			{
				forced_height = key_size / 2 - dpi(2),
				forced_width = key_size,
				widget = wibox.container.background,
			},

			button({ name = "-", keycode = "KP_Subtract" }),

			-- KP Plus key (tall but standard width and padding)
			{
				widget = wibox.container.margin,
				margins = { top = 0, bottom = 0, left = dpi(2), right = dpi(2) },
				{
					forced_height = key_size * 2,
					forced_width = key_size,
					{
						{
							{
								widget = wibox.widget.textbox,
								text = "+",
								font = "Terminus 8",
								align = "center",
								valign = "center",
							},
							widget = wibox.container.place,
						},
						margins = dpi(2),
						widget = wibox.container.margin,
					},
					fg = accent_fg_color,
					bg = accent_bg_color,
					shape = function(cr, width, height)
						gears.shape.rounded_rect(cr, width, height, dpi(2))
					end,
					widget = wibox.container.background,
					buttons = awful.button({}, 1, function()
						awful.spawn("xdotool key KP_Add")
					end),
				},
			},

			-- KP Enter key (tall but standard width and padding)
			{
				widget = wibox.container.margin,
				margins = { top = 0, bottom = 0, left = dpi(2), right = dpi(2) },
				{
					forced_height = key_size * 2,
					forced_width = key_size,
					{
						{
							{
								widget = wibox.widget.textbox,
								text = "Enter",
								font = "Terminus 8",
								align = "center",
								valign = "center",
							},
							widget = wibox.container.place,
						},
						margins = dpi(2),
						widget = wibox.container.margin,
					},
					fg = accent_fg_color,
					bg = accent_bg_color,
					shape = function(cr, width, height)
						gears.shape.rounded_rect(cr, width, height, dpi(2))
					end,
					widget = wibox.container.background,
					buttons = awful.button({}, 1, function()
						awful.spawn("xdotool key KP_Enter")
					end),
				},
			},
		},
	}
end

-- Function to create or update the keyboard bar for current screen
local function create_keyboard_bar()
	local geom = get_screen_geometry()
	local keyboard_height = 5 * key_size + dpi(50)
	local gap = dpi(8) -- Set your desired gap here

	-- Clean up existing bar if it exists
	if current_bar then
		current_bar.visible = false
		current_bar = nil
	end

	-- Create new bar on focused screen
	current_bar = awful.wibar({
		screen = geom.screen,
		height = keyboard_height,
		width = geom.screen_width - 2 * gap,
		x = geom.workarea.x + gap,
		position = "bottom",
		shape = function(cr, width, height)
			gears.shape.rounded_rect(cr, width, height, dpi(8))
		end,
		margins = { top = 0, bottom = gap },
		visible = false,
		bg = "#00000066",
	})

	current_bar:setup({
		layout = wibox.layout.align.horizontal,
		expand = "none", -- Prevents the keyboard from stretching
		nil,       -- Left side empty
		create_keyboard_layout(),
		nil,       -- Right side empty
	})
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
		show_keyboard(false)
	end
end

local function show()
	show_keyboard(true)
end

local function hide()
	show_keyboard(false)
end

-- Connect to toggle signal
awesome.connect_signal("flyout::osd_keyboard:toggle", function()
	toggle()
end)

awesome.connect_signal("flyout::osd_keyboard:show", function()
	show()
end)

awesome.connect_signal("flyout::osd_keyboard:hide", function()
	hide()
end)

return virtual_keyboard
