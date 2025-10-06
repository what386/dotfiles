local beautiful = require("beautiful")
local gears = require("gears")

local config_dir = gears.filesystem.get_configuration_dir()
local icon_dir = config_dir .. "ui/layouts/icons/"

local function get_icon(icon_path)
	if icon_path ~= nil then
		return gears.color.recolor_image(icon_path, beautiful.fg_normal)
	else
		return nil
	end
end

local function load_layouts(layouts)
	local loaded_layouts = {} -- This should be an array, not a hash table

	for _, layout_name in ipairs(layouts) do
		-- Load the layout module
		local layout_module = require("ui.layouts.custom." .. layout_name)

		-- Set up the icon
		local icon_path = icon_dir .. layout_name .. ".png"
		if beautiful["layout_" .. layout_name] == nil then
			beautiful["layout_" .. layout_name] = get_icon(icon_path)
		end

		-- Add to array (not hash table)
		table.insert(loaded_layouts, layout_module)
	end

	return loaded_layouts
end

return load_layouts
