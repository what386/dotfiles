local M = {}

-- Lazy load utility modules
M.platform = require("utils.platform")
M.gpu_adapter = require("utils.gpu-adapter")
M.stdlib = require("utils.stdlib")
M.cells = require("utils.cells")

return M
