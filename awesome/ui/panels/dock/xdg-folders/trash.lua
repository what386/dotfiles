local wibox = require("wibox")
local awful = require("awful")
local gears = require("gears")

local clickable_container = require("ui.clickable-container")
local dpi = require("beautiful").xresources.apply_dpi

local icons = require("theme.icons")

local trash_widget = wibox.widget({
	{
		id = "trash_icon",
		image = icons.folders.trash_empty,
		resize = true,
		widget = wibox.widget.imagebox,
	},
	layout = wibox.layout.align.horizontal,
})

local trash_menu = awful.menu({
	items = {
		{
			"Open trash",
			function()
				awful.spawn.easy_async_with_shell("gio open trash:///", function(stdout) end, 1)
			end,
			icons.folders.open_folder,
		},
		{
			"Delete forever",
			{
				{
					"Yes",
					function()
						awful.spawn.easy_async_with_shell("gio trash --empty", function(stdout) end, 1)
					end,
					icons.system.yes,
				},
				{
					"No",
					"",
					icons.system.no,
				},
			},
			image = icons.folders.trash_empty,
		},
	},
})

local trash_button = wibox.widget({
	{
		trash_widget,
		margins = dpi(10),
		widget = wibox.container.margin,
	},
	widget = clickable_container,
})

-- Tooltip for trash_button
trash_tooltip = awful.tooltip({
	objects = { trash_button },
	mode = "outside",
	align = "right",
	markup = "Trash",
	margin_leftright = dpi(8),
	margin_topbottom = dpi(8),
	preferred_positions = { "bottom", "top", "right", "left" },
})

-- Mouse event for trash_button
trash_button:buttons(gears.table.join(
	awful.button({}, 1, nil, function()
		awful.spawn({ "gio", "open", "trash:///" }, false)
	end),
	awful.button({}, 3, nil, function()
		trash_menu:toggle()
		trash_tooltip.visible = not trash_tooltip.visible
	end)
))

-- Update icon on changes
local check_trash_list = function()
	awful.spawn.easy_async_with_shell("gio list trash:/// | wc -l", function(stdout)
		if tonumber(stdout) > 0 then
			trash_widget.trash_icon:set_image(icons.folders.trash_full)

			awful.spawn.easy_async_with_shell("gio list trash:///", function(stdout)
				trash_tooltip.markup = "<b>Trash contains:</b>\n" .. stdout:gsub("\n$", "")
			end)
		else
			trash_widget.trash_icon:set_image(icons.folders.trash_empty)
			trash_tooltip.markup = "Empty"
		end
	end)
end

-- Check trash on awesome (re)-start
check_trash_list()

-- Kill the old process of gio monitor trash:///
awful.spawn.easy_async_with_shell(
	"ps x | grep 'gio monitor trash:///' | grep -v grep | awk '{print  $1}' | xargs kill",
	function()
		awful.spawn.with_line_callback("gio monitor trash:///", {
			stdout = function(_)
				check_trash_list()
			end,
		})
	end
)

return trash_button
