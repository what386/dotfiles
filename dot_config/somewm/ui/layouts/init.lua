local awful = require("awful")
local layout_loader = require("ui.layouts.loader")

local default_layouts = {
	awful.layout.suit.carousel,
	awful.layout.suit.spiral.dwindle,
	awful.layout.suit.tile,
	awful.layout.suit.floating,
	awful.layout.suit.max,
}

local custom_layouts = {
	"centered",
}

local final_layouts = {}
for _, v in ipairs(layout_loader(custom_layouts)) do final_layouts[#final_layouts + 1] = v end
for _, v in ipairs(default_layouts) do final_layouts[#final_layouts + 1] = v end

awful.layout.layouts = final_layouts
