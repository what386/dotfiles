local awful = require("awful")
local wibox = require("wibox")
local gears = require("gears")
local beautiful = require("beautiful")
local dpi = beautiful.xresources.apply_dpi
local clickable_container = require("ui.clickable-container")
local blur_status = true

local config_dir = gears.filesystem.get_configuration_dir()
local widget_icon_dir = config_dir .. "ui/panels/dashboard/settings/icons/"

local action_name = wibox.widget({
	text = "Blur Effects",
	font = "Inter Bold 10",
	align = "left",
	widget = wibox.widget.textbox,
})

local action_status_text = wibox.widget({
	text = "Off",
	font = "Inter Regular 10",
	align = "left",
	widget = wibox.widget.textbox,
})

local action_info = wibox.widget({
	layout = wibox.layout.fixed.vertical,
	action_name,
	action_status_text,
})

local button_widget = wibox.widget({
	{
		id = "icon",
		image = widget_icon_dir .. "effects.svg",
		widget = wibox.widget.imagebox,
		resize = true,
	},
	layout = wibox.layout.align.horizontal,
})

local widget_button = wibox.widget({
	{
		{
			button_widget,
			margins = dpi(15),
			forced_height = dpi(48),
			forced_width = dpi(48),
			widget = wibox.container.margin,
		},
		widget = clickable_container,
	},
	bg = beautiful.groups_bg,
	shape = gears.shape.circle,
	widget = wibox.container.background,
})

local update_widget = function()
	if blur_status then
		action_status_text:set_text("On")
		widget_button.bg = beautiful.system_magenta_dark
		button_widget.icon:set_image(widget_icon_dir .. "effects.svg")
	else
		action_status_text:set_text("Off")
		widget_button.bg = beautiful.groups_bg
		button_widget.icon:set_image(widget_icon_dir .. "effects-off.svg")
	end
end

local check_blur_status = function()
	awful.spawn.easy_async_with_shell([[bash -c "
		grep -F 'method = \"none\";' ]] .. config_dir .. [[dependencies/picom/picom.conf | tr -d '[\"\;\=\ ]'
		"]], function(stdout, stderr)
		if stdout:match("methodnone") then
			action_status_text:set_text("On")
		else
			action_status_text:set_text("Off")
		end

		update_widget()
	end)
end

check_blur_status()

local toggle_blur = function(togglemode)
	local toggle_blur_script = [[bash -c "
	# Check picom if it's not running then start it
	if [ -z $(pgrep picom) ]; then
		picom -b --experimental-backends --dbus --config ]] .. config_dir .. [[dependencies/picom/picom.conf
	fi

	case ]] .. togglemode .. [[ in
		'enable')
		sed -i -e 's/method = \"none\"/method = \"dual_kawase\"/g' \"]] .. config_dir .. [[dependencies/picom/picom.conf\"
		;;
		'disable')
		sed -i -e 's/method = \"dual_kawase\"/method = \"none\"/g' \"]] .. config_dir .. [[dependencies/picom/picom.conf\"
		;;
	esac
	"]]

	-- Run the script
	awful.spawn.with_shell(toggle_blur_script)
end

local toggle_blur_fx = function()
	local state = nil
	if blur_status then
		blur_status = false
		state = "disable"
	else
		blur_status = true
		state = "enable"
	end
	toggle_blur(state)
	update_widget()
end

widget_button:buttons(gears.table.join(awful.button({}, 1, nil, function()
	toggle_blur_fx()
end)))

action_info:buttons(gears.table.join(awful.button({}, 1, nil, function()
	toggle_blur_fx()
end)))

local action_widget = wibox.widget({
	layout = wibox.layout.fixed.horizontal,
	spacing = dpi(10),
	widget_button,
	{
		layout = wibox.layout.align.vertical,
		expand = "none",
		nil,
		action_info,
		nil,
	},
})

awesome.connect_signal("setting::blur:toggle", function()
	toggle_blur_fx()
end)

return action_widget
