local awful = require("awful")
local beautiful = require("beautiful")
local gears = require("gears")
local apps = require("config.preferences.apps")
local menubar = require("menubar")
local hotkeys_popup = require("awful.hotkeys_popup").widget
local dpi = beautiful.xresources.apply_dpi

local menu_theme = {
	border_width = dpi(8),
	height = dpi(30),
}

local function round_menu(menu)
	menu.wibox.shape = function(cr, width, height)
		gears.shape.rounded_rect(cr, width, height, dpi(10))
	end
	menu.wibox.shape_clip = true
end

local function icon(name)
	return menubar.utils.lookup_icon(name)
end

local function toggle_dashboard()
	local screen = awful.screen.focused()
	if screen and screen.dashboard then screen.dashboard:toggle() end
end

local function show_notifications()
	local screen = awful.screen.focused()
	local panel = screen and screen.infopanel
	if not panel then return end
	panel:switch_pane("notifications")
	if not panel.opened then panel:toggle() end
end

local awesome_menu = {
	{
		"Hotkeys",
		function() hotkeys_popup.show_help(nil, awful.screen.focused()) end,
		icon("keyboard"),
	},
	{
		"Edit config",
		apps.terminal .. " -e " .. (os.getenv("EDITOR") or "nano") .. " " .. awesome.conffile,
		icon("accessories-text-editor"),
	},
	{
		"Reload configuration",
		awesome.reload,
		icon("view-refresh"),
	},
	{
		"Restart compositor",
		awesome.restart,
		icon("system-restart"),
	},
	{
		"Exit SomeWM",
		function() awesome.quit() end,
		icon("system-log-out"),
	},
	{
		"End session…",
		function() awesome.emit_signal("screen::exit_screen:show") end,
		icon("system-shutdown"),
	},
}

mymainmenu = awful.menu({
	theme = menu_theme,
	items = {
		{ "Launch application…", menubar.show, icon("system-run") },
		{ "Terminal", apps.terminal, icon("utilities-terminal") },
		{ "Files", apps.file_manager, icon("system-file-manager") },
		{ "Dashboard", toggle_dashboard, icon("preferences-system") },
		{ "Notifications", show_notifications, icon("preferences-desktop-notification") },
		{ "Awesome", awesome_menu, beautiful.awesome_icon },
	},
})
round_menu(mymainmenu)

-- Build the only submenu eagerly so it receives the same shape as the root menu.
mymainmenu.child[6] = awful.menu({ items = awesome_menu, theme = menu_theme }, mymainmenu)
round_menu(mymainmenu.child[6])

mylauncher = awful.widget.launcher({ image = beautiful.awesome_icon, menu = mymainmenu })
