local preferences = require("config.preferences")

return {
	apps = preferences.apps,
	default = preferences.apps,
	wallpaper = preferences.wallpaper,
	utils = preferences.apps.utils,
}
