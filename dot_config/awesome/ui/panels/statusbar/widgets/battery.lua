local wibox = require("wibox")
local awful = require("awful")
local gears = require("gears")
local beautiful = require("beautiful")
local dpi = beautiful.xresources.apply_dpi
local icons = require("theme.icons")
local clickable_container = require("ui.clickable-container")
local power = require("services.power")

local icons_battery = {
	icons.widgets.battery.discharging.battery_0, icons.widgets.battery.discharging.battery_5,
	icons.widgets.battery.discharging.battery_10, icons.widgets.battery.discharging.battery_15,
	icons.widgets.battery.discharging.battery_20, icons.widgets.battery.discharging.battery_25,
	icons.widgets.battery.discharging.battery_30, icons.widgets.battery.discharging.battery_35,
	icons.widgets.battery.discharging.battery_40, icons.widgets.battery.discharging.battery_45,
	icons.widgets.battery.discharging.battery_50, icons.widgets.battery.discharging.battery_55,
	icons.widgets.battery.discharging.battery_60, icons.widgets.battery.discharging.battery_65,
	icons.widgets.battery.discharging.battery_70, icons.widgets.battery.discharging.battery_75,
	icons.widgets.battery.discharging.battery_80, icons.widgets.battery.discharging.battery_85,
	icons.widgets.battery.discharging.battery_90, icons.widgets.battery.discharging.battery_95,
	icons.widgets.battery.discharging.battery_100,
}
local icons_charging = {
	icons.widgets.battery.charging.battery_charging_0, icons.widgets.battery.charging.battery_charging_5,
	icons.widgets.battery.charging.battery_charging_10, icons.widgets.battery.charging.battery_charging_15,
	icons.widgets.battery.charging.battery_charging_20, icons.widgets.battery.charging.battery_charging_25,
	icons.widgets.battery.charging.battery_charging_30, icons.widgets.battery.charging.battery_charging_35,
	icons.widgets.battery.charging.battery_charging_40, icons.widgets.battery.charging.battery_charging_45,
	icons.widgets.battery.charging.battery_charging_50, icons.widgets.battery.charging.battery_charging_55,
	icons.widgets.battery.charging.battery_charging_60, icons.widgets.battery.charging.battery_charging_65,
	icons.widgets.battery.charging.battery_charging_70, icons.widgets.battery.charging.battery_charging_75,
	icons.widgets.battery.charging.battery_charging_80, icons.widgets.battery.charging.battery_charging_85,
	icons.widgets.battery.charging.battery_charging_90, icons.widgets.battery.charging.battery_charging_95,
	icons.widgets.battery.charging.battery_charging_100,
}

local widget = wibox.widget({ { id = "icon", image = icons.widgets.battery.battery_alert, widget = wibox.widget.imagebox, resize = true }, layout = wibox.layout.align.horizontal })
local widget_button = wibox.widget({ { widget, margins = dpi(5.5), widget = wibox.container.margin }, widget = clickable_container })
local battery_tooltip = awful.tooltip({ text = "Loading...", objects = { widget_button }, delay_show = 0.15, mode = "outside", align = "right", preferred_positions = { "left", "right", "top", "bottom" }, margin_leftright = dpi(8), margin_topbottom = dpi(8) })

local function get_icon(list, charge)
	charge = math.max(0, math.min(100, tonumber(charge) or 0))
	local index = math.floor(charge / 5) + 1
	return list[math.max(1, math.min(21, index))]
end

local function render(battery)
	battery = battery or power.get_battery_state()
	local charge = battery.charge
	if not charge then
		widget.icon:set_image(icons.widgets.battery.battery_alert)
		battery_tooltip:set_markup("Battery unavailable")
		return
	end

	local charging = battery.status == "Charging" or battery.status == "Not charging"
	widget.icon:set_image(get_icon(charging and icons_charging or icons_battery, charge))
	local time = battery.time and not tostring(battery.time):match("unknown") and battery.time or "unavailable"
	local status = charging and "Time until fully charged: <b>" .. time .. "</b>" or "Time until discharged: <b>" .. time .. "</b>"
	if battery.status == "Not charging" then status = "Battery is not charging." end
	local health = "\nDesign capacity: <b>" .. tostring(battery.design_capacity or "unknown") .. "</b>\nEffective capacity: <b>" .. tostring(battery.effective_capacity or "unknown") .. "</b>\nBattery health: <b>" .. tostring(battery.health or "unknown") .. "</b>"
	battery_tooltip:set_markup("Percentage: <b>" .. tostring(charge) .. "%</b>\n" .. status .. health)
end

widget_button:buttons(gears.table.join(awful.button({}, 1, nil, power.open_power_manager)))
awesome.connect_signal("power::battery", render)
render(power.get_battery_state())

return widget_button
