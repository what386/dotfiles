-- Required libraries
local wibox = require("wibox")
local awful = require("awful")
local gears = require("gears")
local beautiful = require("beautiful")
local dpi = beautiful.xresources.apply_dpi

local icons = require("theme.icons")
local clickable_container = require("ui.clickable-container")
local userprefs = require("config.user.preferences")

local gfs = require("gears.filesystem")

local icons_battery = {
	icons.widgets.battery.discharging.battery_0,
	icons.widgets.battery.discharging.battery_5,
	icons.widgets.battery.discharging.battery_10,
	icons.widgets.battery.discharging.battery_15,
	icons.widgets.battery.discharging.battery_20,
	icons.widgets.battery.discharging.battery_25,
	icons.widgets.battery.discharging.battery_30,
	icons.widgets.battery.discharging.battery_35,
	icons.widgets.battery.discharging.battery_40,
	icons.widgets.battery.discharging.battery_45,
	icons.widgets.battery.discharging.battery_50,
	icons.widgets.battery.discharging.battery_55,
	icons.widgets.battery.discharging.battery_60,
	icons.widgets.battery.discharging.battery_65,
	icons.widgets.battery.discharging.battery_70,
	icons.widgets.battery.discharging.battery_75,
	icons.widgets.battery.discharging.battery_80,
	icons.widgets.battery.discharging.battery_85,
	icons.widgets.battery.discharging.battery_90,
	icons.widgets.battery.discharging.battery_95,
	icons.widgets.battery.discharging.battery_100,
}

local icons_charging = {
	icons.widgets.battery.charging.battery_charging_0,
	icons.widgets.battery.charging.battery_charging_5,
	icons.widgets.battery.charging.battery_charging_10,
	icons.widgets.battery.charging.battery_charging_15,
	icons.widgets.battery.charging.battery_charging_20,
	icons.widgets.battery.charging.battery_charging_25,
	icons.widgets.battery.charging.battery_charging_30,
	icons.widgets.battery.charging.battery_charging_35,
	icons.widgets.battery.charging.battery_charging_40,
	icons.widgets.battery.charging.battery_charging_45,
	icons.widgets.battery.charging.battery_charging_50,
	icons.widgets.battery.charging.battery_charging_55,
	icons.widgets.battery.charging.battery_charging_60,
	icons.widgets.battery.charging.battery_charging_65,
	icons.widgets.battery.charging.battery_charging_70,
	icons.widgets.battery.charging.battery_charging_75,
	icons.widgets.battery.charging.battery_charging_80,
	icons.widgets.battery.charging.battery_charging_85,
	icons.widgets.battery.charging.battery_charging_90,
	icons.widgets.battery.charging.battery_charging_95,
	icons.widgets.battery.charging.battery_charging_100,
}

local widget = wibox.widget({
	{
		id = "icon",
		image = icons.widgets.battery.battery_alert,
		widget = wibox.widget.imagebox,
		resize = true,
	},
	--{
	--	id = "percentage",
	--	text = "??%",
	--	widget = wibox.widget.textbox,
	--	resize = true,
	--},
	layout = wibox.layout.align.horizontal,
})

local widget_button = wibox.widget({
	{
		widget,
		margins = dpi(5.5),
		widget = wibox.container.margin,
	},
	widget = clickable_container,
})

widget_button:buttons(gears.table.join(awful.button({}, 1, nil, function()
	awful.spawn(userprefs.default.power_manager, false)
end)))

local battery_tooltip = awful.tooltip({
	text = "Loading...",
	objects = { widget_button },
	delay_show = 0.15,
	mode = "outside",
	align = "right",
	preferred_positions = { "left", "right", "top", "bottom" },
	margin_leftright = dpi(8),
	margin_topbottom = dpi(8),
})

local icon_list = icons_battery

local update_tooltip = function(message)
	battery_tooltip:set_markup(message)
end

local persistent_battery_info

awful.spawn.easy_async_with_shell("acpi -i", function(stdout)
	local design_cap, effective_cap, health = string.match(stdout, ".+:.+:.+ .+ (%d+ mAh).+ .+ .+ (%d+ mAh).+= (%d+%%)")

	persistent_battery_info = "\nDesign capacity: <b>"
		.. design_cap
		.. "</b>"
		.. "\nEffective capacity: <b>"
		.. effective_cap
		.. "</b>"
		.. "\nBattery health: <b>"
		.. health
		.. "</b>"
end)

local function update_widget(status, charge, time)
	local formatted_time
	local formatted_status

	if not charge then
		return
	end

	if status == "Charging" then
		icon_list = icons_charging
		formatted_status = "charged"
	else
		icon_list = icons_battery
		formatted_status = "discharged"
	end

	if time and not time:match("unknown") then
		formatted_time = time
	else
		formatted_time = "unavailable"
	end

	if charge == 0 then
		widget.icon:set_image(icons.widgets.battery)
	end

	if charge == 100 then
		widget.icon:set_image(icon_list[21])
	else
		widget.icon:set_image(icon_list[math.floor(charge / 5) + 1])
	end

	update_tooltip(
		"Battery percentage: <b>"
		.. charge
		.. "%</b>"
		.. "\nTime until "
		.. formatted_status
		.. ": <b>"
		.. formatted_time
		.. "</b>"
		.. persistent_battery_info
	)

	--widget.percentage.text = charge .. "%"
end

awful.widget.watch("acpi -i", 10, function(_, stdout)
	local status, charge_str, time = string.match(stdout, ".+: (%a+), (%d+)%%, (%d+:%d+:%d+)")
	local charge = tonumber(charge_str)

	update_widget(status, charge, time)
end)

return widget_button
