return {
	"nvim-treesitter/nvim-treesitter",
	build = ":TSUpdate",
	main = "nvim-treesitter.configs",

	config = function()
		require("config.treesitter.manual").register()

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
