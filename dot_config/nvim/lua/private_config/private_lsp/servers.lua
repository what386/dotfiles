-- Enable the following language servers
return {
	-- Application languages
	jdtls = {}, -- Java
	csharp_ls = {}, -- C#
	ruby_lsp = {}, -- Ruby
	pylsp = {}, -- Python
	ruff = {}, -- Python linting/formatting LSP

	-- Systems languages
	rust_analyzer = {},
	zls = {},
	gopls = {},
	asm_lsp = {},

	-- Web
	html = {
		filetypes = { "html", "twig", "hbs" },
	},
	tailwindcss = {},
	ts_ls = {},

	-- Shell
	bashls = {},
	powershell_es = {},

	-- Docker
	dockerls = {},
	docker_compose_language_service = {},

	-- Embedded
	arduino_language_server = {},

	-- Lua
	lua_ls = {
		settings = {
			Lua = {
				workspace = {
					checkThirdParty = false,
				},
				telemetry = {
					enable = false,
				},
				diagnostics = {
					disable = { "missing-fields" },
				},
			},
		},
	},

	-- Markup and configuration
	jsonls = {},
	yamlls = {},
	taplo = {},
	tinymist = {},

	-- SQL
	sqlls = {},
}
