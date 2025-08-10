-- Dependency: xdotool
--
-- Usage:
-- 1. Save as "virtual_keyboard.lua" in ~/.config/awesome/
-- 2. Add a virtual_keyboard for every screen:
--		awful.screen.connect_for_each_screen(function(s)
--			...
--			local virtual_keyboard = require("virtual_keyboard")
--			s.virtual_keyboard = virtual_keyboard:new({ screen = s } )
--			...
--		end)
-- 3. Toggle by using: awful.screen.focused().virtual_keyboard:toggle()

local awful = require("awful")
local wibox = require("wibox")
local dpi = require("beautiful").xresources.apply_dpi

local key_size = dpi(66)
local mod_fg_color = "#A9DD9D"
local mod_bg_color = "#2B373E"
local accent_fg_color = "#2B373E"
local accent_bg_color = "#A9DD9D"
local press_fg_color = "#2B373E"
local press_bg_color = "#A1BFCF"

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

local conf = {}
conf.visible = true

conf.screen = conf.screen or awful.screen.focused()
conf.position = conf.position or "bottom"

-- wibox
local bar = awful.wibar({
	position = conf.position,
	screen = conf.screen,
	height = (5 * key_size),
	bg = "#56666f",
	visible = conf.visible,
})
bar:setup({
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
					-- button({
					--     name = "",
					--     size = 0.25
					-- }),
					-- button({ name = "Insert" }),
					-- button({ name = "Home" }),
					-- button({
					--     name = "PageUp",
					--     keycode = "Page_Up"
					-- })
					--22 Jun 2025 - 28 Jun 2025 has
					--
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
					-- button({
					--     name = "",
					--     size = 0.25
					-- }),
					-- button({ name = "Delete" }),
					-- button({ name = "End" }),
					-- button({
					--     name = "PageDown",
					--     keycode = "Page_Down"
					-- })
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
					-- button({
					--     name = "",
					--     size = 0.25
					-- }),
					-- button({ name = "" }),
					-- button({ name = "" }),
					-- button({ name = "" })
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
					-- button({
					--     name = "",
					--     size = 0.25
					-- }),
					-- button({ name = "" }),
					-- button({ name = "Up" }),
					-- button({ name = "" })
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
					-- button({
					--     name = "",
					--     size = 0.25
					-- }),
					-- button({ name = "Left" }),
					-- button({ name = "Down" }),
					-- button({ name = "Right" })
				},
				{ layout = wibox.layout.fixed.horizontal },
			},
		},
	},
})
--conf.bar = bar
--local dropdown = setmetatable(conf, { __index = })

local function toggle()
	bar.visible = not bar.visible
end

return bar
