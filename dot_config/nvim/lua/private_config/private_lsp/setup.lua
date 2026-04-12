-- Enable the following language servers
return {
	-- Lua
	lua_ls = {
		settings = {
			Lua = {
				runtime = { version = "LuaJIT" },
				workspace = {
					checkThirdParty = false,
					-- Tells lua_ls where to find all the Lua files that you have loaded
					-- for your Neovim configuration.
					library = {
						"${3rd}/luv/library",
						unpack(vim.api.nvim_get_runtime_file("", true)),
					},
					-- If lua_ls is really slow on your computer, you can try this instead:
					-- library = { vim.env.VIMRUNTIME },
				},
				completion = { callSnippet = "Replace" },
				telemetry = { enable = false },
				diagnostics = { disable = { "missing-fields" } },
			},
		},
	},

	-- Python
	pylsp = {
		settings = {
			pylsp = {
				plugins = {
					pyflakes = { enabled = false },
					pycodestyle = { enabled = false },
					autopep8 = { enabled = false },
					yapf = { enabled = false },
					mccabe = { enabled = false },
					pylsp_mypy = { enabled = false },
					pylsp_black = { enabled = false },
					pylsp_isort = { enabled = false },
				},
			},
		},
	},
	ruff = {}, -- Complimentary Python LSP

	-- Java / C#
	jdtls = {},
	csharp_ls = {},

	-- Rust
	rust_analyzer = {},

	-- Web / Frontend
	html = { filetypes = { "html", "twig", "hbs" } },
	tailwindcss = {},
	ts_ls = {},

	-- Ruby
	ruby_lsp = {},

	-- JSON / SQL
	jsonls = {},
	sqlls = {},

	-- Zig
	zls = {},

	-- Go
	gopls = {},

	-- Shell
	bashls = {},
	lash_lsp = {
		mason = false,
		cmd = { "lashlsp" },
		filetypes = { "lash" },
		root_markers = { ".git" },
	},

	-- Docker
	dockerls = {},
	docker_compose_language_service = {},
}
