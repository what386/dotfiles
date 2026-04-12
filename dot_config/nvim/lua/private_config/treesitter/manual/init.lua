local M = {}

local manual_parsers = {
	require("config.treesitter.manual.lash"),
}

function M.register()
	local parser_config = require("nvim-treesitter.parsers").get_parser_configs()

	for _, parser in ipairs(manual_parsers) do
		parser_config[parser.name] = {
			install_info = parser.install_info,
			filetype = parser.filetype,
		}
	end
end

return M
