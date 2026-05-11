local paths = require("theme.icons.paths")
local dir = paths.theme_icons_dir

return {
	settings = {
		bluetooth = dir .. "widgets/bluetooth/bluetooth.svg",
		bluetooth_off = dir .. "widgets/bluetooth/bluetooth-off.svg",
		airplane_mode = dir .. "widgets/airplane/airplane-mode.svg",
		airplane_mode_off = dir .. "widgets/airplane/airplane-mode-off.svg",
		brightness = dir .. "widgets/brightness/brightness.svg",
		volume_medium = dir .. "widgets/volume/volume-medium.svg",
		effects = dir .. "system/effects.svg",
		loading = dir .. "system/loading.svg",
		blue_light = dir .. "dashboard/settings/blue-light.svg",
		blue_light_off = dir .. "dashboard/settings/blue-light-off.svg",
		brightness_off = dir .. "dashboard/settings/brightness-off.svg",
		dont_disturb = dir .. "dashboard/settings/dont-disturb.svg",
		notify = dir .. "dashboard/settings/notify.svg",
		effects_off = dir .. "dashboard/settings/effects-off.svg",
	},
	switch = {
		chart = dir .. "dashboard/switch/chart.svg",
		gear = dir .. "dashboard/switch/gear.svg",
	},
}
