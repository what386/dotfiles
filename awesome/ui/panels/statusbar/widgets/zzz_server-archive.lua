local awful = require("awful")
local wibox = require("wibox")
local gears = require("gears")
local naughty = require("naughty")
local watch = awful.widget.watch
local dpi = require("beautiful").xresources.apply_dpi

local usercreds = require("config.user.credentials")

local clickable_container = require("ui.clickable-container")

local icons = require("theme.icons")

local gfs = require("gears.filesystem")

local config_dir = gfs.get_configuration_dir()
local script_dir = config_dir .. "/scripts/"

local widget = wibox.widget({
	{
		id = "icon",
		image = icons.widgets.server.server_disconnect,
		widget = wibox.widget.imagebox,
		resize = true,
	},
	layout = wibox.layout.align.horizontal,
})

local widget_button = wibox.widget({
	{
		widget,
		margins = dpi(6),
		widget = wibox.container.margin,
	},
	widget = clickable_container,
})

local username = usercreds.server.username
local local_ip = usercreds.server.local_ip

widget_button:buttons(gears.table.join(awful.button({}, 1, nil, function()
	awful.spawn.with_shell([[gnome-terminal -- ssh ]] .. username .. "@" .. local_ip, false) -- command to run on click widget
end)))

local server_tooltip = awful.tooltip({
	text = "Loading...",
	objects = { widget_button },
	delay_show = 0.15,
	mode = "outside",
	align = "right",
	margin_leftright = dpi(8),
	margin_topbottom = dpi(8),
	preferred_positions = { "right", "left", "top", "bottom" },
})

local update_tooltip = function(message)
	server_tooltip:set_markup(message)
end

local function update_server_widget(tunneled, local_connection, global_connection)
	local icon = icons.widgets.server.server_disconnect

	local global_connection_string = "Unresponsive..."
	if global_connection == "1" then
		global_connection_string = "Replying to pings"
		icon = icons.widgets.server.server_online
	end

	local local_connection_string = "No connection"
	if local_connection == "1" then
		local_connection_string = "Connected by LAN"
		icon = icons.widgets.server.server_connected
	end

	local tunneled_string = "Public network"
	if tunneled == true then
		tunneled_string = "Local at 10.0.0.2"
	end

	widget.icon:set_image(icon)
	update_tooltip(
		"Network: <b>"
		.. tunneled_string
		.. "</b>"
		.. "\nCommunication: <b>"
		.. local_connection_string
		.. "</b>"
		.. "\nStatus: <b>"
		.. global_connection_string
		.. "</b>"
	)
end

local function update_server_connection(tunneled)
	awful.spawn.easy_async(script_dir .. "server_status.sh", function(stdout)
		local local_connection, global_connection = string.match(stdout, "(%d),(%d)")
		update_server_widget(tunneled, local_connection, global_connection)
	end)
end

local function update_server_information()
	awful.spawn.easy_async([[ip route get 10.0.0.2]], function(stdout)
		local status = string.match(stdout, "10.0.0.2 (%a%a%a)")

		local tunneled = false
		if status == "dev" then --tunnel active
			tunneled = true
		end

		update_server_connection(tunneled)
	end)
end

gears.timer({
	timeout = 30,
	call_now = true,
	autostart = true,
	callback = function()
		update_server_information()
	end,
})

return widget_button
