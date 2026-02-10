local function default_parser_dir()
	local config_dir = vim.fn.stdpath("config")
	local real_config_dir = vim.uv.fs_realpath(config_dir) or config_dir
	return vim.fn.fnamemodify(real_config_dir .. "/treesitter/brash", ":p")
end

return {
	name = "brash",
	filetype = "brash",
	install_info = {
		url = default_parser_dir(),
		files = { "src/parser.c" },
		generate_requires_npm = false,
		requires_generate_from_grammar = false,
	},
}
