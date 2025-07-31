local awful = require("awful")
local gears = require("gears")
local layout_loader = require("ui.layouts.loader")

local default_layouts = {
	awful.layout.suit.spiral.dwindle,
	--awful.layout.suit.tile,
	awful.layout.suit.floating,
	awful.layout.suit.max,
}

local custom_layouts = {
	"centered",
}

local final_layouts = gears.table.join(layout_loader(custom_layouts), default_layouts)

awful.layout.layouts = final_layouts
