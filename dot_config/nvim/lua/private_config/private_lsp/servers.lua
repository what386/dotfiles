-- Enable the following language servers
return {
	-- Application languages
	jdtls = {}, -- Java
	csharp_ls = {}, -- C#

	-- Systems languages
	rust_analyzer = {},
	zls = {},
	gopls = {},

	-- Web
	html = { filetypes = { "html", "twig", "hbs" } },
	tailwindcss = {},
	ts_ls = {}, -- or vtsls = {}
	ruby_lsp = {},

	-- Shell / Docker
	bashls = {},
	powershell_es = {},
	basedpyright = {},
	ruff = {},
	shellcheck = {},

	-- Embedded
	lua_ls = {
		settings = {
			Lua = {
				workspace = { checkThirdParty = false },
				telemetry = { enable = false },
				diagnostics = { disable = { "missing-fields" } },
			},
		},
	},

	-- Other
	jsonls = {},
	taplo = {},
	yamlls = {},
	sqlls = {},
	actionlint = {},
	dockerls = {},
	docker_compose_language_service = {},

	-- Custom
	clangd = require("config.lsp.custom.clangd")
}
