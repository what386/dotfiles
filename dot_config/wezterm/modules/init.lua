local M = {}

function M.apply(config)
	-- Load in-house modules and their event registrations.
	require("modules.workspace")
	require("modules.pane_move")
	require("modules.projects").apply(config)
end

return M
