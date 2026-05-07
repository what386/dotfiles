local awful = require("awful")
local wibox = require("wibox")
local gears = require("gears")
local dpi = require("beautiful").xresources.apply_dpi
local clickable_container = require("ui.clickable-container")
local icons = require("theme.icons")
local network = require("services.network")

local widget = wibox.widget({ { id = "icon", image = icons.widgets.wifi.wifi_strength_off, widget = wibox.widget.imagebox, resize = true }, layout = wibox.layout.align.horizontal })
local widget_button = wibox.widget({ { widget, margins = dpi(6), widget = wibox.container.margin }, widget = clickable_container })
local network_tooltip = awful.tooltip({ text = "Loading...", objects = { widget_button }, delay_show = 0.15 })

local function wifi_icon(strength, healthy)
	local rounded = math.floor((strength or 0) / 25 + 0.5)
	if rounded <= 1 then return healthy and icons.widgets.wifi.wifi_strength_1 or icons.widgets.wifi.wifi_strength_1_alert end
	if rounded == 2 then return healthy and icons.widgets.wifi.wifi_strength_2 or icons.widgets.wifi.wifi_strength_2_alert end
	if rounded == 3 then return healthy and icons.widgets.wifi.wifi_strength_3 or icons.widgets.wifi.wifi_strength_3_alert end
	return healthy and icons.widgets.wifi.wifi_strength_4 or icons.widgets.wifi.wifi_strength_4_alert
end

local function render(state)
	state = state or network.get_state()
	if not state.connected then
		widget.icon:set_image(icons.widgets.wifi.wifi_strength_off)
		network_tooltip:set_markup("Network disconnected")
		return
	end
	if state.mode == "wired" then
		widget.icon:set_image(state.internet_healthy and icons.widgets.ethernet.eth_connected or icons.widgets.ethernet.eth_no_route)
		network_tooltip:set_markup((state.internet_healthy and "" or "<b>No internet!</b>\n") .. "Ethernet: <b>" .. tostring(state.interfaces.lan) .. "</b>")
	else
		widget.icon:set_image(wifi_icon(state.strength, state.internet_healthy))
		local msg = "SSID: <b>" .. tostring(state.ssid) .. "</b>\nSignal: <b>" .. tostring(state.signal_dbm or "N/A") .. " dBm (" .. tostring(math.floor(state.strength or 0)) .. "%)</b>\nBitrate: <b>" .. tostring(state.bitrate) .. "</b>"
		if not state.internet_healthy then msg = "<b>Connected but no internet!</b>\n" .. msg end
		network_tooltip:set_markup(msg)
	end
end

widget_button:buttons(gears.table.join(awful.button({}, 1, nil, network.open_manager)))
awesome.connect_signal("network::state", render)
render(network.get_state())

return widget_button
