local paths = require("theme.icons.paths")
local dir = paths.theme_icons_dir

return {
	cpu = dir .. "applets/resource-monitor/cpu.svg",
	gpu = dir .. "applets/resource-monitor/gpu.svg",
	ram = dir .. "applets/resource-monitor/memory.svg",
	storage = dir .. "applets/resource-monitor/storage.svg",
	hdd = dir .. "applets/resource-monitor/hdd.svg",
	ssd = dir .. "applets/resource-monitor/storage.svg",
	temp = dir .. "applets/resource-monitor/thermometer.svg",
	net = dir .. "system/refresh.svg",
}
