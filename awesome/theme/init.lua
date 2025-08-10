local beautiful = require("beautiful")

local gtable = require("gears.table")
local default_theme = require("theme.default")
local theme = require("theme.flutter")

local final_theme = {}
gtable.crush(final_theme, default_theme.theme)
gtable.crush(final_theme, theme.theme)
default_theme.awesome_overrides(final_theme)
theme.awesome_overrides(final_theme)

require("theme.wallpapers")

beautiful.init(final_theme)

require("theme.sounds")
