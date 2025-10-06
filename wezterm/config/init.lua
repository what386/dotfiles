local M = {}

function M.apply(config)
    -- Apply core configuration modules
    require("config.options").apply(config)
    require("config.keymaps").apply(config)
    require("config.domains").apply(config)
end

return M
