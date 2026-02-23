local wezterm = require("wezterm")
local resurrect = wezterm.plugin.require("https://github.com/MLFlexer/resurrect.wezterm")

local M = {}

-- Create resurrect-specific keybindings
local function create_resurrect_keys()
    return {
        -- Save workspace state
        {
            key = "w",
            mods = "ALT",
            action = wezterm.action_callback(function(win, pane)
                resurrect.state_manager.save_state(resurrect.workspace_state.get_workspace_state())
            end),
        },
        -- Save window state
        {
            key = "W",
            mods = "ALT",
            action = resurrect.window_state.save_window_action(),
        },
        -- Save tab state
        {
            key = "T",
            mods = "ALT",
            action = resurrect.tab_state.save_tab_action(),
        },
        -- Save all states
        {
            key = "s",
            mods = "ALT",
            action = wezterm.action_callback(function(win, pane)
                resurrect.state_manager.save_state(resurrect.workspace_state.get_workspace_state())
                resurrect.window_state.save_window_action()
            end),
        },
        -- Restore with fuzzy finder
        {
            key = "r",
            mods = "ALT",
            action = wezterm.action_callback(function(win, pane)
                resurrect.fuzzy_loader.fuzzy_load(win, pane, function(id, label)
                    local type = string.match(id, "^([^/]+)") -- match before '/'
                    id = string.match(id, "([^/]+)$") -- match after '/'
                    id = string.match(id, "(.+)%..+$") -- remove file extension
                    local opts = {
                        relative = true,
                        restore_text = true,
                        on_pane_restore = resurrect.tab_state.default_on_pane_restore,
                    }
                    if type == "workspace" then
                        local state = resurrect.state_manager.load_state(id, "workspace")
                        resurrect.workspace_state.restore_workspace(state, opts)
                    elseif type == "window" then
                        local state = resurrect.state_manager.load_state(id, "window")
                        resurrect.window_state.restore_window(pane:window(), state, opts)
                    elseif type == "tab" then
                        local state = resurrect.state_manager.load_state(id, "tab")
                        resurrect.tab_state.restore_tab(pane:tab(), state, opts)
                    end
                end)
            end),
        },
    }
end

function M.apply(config)
    -- Get existing keys or initialize empty table
    local existing_keys = config.keys or {}

    -- Append resurrect keys to existing keys
    local resurrect_keys = create_resurrect_keys()
    for _, key in ipairs(resurrect_keys) do
        table.insert(existing_keys, key)
    end

    -- Set the combined keys back to config
    config.keys = existing_keys
end

return M

