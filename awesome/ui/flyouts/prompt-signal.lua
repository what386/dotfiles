local awful = require("awful")
local wibox = require("wibox")
local naughty = require("naughty")
local gears = require("gears")
local beautiful = require("beautiful")
local dpi = beautiful.xresources.apply_dpi
local panel_width = dpi(500)
local panel_height = dpi(50)
local margins = dpi(65)

-- Create the prompt widget
local prompt = awful.widget.prompt()

-- Popup container
local prompt_popup = wibox({
	width = panel_width,
	height = panel_height,
	ontop = true,
	visible = false,
	bg = "#000000cc", -- semi-transparent background
	fg = "#ffffff",
	shape = gears.shape.rounded_rect,
	type = "dialog",
})

-- Set widget layout
prompt_popup:setup({
	{
		{
			prompt,
			margins = 5,
			widget = wibox.container.margin,
		},
		widget = wibox.container.background,
	},
	layout = wibox.layout.align.horizontal,
})

-- Function to show and run prompt
local function show_prompt()
	local screen = awful.screen.focused()
	prompt_popup.screen = screen
	prompt_popup.x = (screen.geometry.width / 2) - panel_width / 2
	prompt_popup.y = (screen.geometry.height - panel_height - margins)
	prompt_popup.visible = true
	awful.prompt.run({
		prompt = "Emit Signal: ",
		textbox = prompt.widget,
		history_path = awful.util.get_cache_dir() .. "/history_signal",
		exe_callback = function(input)
			if not input or input == "" then
				prompt_popup.visible = false
				return
			end

			-- Emit the signal with the input text
			local success, err = pcall(function()
				awesome.emit_signal(input)
			end)

			prompt_popup.visible = false

			-- Show notification about the signal emission
			if success then
				naughty.notify({
					title = "Signal Emitted",
					text = "Signal '" .. input .. "' emitted successfully",
					timeout = 3,
					preset = naughty.config.presets.normal,
				})
			else
				naughty.notify({
					title = "Signal Error",
					text = "Failed to emit signal '" .. input .. "': " .. tostring(err),
					timeout = 5,
					preset = naughty.config.presets.critical,
				})
			end
		end,
		done_callback = function()
			prompt_popup.visible = false
		end,
	})
end

awesome.connect_signal("flyout::signalbox:activate", function()
	show_prompt()
end)
