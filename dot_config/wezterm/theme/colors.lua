local M = {}

function M.apply(config)
	local terminal_bg = "#000000"
	local tabline_bg = "rgba(0, 0, 0, 0.52)"

	-- Color scheme
	config.color_scheme = "Oceanic-Next"

	-- Color overrides
	config.colors = {
		background = terminal_bg,
		tab_bar = {
			background = tabline_bg,
			inactive_tab_edge = tabline_bg,
		},
	}
end

return M
