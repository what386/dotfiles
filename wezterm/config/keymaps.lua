wezterm = require("wezterm")
local act = require("wezterm").action

local keys = {
	-- VI doing
	{ key = "v", mods = "LEADER", action = act.ActivateCopyMode },

	-- pane keybinds
	{ key = "-", mods = "LEADER", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },
	{ key = "=", mods = "LEADER", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
	{ key = "r", mods = "LEADER", action = act.ActivateKeyTable({ name = "resize", one_shot = false }) },
	{ key = "z", mods = "LEADER", action = act.TogglePaneZoomState },

	-- tab navigation
	{ key = "e", mods = "LEADER", action = act.SpawnTab("CurrentPaneDomain") },
	{ key = "q", mods = "LEADER", action = act.CloseCurrentPane({ confirm = true }) },
	{ key = "[", mods = "LEADER", action = act.ActivateTabRelative(-1) },
	{ key = "]", mods = "LEADER", action = act.ActivateTabRelative(1) },
	{ key = "t", mods = "LEADER", action = act.ShowTabNavigator },
	{ key = "m", mods = "LEADER", action = act.ActivateKeyTable({ name = "move", one_shot = false }) },

	-- workspace navigation
	{ key = "p", mods = "LEADER", action = wezterm.action.ShowLauncherArgs({ flags = "WORKSPACES" }) },
	{
		key = "o",
		mods = "LEADER",
		action = act.PromptInputLine({
			description = wezterm.format({
				{ Attribute = { Intensity = "Bold" } },
				{ Foreground = { AnsiColor = "Fuchsia" } },
				{ Text = "Name for new workspace:" },
			}),
			action = wezterm.action_callback(function(window, pane, line)
				if line then
					window:perform_action(
						act.SwitchToWorkspace({
							name = line,
						}),
						pane
					)
				end
			end),
		}),
	},

	-- plugin keybinds
	--{ key = "s", mods = "LEADER", action = workspace_switcher.switch_workspace(), },
	--{ key = "p", mods = "LEADER", action = workspace_switcher.switch_to_prev_workspace(), },
}

-- jump between tabs with <LDR 1-9>
for i = 1, 9 do
	table.insert(keys, {
		key = tostring(i),
		mods = "LEADER",
		action = act.ActivateTab(i - 1),
	})
end

local key_tables = {
	resize = {
		{ key = "h", action = act.AdjustPaneSize({ "Left", 1 }) },
		{ key = "j", action = act.AdjustPaneSize({ "Down", 1 }) },
		{ key = "k", action = act.AdjustPaneSize({ "Up", 1 }) },
		{ key = "l", action = act.AdjustPaneSize({ "Right", 1 }) },
		{ key = "Escape", action = "PopKeyTable" },
		{ key = "Enter", action = "PopKeyTable" },
	},
	move = {
		{ key = "h", action = act.MoveTabRelative(-1) },
		{ key = "j", action = act.MoveTabRelative(-1) },
		{ key = "k", action = act.MoveTabRelative(1) },
		{ key = "l", action = act.MoveTabRelative(1) },
		{ key = "Escape", action = "PopKeyTable" },
		{ key = "Enter", action = "PopKeyTable" },
	},
	font = {
		{ key = "k", action = act.IncreaseFontSize },
		{ key = "j", action = act.DecreaseFontSize },
		{ key = "r", action = act.ResetFontSize },
		{ key = "Escape", action = "PopKeyTable" },
		{ key = "q", action = "PopKeyTable" },
	},
}

local mouse_bindings = {
	-- Ctrl-click will open the link under the mouse cursor
	{
		event = { Up = { streak = 1, button = "Left" } },
		mods = "CTRL",
		action = act.OpenLinkAtMouseCursor,
	},
}

return {
	leader = { key = "LeftAlt", timeout_milliseconds = 1000 },
	keys = keys,
	key_tables = key_tables,
	mouse_bindings = mouse_bindings,
}
