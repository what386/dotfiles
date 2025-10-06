gfs = require("gears.filesystem")

local dir = gfs.get_configuration_dir() .. "theme/icons/"
local style = "circle"
local titlebar = "titlebar/" .. style .. "/"

local icons = {}

icons.system = {
	awesome = dir .. "system/awesome.svg",
	toggled_on = dir .. "system/toggled-on.svg",
	toggled_off = dir .. "system/toggled-off.svg",
	left_arrow = dir .. "system/left-arrow.svg",
	right_arrow = dir .. "system/right-arrow.svg",
	plus = dir .. "system/plus.svg",
	effects = dir .. "system/effects.svg",
	search = dir .. "system/magnify.svg",
	remove = dir .. "system/remove.svg",
	close = dir .. "system/close.svg",
	refresh = dir .. "system/refresh.svg",
	settings = dir .. "system/settings.svg",
	loading = dir .. "system/loading.svg",
	no = dir .. "system/no.svg",
	yes = dir .. "system/yes.svg",
	floppy_disk = dir .. "system/floppy.svg",
	compact_disk = dir .. "system/cd.svg",
	usb = dir .. "system/usb.svg",
	menu = dir .. "system/menu.svg",
	kb_on = dir .. "system/kb-on.svg",
	kb_off = dir .. "system/kb-off.svg",
	default_user = dir .. "system/default-user.svg",
	launcher = dir .. "system/launcher.svg",
	up_chevron = dir .. "system/up-chevron.svg",
	down_chevron = dir .. "system/down-chevron.svg",
	left_chevron = dir .. "system/left-chevron.svg",
}

icons.folders = {
	documents = dir .. "folders/folder-documents.svg",
	downloads = dir .. "folders/folder-download.svg",
	pictures = dir .. "folders/folder-pictures.svg",
	home = dir .. "folders/folder-home.svg",
	trash_empty = dir .. "folders/trash-empty.svg",
	trash_full = dir .. "folders/trash-full.svg",
	open_folder = dir .. "folders/open-folder.svg",
}

icons.power = {
	power = dir .. "power/power.svg",
	reboot = dir .. "power/reboot.svg",
	lock = dir .. "power/lock.svg",
	sleep = dir .. "power/sleep.svg",
	hibernate = dir .. "power/hibernate.svg",
	logout = dir .. "power/logout.svg",
}

icons.tags = {
	development = dir .. "tags/development.svg",
	file_manager = dir .. "tags/file-manager.svg",
	web_browser = dir .. "tags/zenbrowser.svg",
	multimedia = dir .. "tags/multimedia.svg",
	sandbox = dir .. "tags/sandbox.svg",
	social = dir .. "tags/social.svg",
	terminal = dir .. "tags/terminal.svg",
	graphics = dir .. "tags/graphics.svg",
	text_editor = dir .. "tags/text-editor.svg",
	vinyl = dir .. "tags/vinyl.svg",
	music = dir .. "tags/music.svg",
	mail = dir .. "tags/mail.svg",
}

icons.layouts = {
	dwindle = dir .. "layouts/dwindle.svg",
	floating = dir .. "layouts/floating.svg",
	fullscreen = dir .. "layouts/fullscreen.svg",
	max = dir .. "layouts/max.svg",
	tile = dir .. "layouts/tile.svg",
}

icons.applets = {}

icons.applets.email = {
	email = dir .. "applets/email/email.svg",
	email1 = dir .. "applets/email/email1.svg",
	email2 = dir .. "applets/email/email2.svg",
	email3 = dir .. "applets/email/email3.svg",
	email4 = dir .. "applets/email/email4.svg",
	email5 = dir .. "applets/email/email5.svg",
	email6 = dir .. "applets/email/email6.svg",
	email7 = dir .. "applets/email/email7.svg",
	email8 = dir .. "applets/email/email8.svg",
	email9 = dir .. "applets/email/email9.svg",
	email_many = dir .. "applets/email/email9+.svg",
	email_unread = dir .. "applets/email/email-unread.svg",
}

icons.applets.media = {
	music = dir .. "applets/media/music.svg",
	pause = dir .. "applets/media/pause.svg",
	play = dir .. "applets/media/play.svg",
	next = dir .. "applets/media/next.svg",
	prev = dir .. "applets/media/prev.svg",
	random_on = dir .. "applets/media/random-on.svg",
	random_off = dir .. "applets/media/random-off.svg",
	repeat_on = dir .. "applets/media/repeat-on.svg",
	repeat_off = dir .. "applets/media/repeat-off.svg",
}

icons.applets.notifications = {
	dismiss_notification = dir .. "applets/notifications/dismiss-notification.svg",
	clear_all = dir .. "applets/notifications/clear-all.svg",
	dont_disturb_mode = dir .. "applets/notifications/dont-disturb-mode.svg",
	notify_mode = dir .. "applets/notifications/notify-mode.svg",
	empty_notification = dir .. "applets/notifications/empty-notification.svg",
	new_notification = dir .. "applets/notifications/new-notification.svg",
}

icons.applets.resources = {
	cpu = dir .. "applets/resource-monitor/cpu.svg",
	gpu = dir .. "applets/resource-monitor/gpu.svg",
	ram = dir .. "applets/resource-monitor/memory.svg",
	storage = dir .. "applets/resource-monitor/storage.svg",
	hdd = dir .. "applets/resource-monitor/hdd.svg",
	ssd = dir .. "applets/resource-monitor/ssd.svg",
	temp = dir .. "applets/resource-monitor/thermometer.svg",
	net = dir .. "applets/resource-monitor/network.svg",
}

icons.applets.weather = {
	sun_icon = dir .. "applets/weather/sun_icon.svg",
	moon_icon = dir .. "applets/weather/moon_icon.svg",
	dfew_clouds = dir .. "applets/weather/dfew_clouds.svg",
	nfew_clouds = dir .. "applets/weather/nfew_clouds.svg",
	dscattered_clouds = dir .. "applets/weather/dscattered_clouds.svg",
	nscattered_clouds = dir .. "applets/weather/nscattered_clouds.svg",
	dbroken_clouds = dir .. "applets/weather/dbroken_clouds.svg",
	nbroken_clouds = dir .. "applets/weather/nbroken_clouds.svg",
	dshower_rain = dir .. "applets/weather/dshower_rain.svg",
	nshower_rain = dir .. "applets/weather/nshower_rain.svg",
	drain = dir .. "applets/weather/d_rain.svg",
	nrain = dir .. "applets/weather/n_rain.svg",
	dthunderstorm = dir .. "applets/weather/dthunderstorm.svg",
	nthunderstorm = dir .. "applets/weather/nthunderstorm.svg",
	dsnow = dir .. "applets/weather/dsnow.svg",
	nsnow = dir .. "applets/weather/nsnow.svg",
	dmist = dir .. "applets/weather/dmist.svg",
	nmist = dir .. "applets/weather/nmist.svg",
	weather_error = dir .. "applets/weather/weather_error.svg",
	sunrise = dir .. "applets/weather/sunrise.svg",
	sunset = dir .. "applets/weather/sunset.svg",
}

icons.widgets = {}

icons.widgets.server = {
	server = dir .. "widgets/server/server.svg",
	server_time = dir .. "widgets/server/server-time.svg",
	server_crash = dir .. "widgets/server/server-crash.svg",
	server_online = dir .. "widgets/server/server-online.svg",
	server_disconnect = dir .. "widgets/server/server-disconnect.svg",
	server_connected = dir .. "widgets/server/server-connected.svg",
}

icons.widgets.update = {
	shield = dir .. "widgets/update-manager/shield.svg",
	shield_check = dir .. "widgets/update-manager/shield-check.svg",
	shield_alert = dir .. "widgets/update-manager/shield-alert.svg",
	shield_x = dir .. "widgets/update-manager/shield-x.svg",
	shield_off = dir .. "widgets/update-manager/shield-off.svg",
}

icons.widgets.package = {
	package_check = dir .. "widgets/package-manager/package-check.svg",
	package_x = dir .. "widgets/package-manager/package-x.svg",
	package_plus = dir .. "widgets/package-manager/package-plus.svg",
	package_minus = dir .. "widgets/package-manager/package-minus.svg",
	package_search = dir .. "widgets/package-manager/package-search.svg",
}

icons.widgets.battery = {
	battery_alert = dir .. "widgets/battery/battery-alert.svg",
	battery_alert_red = dir .. "widgets/battery/battery-alert-red.svg",
	battery_unknown = dir .. "widgets/battery/battery-unknown.svg",
}

icons.widgets.battery.discharging = {
	battery_0 = dir .. "widgets/battery/discharging/battery-0.svg",
	battery_5 = dir .. "widgets/battery/discharging/battery-5.svg",
	battery_10 = dir .. "widgets/battery/discharging/battery-10.svg",
	battery_15 = dir .. "widgets/battery/discharging/battery-15.svg",
	battery_20 = dir .. "widgets/battery/discharging/battery-20.svg",
	battery_25 = dir .. "widgets/battery/discharging/battery-25.svg",
	battery_30 = dir .. "widgets/battery/discharging/battery-30.svg",
	battery_35 = dir .. "widgets/battery/discharging/battery-35.svg",
	battery_40 = dir .. "widgets/battery/discharging/battery-40.svg",
	battery_45 = dir .. "widgets/battery/discharging/battery-45.svg",
	battery_50 = dir .. "widgets/battery/discharging/battery-50.svg",
	battery_55 = dir .. "widgets/battery/discharging/battery-55.svg",
	battery_60 = dir .. "widgets/battery/discharging/battery-60.svg",
	battery_65 = dir .. "widgets/battery/discharging/battery-65.svg",
	battery_70 = dir .. "widgets/battery/discharging/battery-70.svg",
	battery_75 = dir .. "widgets/battery/discharging/battery-75.svg",
	battery_80 = dir .. "widgets/battery/discharging/battery-80.svg",
	battery_85 = dir .. "widgets/battery/discharging/battery-85.svg",
	battery_90 = dir .. "widgets/battery/discharging/battery-90.svg",
	battery_95 = dir .. "widgets/battery/discharging/battery-95.svg",
	battery_100 = dir .. "widgets/battery/discharging/battery-100.svg",
}

icons.widgets.battery.charging = {
	battery_charging_0 = dir .. "widgets/battery/charging/battery-charging-0.svg",
	battery_charging_5 = dir .. "widgets/battery/charging/battery-charging-5.svg",
	battery_charging_10 = dir .. "widgets/battery/charging/battery-charging-10.svg",
	battery_charging_15 = dir .. "widgets/battery/charging/battery-charging-15.svg",
	battery_charging_20 = dir .. "widgets/battery/charging/battery-charging-20.svg",
	battery_charging_25 = dir .. "widgets/battery/charging/battery-charging-25.svg",
	battery_charging_30 = dir .. "widgets/battery/charging/battery-charging-30.svg",
	battery_charging_35 = dir .. "widgets/battery/charging/battery-charging-35.svg",
	battery_charging_40 = dir .. "widgets/battery/charging/battery-charging-40.svg",
	battery_charging_45 = dir .. "widgets/battery/charging/battery-charging-45.svg",
	battery_charging_50 = dir .. "widgets/battery/charging/battery-charging-50.svg",
	battery_charging_55 = dir .. "widgets/battery/charging/battery-charging-55.svg",
	battery_charging_60 = dir .. "widgets/battery/charging/battery-charging-60.svg",
	battery_charging_65 = dir .. "widgets/battery/charging/battery-charging-65.svg",
	battery_charging_70 = dir .. "widgets/battery/charging/battery-charging-70.svg",
	battery_charging_75 = dir .. "widgets/battery/charging/battery-charging-75.svg",
	battery_charging_80 = dir .. "widgets/battery/charging/battery-charging-80.svg",
	battery_charging_85 = dir .. "widgets/battery/charging/battery-charging-85.svg",
	battery_charging_90 = dir .. "widgets/battery/charging/battery-charging-90.svg",
	battery_charging_95 = dir .. "widgets/battery/charging/battery-charging-95.svg",
	battery_charging_100 = dir .. "widgets/battery/charging/battery-charging-100.svg",
}

icons.widgets.brightness = {
	brightness = dir .. "widgets/brightness/brightness.svg",
}

icons.widgets.volume = {
	volume_muted = dir .. "widgets/volume/volume-muted.svg",
	volume_off = dir .. "widgets/volume/volume-off.svg",
	volume_low = dir .. "widgets/volume/volume-low.svg",
	volume_medium = dir .. "widgets/volume/volume-medium.svg",
	volume_high = dir .. "widgets/volume/volume-high.svg",

	headphones = dir .. "widgets/volume/headphones.svg",
	headphones_muted = dir .. "widgets/volume/headphones-muted.svg",
}

icons.widgets.microphone = {
	mic_muted = dir .. "widgets/microphone/microphone-muted.svg",
	microphone = dir .. "widgets/microphone/microphone.svg",
	mic_low = dir .. "widgets/microphone/microphone-low.svg",
	mic_medium = dir .. "widgets/microphone/microphone-medium.svg",
	mic_high = dir .. "widgets/microphone/microphone-high.svg",
}

icons.widgets.bluetooth = {
	bluetooth_off = dir .. "widgets/bluetooth/bluetooth-off.svg",
	bluetooth_on = dir .. "widgets/bluetooth/bluetooth.svg",
	bluetooth_scanning = dir .. "widgets/bluetooth/bluetooth-scanning.svg",
	bluetooth_connected = dir .. "widgets/bluetooth/bluetooth-connected.svg",
}

icons.widgets.wifi = {
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

	wifi_strength_alert = dir .. "widgets/wifi/.svg",
	wifi_strength_alert_outline = dir .. "widgets/wifi/.svg",
}

icons.widgets.ethernet = {
	eth_disconnected = dir .. "widgets/ethernet/wired-disconnect.svg",
	eth_connecting = dir .. "widgets/ethernet/wired-connecting.svg",
	eth_connected = dir .. "widgets/ethernet/wired-connected.svg",
	eth_no_route = dir .. "widgets/ethernet/wired-no-route.svg",
}

return icons
