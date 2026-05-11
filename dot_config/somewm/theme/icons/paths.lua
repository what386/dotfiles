local gfs = require("gears.filesystem")

local config_dir = gfs.get_configuration_dir()

return {
	config_dir = config_dir,
	theme_icons_dir = config_dir .. "theme/icons/",
}
