local wezterm = require("wezterm")
local act = wezterm.action

local M = {}

wezterm.on("user-var-changed", function(window, pane, name, value)
	if name ~= "WEZTERM_WORKSPACE_PICKER" then
		return
	end

	-- Close the temporary picker tab while its pane is still the active target.
	window:perform_action(act.CloseCurrentTab({ confirm = false }), pane)
	window:perform_action(
		act.SwitchToWorkspace({ name = value }),
		window:active_pane()
	)
end)

function M.switch(window, pane)
	local workspaces = wezterm.mux.get_workspace_names()
	table.sort(workspaces)

	local args = { "bash", wezterm.config_dir .. "/scripts/workspace-picker.sh" }
	for _, workspace in ipairs(workspaces) do
		table.insert(args, workspace)
	end

	-- Do not let a persistent resize/move key table consume picker input.
	window:perform_action(act.PopKeyTable, pane)
	window:perform_action(
		act.SpawnCommandInNewTab({ args = args }),
		pane
	)
end

return M
