local beautiful = require("beautiful")

local gtable = require("gears.table")
local theme_options = require("theme.options")
local theme_colors = require("theme.colors")

local final_theme = {}
gtable.crush(final_theme, theme_options.theme)
gtable.crush(final_theme, theme_colors.theme)
theme_options.awesome_overrides(final_theme)
theme_colors.awesome_overrides(final_theme)

beautiful.init(final_theme)

require("theme.wallpapers")
require("theme.sounds")
