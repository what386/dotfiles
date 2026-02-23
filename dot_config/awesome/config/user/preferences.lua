local filesystem = require("gears.filesystem")
local config_dir = filesystem.get_configuration_dir()
local scripts_dir = config_dir .. "scripts/"

return {
	default = {
		terminal = "wezterm",
		development = "nvim",
		web_browser = "zen",
		text_editor = "nano",
		file_manager = "nemo",
		multimedia = "vlc",
		photo_editor = "gimp",
		sandbox = "virt-manager",
		network_manager = "cinnamon-settings network",
		bluetooth_manager = "blueman-manager",
		power_manager = "gnome-power-statistics",
		package_manager = "mintinstall",
		package_updater = "mintupdate",
		lock = "",
		quake = "kitty --name QuakeTerminal",
		scratchpad = "kitty --name QuakeScratchpad",

		rofi_global = "rofi -dpi "
			.. screen.primary.dpi
			.. ' -show "Global Search" -modi "Global Search":'
			.. config_dir
			.. "/dependencies/rofi/global/rofi-spotlight.sh"
			.. " -theme "
			.. config_dir
			.. "/dependencies/rofi/global/rofi.rasi",

		rofi_appmenu = "rofi -dpi "
			.. screen.primary.dpi
			.. " -show drun -theme "
			.. config_dir
			.. "/dependencies/rofi/appmenu/rofi.rasi",
	},

	lockscreen = {
		fallback_password = "", -- currently non-functional
		capture_intruder = true,
		bg_image = "locksreen-bg.jpg",
		blur_background = false,
		tmp_wall_dir = "/tmp/awesomewm/" .. os.getenv("USER") .. "/",
	},

	wallpaper = {
		directory = "theme/wallpapers/",
		valid_formats = { "jpg", "png", "jpeg" },

		schedule = {
			["00:00:00"] = "midnight-wallpaper.jpg",
			["06:22:00"] = "morning-wallpaper.jpg",
			["12:00:00"] = "noon-wallpaper.jpg",
			["17:58:00"] = "night-wallpaper.jpg",
		},
		-- Stretch background image across all screens(monitor)
		stretch = false,
	},

	-- List of binaries/shell scripts that will execute for a certain task
	utils = {
		full_screenshot = "snap full",
		gui_screenshot = "flameshot gui",
		update_profile = scripts_dir .. "update_profile.sh",
	},
}
