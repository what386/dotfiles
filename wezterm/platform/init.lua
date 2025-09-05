local wezterm = require("wezterm")

local M = {}

-- Platform detection
M.is_windows = wezterm.target_triple:match("windows") ~= nil
M.is_macos = wezterm.target_triple:match("apple") ~= nil
M.is_linux = wezterm.target_triple:match("linux") ~= nil

function M.apply(config)
    -- Apply platform-specific configuration
    if M.is_windows then
        require("platform.windows").apply(config)
    elseif M.is_macos then
        require("platform.macos").apply(config)
    elseif M.is_linux then
        require("platform.linux").apply(config)
    end
end

return M
