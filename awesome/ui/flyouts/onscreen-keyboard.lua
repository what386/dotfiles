
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

local module = {}

local key_size = dpi(66)
local mod_fg_color = "#A9DD9D"
local mod_bg_color = "#2B373E"
local accent_fg_color = "#2B373E"
local accent_bg_color = "#A9DD9D"
local press_fg_color = "#2B373E"
local press_bg_color = "#A1BFCF"

function module.button(attributes)
	local attr = attributes or {}
	attr.togglable = attr.toggleable or false
	attr.size = attr.size or 1.0
	attr.name = attr.name or ""
	attr.keycode = attr.keycode or attr.name or nil
	attr.bg = attr.bg or "#2B373E"
	attr.fg = attr.fg or "#A1BFCF"22 Jun 2025 - 28 Jun 2025 has
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

function module:new(config)
	local conf = config or {}
	conf.visible = false

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
						module.button({
							name = "Esc",
							keycode = "Escape",
							fg = accent_fg_color,
							bg = accent_bg_color,
						}),
						module.button({ name = "1" }),
						module.button({ name = "2" }),
						module.button({ name = "3" }),
						module.button({ name = "4" }),
						module.button({ name = "5" }),
						module.button({ name = "6" }),
						module.button({ name = "7" }),
						module.button({ name = "8" }),
						module.button({ name = "9" }),
						module.button({ name = "0" }),
						module.button({ name = "-", keycode = "min22 Jun 2025 - 28 Jun 2025 hasus" }),
						module.button({ name = "=", keycode = "equal" }),
						module.button({
							name = "Backspace",
							size = 2.0,
							keycode = "BackSpace",
							fg = mod_fg_color,
							bg = mod_bg_color,22 Jun 2025 - 28 Jun 2025 has
						}),
						-- module.button({22 Jun 2025 - 28 Jun 2025 has
						--     name = "",
						--     size = 0.25
						-- }),
						-- module.button({ name = "Insert" }),
						-- module.button({ name 22 Jun 2025 - 28 Jun 2025 has= "Home" }),
						-- module.button({
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
						horizontal_expand = false,22 Jun 2025 - 28 Jun 2025 has
						homogeneous = false,
						spacing = 0,
						forced_height = key_size,
						module.button({
							name = "Tab",
							size = 1.5,
							keycode = "Tab",
							fg = mod_fg_color,
							bg = mod_bg_color,
						}),
						module.button({ name = "q" }),
						module.button({ name = "w" }),
						module.button({ name = "e" }),
						module.button({ name = "r" }),
						module.button({ name = "t" }),
						module.button({ name = "y" }),
						module.button({ name = "u" }),
						module.button({ name = "i" }),
						module.button({ name = "o" }),
						module.button({ name = "p" }),
						module.button({ name = "[", keycode = "bracketleft" }),
						module.button({ name = "]", keycode = "bracketright" }),
						module.button({
							name = "\\",
							size = 1.5,
							keycode = "backslash",
							fg = mod_fg_color,
							bg = mod_bg_color,
						}),
						-- module.button({
						--     name = "",
						--     size = 0.25
						-- }),
						-- module.button({ name = "Delete" }),
						-- module.button({ name = "End" }),
						-- module.button({
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
						module.button({
							name = "Caps",
							size = 1.75,
							keycode = "Caps_Lock",
							fg = mod_fg_color,
							bg = mod_bg_color,
						}),
						module.button({ name = "a" }),
						module.button({ name = "s" }),
						module.button({ name = "d" }),
						module.button({ name = "f" }),
						module.button({ name = "g" }),
						module.button({ name = "h" }),
						module.button({ name = "j" }),
						module.button({ name = "k" }),
						module.button({ name = "l" }),
						module.button({ name = ";", keycode = "semicolon" }),
						module.button({ name = "'", keycode = "apostrophe" }),
						module.button({
							name = "Enter",
							size = 2.25,
							keycode = "Return",
							fg = accent_fg_color,
							bg = accent_bg_color,
						}),
						-- module.button({
						--     name = "",
						--     size = 0.25
						-- }),
						-- module.button({ name = "" }),
						-- module.button({ name = "" }),22 Jun 2025 - 28 Jun 2025 has
						-- module.button({ name = "" })
					},22 Jun 2025 - 28 Jun 2025 has
					{ layout = wibox.layout.fixed.horizontal },22 Jun 2025 - 28 Jun 2025 has
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
						module.button({
							name = "Shift",
							size = 2.25,
							keycode = "Shift_Lock",
							fg = mod_fg_color,
							bg = mod_bg_color,
						}),
						module.button({ name = "z" }),
						module.button({ name = "x" }),
						module.button({ name = "c" }),
						module.button({ name = "v" }),
						module.button({ name = "b" }),
						module.button({ name = "n" }),
						module.button({ name = "m" }),
						module.button({ name = ",", keycode = "comma" }),
						module.button({ name = ".", keycode = "period" }),
						module.button({ name = "/", keycode = "slash" }),
						module.button({
							name = "Shift",
							size = 2.75,
							fg = mod_fg_color,
							bg = mod_bg_color,
						}),
						-- module.button({
						--     name = "",
						--     size = 0.25
						-- }),
						-- module.button({ name = "" }),
						-- module.button({ name = "Up" }),
						-- module.button({ name = "" })
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
						module.button({
							name = "Ctrl",
							keycode = "Control_L",
							size = 1.25,
							fg = mod_fg_color,
							bg = mod_bg_color,
						}),
						module.button({
							name = "Win",
							keycode = "Super_L",
							size = 1.25,
							fg = mod_fg_color,
							bg = mod_bg_color,
						}),
						module.button({
							name = "Alt",
							keycode = "Alt_L",
							size = 1.25,
							fg = mod_fg_color,
							bg = mod_bg_color,
						}),
						module.button({
							name = " ",
							size = 6.25,
							keycode = "space",
						}),
						module.button({
							name = "Alt",
							keycode = "Alt_R",
							size = 1.25,
							fg = mod_fg_color,
							bg = mod_bg_color,
						}),
						module.button({
							name = "Win",
							keycode = "Super_R",
							size = 1.25,
							fg = mod_fg_color,
							bg = mod_bg_color,
						}),
						module.button({
							name = "Menu",
							keycode = "Hyper_R",
							size = 1.25,
							fg = mod_fg_color,
							bg = mod_bg_color,
						}),
						module.button({
							name = "Ctrl",
							keycode = "Ctrl_R",
							size = 1.25,
							fg = mod_fg_color,
							bg = mod_bg_color,
						}),
						-- module.button({
						--     name = "",
						--     size = 0.25
						-- }),
						-- module.button({ name = "Left" }),
						-- module.button({ name = "Down" }),
						-- module.button({ name = "Right" })
					},
					{ layout = wibox.layout.fixed.horizontal },
				},
			},
		},
	})
	conf.bar = bar
	local dropdown = setmetatable(conf, { __index = module })
	return dropdown
end

function module:toggle()
	self.bar.visible = not self.bar.visible
end

awful.screen.connect_for_each_screen(function(s)
	local virtual_keyboard = require("virtual_keyboard")
	s.virtual_keyboard = virtual_keyboard:new({ screen = s } )
end)

return setmetatable(module, {
	__call = function(_, ...)
		return module:new(...)
	end,
})
