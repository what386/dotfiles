local M = {}

function M.apply(config)
    -- Load theme modules in order
    require("theme.fonts").apply(config)
    require("theme.colors").apply(config)
    require("theme.appearance").apply(config)
end

return M
