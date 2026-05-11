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
		network_manager = "nm-connection-editor",
		bluetooth_manager = "blueman-manager",
		power_manager = "gnome-power-statistics",
		package_manager = "pacman",
		quake = "kitty --class QuakeTerminal",

		-- TODO: fix this
		global_search = "echo nope",

		appmenu_search = "wofi"
			.. " --conf " .. config_dir .. "/dependencies/wofi/appmenu/config"
			.. " --style " .. config_dir .. "/dependencies/wofi/appmenu/style.css"
			.. "--xoffset=-225"
			.. "--yoffset=-100"
			.. " --show drun"
			.. " --layer=overlay"
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
		--full_screenshot = "snap full",
		--gui_screenshot = "flameshot gui",
		update_profile = scripts_dir .. "update_profile.sh",
	},
}
