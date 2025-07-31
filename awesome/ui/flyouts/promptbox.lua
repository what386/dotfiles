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
		prompt = "Run Lua: ",
		textbox = prompt.widget,
		history_path = awful.util.get_cache_dir() .. "/history_eval",

		exe_callback = function(input)
			if not input or input == "" then
				prompt_popup.visible = false
				return
			end

			local result, err
			local output_buffer = {}

			-- Override print to capture output
			local env = setmetatable({}, { __index = _G })
			env.print = function(...)
				local args = { ... }
				for i = 1, #args do
					args[i] = tostring(args[i])
				end
				table.insert(output_buffer, table.concat(args, "\t"))
			end

			local chunk, syntax_err = load("return " .. input, "prompt_input", "t", env)
			if not chunk then
				chunk, syntax_err = load(input, "prompt_input", "t", env)
			end

			if chunk then
				local success, output = pcall(chunk)
				if success then
					-- If there's no return value but something was printed, show that
					if output == nil and #output_buffer > 0 then
						result = table.concat(output_buffer, "\n")
					else
						result = tostring(output)
					end
				else
					err = output
				end
			else
				err = syntax_err
			end

			prompt_popup.visible = false

			naughty.notify({
				title = "Prompt Output",
				text = result or ("Error: " .. tostring(err)),
				timeout = 5,
				preset = naughty.config.presets.normal,
			})
		end,

		done_callback = function()
			prompt_popup.visible = false
		end,
	})
end

-- Connect to your custom signal
awesome.connect_signal("module::promptbox:activate", function()
	show_prompt()
end)
