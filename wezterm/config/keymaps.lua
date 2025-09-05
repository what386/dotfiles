local wezterm = require("wezterm")
local act = wezterm.action

local M = {}

local function create_keys()
    local keys = {
        -- VI mode
        { key = "v", mods = "LEADER", action = act.ActivateCopyMode },

        -- Pane management
        { key = "-", mods = "LEADER", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },
        { key = "=", mods = "LEADER", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
        { key = "r", mods = "LEADER", action = act.ActivateKeyTable({ name = "resize", one_shot = false }) },
        { key = "z", mods = "LEADER", action = act.TogglePaneZoomState },

        -- Tab management
        { key = "e", mods = "LEADER", action = act.SpawnTab("CurrentPaneDomain") },
        { key = "q", mods = "LEADER", action = act.CloseCurrentPane({ confirm = true }) },
        { key = "[", mods = "LEADER", action = act.ActivateTabRelative(-1) },
        { key = "]", mods = "LEADER", action = act.ActivateTabRelative(1) },
        { key = "t", mods = "LEADER", action = act.ShowTabNavigator },
        { key = "m", mods = "LEADER", action = act.ActivateKeyTable({ name = "move", one_shot = false }) },

        -- Workspace management
        { key = "p", mods = "LEADER", action = act.ShowLauncherArgs({ flags = "WORKSPACES" }) },
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
                        window:perform_action(act.SwitchToWorkspace({ name = line }), pane)
                    end
                end),
            }),
        },
    }

    -- Add tab switching keys (1-9)
    for i = 1, 9 do
        table.insert(keys, {
            key = tostring(i),
            mods = "LEADER",
            action = act.ActivateTab(i - 1),
        })
    end

    return keys
end

local function create_key_tables()
    return {
        resize = {
            { key = "h",      action = act.AdjustPaneSize({ "Left", 1 }) },
            { key = "j",      action = act.AdjustPaneSize({ "Down", 1 }) },
            { key = "k",      action = act.AdjustPaneSize({ "Up", 1 }) },
            { key = "l",      action = act.AdjustPaneSize({ "Right", 1 }) },
            { key = "Escape", action = "PopKeyTable" },
            { key = "Enter",  action = "PopKeyTable" },
        },
        move = {
            { key = "h",      action = act.MoveTabRelative(-1) },
            { key = "j",      action = act.MoveTabRelative(-1) },
            { key = "k",      action = act.MoveTabRelative(1) },
            { key = "l",      action = act.MoveTabRelative(1) },
            { key = "Escape", action = "PopKeyTable" },
            { key = "Enter",  action = "PopKeyTable" },
        },
        font = {
            { key = "k",      action = act.IncreaseFontSize },
            { key = "j",      action = act.DecreaseFontSize },
            { key = "r",      action = act.ResetFontSize },
            { key = "Escape", action = "PopKeyTable" },
            { key = "q",      action = "PopKeyTable" },
        },
    }
end

local function create_mouse_bindings()
    return {
        -- Ctrl-click to open links
        {
            event = { Up = { streak = 1, button = "Left" } },
            mods = "CTRL",
            action = act.OpenLinkAtMouseCursor,
        },
    }
end

function M.apply(config)
    config.leader = { key = "LeftAlt", timeout_milliseconds = 1000 }
    config.keys = create_keys()
    config.key_tables = create_key_tables()
    config.mouse_bindings = create_mouse_bindings()
end

return M
