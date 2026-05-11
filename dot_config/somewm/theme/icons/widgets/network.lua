local paths = require("theme.icons.paths")
local dir = paths.theme_icons_dir

return {
	wifi = {
		wifi_on = dir .. "widgets/wifi/wifi.svg",
		wifi_off = dir .. "widgets/wifi/wifi-off.svg",
		wifi_strength_off = dir .. "widgets/wifi/wifi-strength-off.svg",
		wifi_strength_off_outline = dir .. "widgets/wifi/wifi-strength-off-outline.svg",
		wifi_strength_empty = dir .. "widgets/wifi/wifi-strength-empty.svg",
		wifi_strength_outline = dir .. "widgets/wifi/wifi-strength-outline.svg",
		wifi_strength_1 = dir .. "widgets/wifi/wifi-strength-1.svg",
		wifi_strength_2 = dir .. "widgets/wifi/wifi-strength-2.svg",
		wifi_strength_3 = dir .. "widgets/wifi/wifi-strength-3.svg",
		wifi_strength_4 = dir .. "widgets/wifi/wifi-strength-4.svg",
		wifi_strength_1_alert = dir .. "widgets/wifi/wifi-strength-1-alert.svg",
		wifi_strength_2_alert = dir .. "widgets/wifi/wifi-strength-2-alert.svg",
		wifi_strength_3_alert = dir .. "widgets/wifi/wifi-strength-3-alert.svg",
		wifi_strength_4_alert = dir .. "widgets/wifi/wifi-strength-4-alert.svg",
		wifi_strength_alert = dir .. "widgets/wifi/wifi-strength-alert.svg",
		wifi_strength_alert_outline = dir .. "widgets/wifi/wifi-strength-alert-outline.svg",
	},
	ethernet = {
		eth_disconnected = dir .. "widgets/ethernet/wired-disconnect.svg",
		eth_connecting = dir .. "widgets/ethernet/wired-connecting.svg",
		eth_connected = dir .. "widgets/ethernet/wired-connected.svg",
		eth_no_route = dir .. "widgets/ethernet/wired-no-route.svg",
	},
	airplane = {
		airplane_mode = dir .. "widgets/airplane/airplane-mode.svg",
		airplane_mode_off = dir .. "widgets/airplane/airplane-mode-off.svg",
	},
}
