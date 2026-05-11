local awful = require("awful")
local wibox = require("wibox")
local gears = require("gears")
local dpi = require("beautiful").xresources.apply_dpi
local clickable_container = require("ui.clickable-container")
local icons = require("theme.icons")
local network = require("services.network")

local state = network.get_state()
local widget = wibox.widget({ { id = "icon", image = icons.widgets.wifi.wifi_strength_alert, widget = wibox.widget.imagebox, resize = true }, layout = wibox.layout.align.horizontal })
local widget_button = wibox.widget({ { widget, margins = dpi(6), widget = wibox.container.margin }, widget = clickable_container })
local tooltip = awful.tooltip({ objects = { widget_button }, delay_show = 0.15, mode = "outside", align = "right", margin_leftright = dpi(8), margin_topbottom = dpi(8), preferred_positions = { "left", "right", "top", "bottom" } })

local function render(next_state)
	if type(next_state) == "table" then state = next_state end
	local vpn_text = state.vpn_connected == true and "connected" or state.vpn_connected == false and "disconnected" or "unknown"
	local trust_text = state.trusted == true and "trusted" or state.trusted == false and "untrusted" or "unknown"
	if state.vpn_connected then widget.icon:set_image(icons.widgets.wifi.wifi_strength_4) elseif state.trusted then widget.icon:set_image(icons.widgets.wifi.wifi_on) else widget.icon:set_image(icons.widgets.wifi.wifi_strength_alert) end
	tooltip:set_markup("Network: <b>" .. tostring(state.ssid) .. "</b>\nTrust: <b>" .. trust_text .. "</b>\nVPN: <b>" .. vpn_text .. "</b>")
end

widget_button:buttons({
    awful.button({}, 1, nil, function() network.refresh_vpn() end),
    awful.button({}, 3, nil, network.toggle_vpn)
})
awesome.connect_signal("network::state", render)
awesome.connect_signal("vpn::status", function(next_state)
	state.ssid = next_state.ssid or state.ssid
	state.trusted = next_state.trusted
	state.vpn_connected = next_state.connected
	state.vpn_interface = next_state.interface or state.vpn_interface
	render(state)
end)
render(state)

return widget_button
