return {
	"nvim-treesitter/nvim-treesitter",
	build = ":TSUpdate",
	main = "nvim-treesitter.configs",

	config = function()
		-- Register the Hydrogen parser BEFORE setting up treesitter
		--local parser_config = require("nvim-treesitter.parsers").get_parser_configs()

		--parser_config.hydrogen = {
		--	install_info = {
		--		url = vim.fn.expand("~/.config/nvim/treesitter/hydrogen"),
		--		files = { "src/parser.c" },
		--		branch = "main",
		--		generate_requires_npm = false,
		--		requires_generate_from_grammar = false,
		--	},
		--	filetype = "hydrogen",
		--}

		-- Register the .hy file extension
		--vim.filetype.add({
		--	extension = {
		--		hy = "hydrogen",
		--	},
		--})

		-- Configure treesitter
		require("nvim-treesitter.configs").setup({
			ensure_installed = {
				"lua",
				"python",
				"sql",
				"dockerfile",
				"json",
				"gitignore",
				"graphql",
				"markdown",
				"markdown_inline",
				"css",
				"html",
				"javascript",
				"cpp",
				"make",
				"cmake",
				"c_sharp",
				"bash",
				"powershell",
				"vimdoc",
				"vim",
				"regex",
				-- Note: Don't add "hydrogen" here, it's a local parser
			},
			auto_install = true,
			highlight = {
				enable = true,
				additional_vim_regex_highlighting = { "ruby" },
			},
			indent = { enable = true, disable = { "ruby" } },
		})
	end,
}
