local M = {}

function M.apply(config)
    -- Load plugin/module configurations
    require("modules.tabline").apply(config)

    -- Add other modules here as you create them:
    -- require('modules.workspace').apply(config)
    -- require('modules.statusbar').apply(config)
end

return M
