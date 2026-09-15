return {
	"nvim-treesitter/nvim-treesitter",
	branch = "main",
	lazy = false,
	build = ":TSUpdate",

	config = function()
		require("config.treesitter.manual").register()

		local languages = {
			"lua",
			"python",
			"sql",
			"dockerfile",
			"json",
			"toml",
			"gitignore",
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
			"rust",
			"regex",
		}

		local ts = require("nvim-treesitter")

		ts.install(languages)

		vim.api.nvim_create_autocmd("FileType", {
			pattern = "*",
			callback = function(args)
				local ft = vim.bo[args.buf].filetype
				local lang = vim.treesitter.language.get_lang(ft)

				if not lang then
					return
				end

				local ok = pcall(vim.treesitter.start, args.buf, lang)

				if ok and ft ~= "ruby" then
					vim.bo[args.buf].indentexpr =
						"v:lua.require'nvim-treesitter'.indentexpr()"
				end
			end,
		})
	end,
}
