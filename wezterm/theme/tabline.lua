local wezterm = require("wezterm")
local fonts = wezterm.nerdfonts
local tabline = wezterm.plugin.require("https://github.com/michaelbrusegard/tabline.wez")

local function get_key_table_name(mode, window)
	if window:active_key_table() == "copy_mode" then
		return fonts.cod_copy .. "  COPY "
	end
	if window:active_key_table() == "resize" then
		return fonts.md_resize .. " RESIZE"
	end
	if window:active_key_table() == "move" then
		return fonts.cod_move .. "  MOVE "
	end

	return window:active_key_table()
end

return {
	tabline.setup({
		options = {
			icons_enabled = true,
			theme = "One Dark (Gogh)",
			tabs_enabled = true,
			theme_overrides = {},
			section_separators = {
				left = fonts.ple_lower_left_triangle,
				--right = fonts.ple_upper_right_triangle,
			},
			component_separators = {
				left = "|",
				right = "|",
			},
			tab_separators = {
				left = "",
				right = "",
			},
		},
		sections = {
			tabline_a = {
				{
					"mode",
					icons_enabled = false,
					fmt = function(mode, window)
						if window:leader_is_active() then
							return fonts.cod_record_keys .. " LEADER"
						end

						if window:active_key_table() then
							return get_key_table_name(mode, window)
						end

						return fonts.cod_terminal_powershell .. " " .. mode
					end,
				},
			},
			tabline_b = { "workspace" },
			tabline_c = { "|", padding = 1 },

			tab_active = {
				"index",
				{ "process", padding = 1 },
				"output",
			},
			tab_inactive = {
				"index",
				{ "process", padding = 1 },
				"output",
			},

			tabline_x = { "|" },
			tabline_y = {},
			tabline_z = { "domain" },
		},
		extensions = {
			--'resurrect',
			--'smart_workspace_switcher',
		},
	}),
}
