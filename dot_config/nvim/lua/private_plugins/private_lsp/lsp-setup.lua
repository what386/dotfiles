return { -- LSP Configuration & Plugins
	"neovim/nvim-lspconfig",
	dependencies = {
		-- Automatically install LSPs and related tools to stdpath for neovim
		"williamboman/mason.nvim",
		"williamboman/mason-lspconfig.nvim",
		"WhoIsSethDaniel/mason-tool-installer.nvim",

		-- Useful status updates for LSP.
		-- opts = {} is the same as calling require('fidget').setup({})
		{
			"j-hui/fidget.nvim",
			tag = "v1.4.0",
			opts = {
				progress = {
					display = {
						done_icon = "✓", -- Icon shown when all LSP progress tasks are complete
					},
				},
				notification = {
					window = {
						winblend = 0, -- Background color opacity in the notification window
					},
				},
			},
		},
	},
	config = function()
		vim.api.nvim_create_autocmd("LspAttach", {
			group = vim.api.nvim_create_augroup("lsp-attach", { clear = true }),

			callback = function(event)
				require("config.keymaps.lsp-binds")(event)
				require("config.lsp.format").enable(event.buf)
			end,
		})

		local capabilities = require("blink.cmp").get_lsp_capabilities()

		local servers = require("config.lsp.servers")
		local tools = require("config.lsp.tools")
		local configured_servers = {}

		local function setup_server(server_name)
			if configured_servers[server_name] then
				return
			end
			local server = vim.deepcopy(servers[server_name] or {})
			server.capabilities = vim.tbl_deep_extend("force", {}, capabilities, server.capabilities or {})
			vim.lsp.config(server_name, server)
			vim.lsp.enable(server_name)
			configured_servers[server_name] = true
		end

		-- Ensure the servers and tools above are installed
		require("mason").setup()

		-- You can add other tools here that you want Mason to install
		-- for you, so that they are available from within Neovim.
		local ensure_installed = {}
		local installed = {}
		local function ensure(package)
			if not installed[package] then
				installed[package] = true
				table.insert(ensure_installed, package)
			end
		end
		for server_name, server_opts in pairs(servers or {}) do
			if server_opts.mason ~= false then
				ensure(server_name)
			end
		end
		for _, tool in ipairs(tools) do
			ensure(tool)
		end
		table.sort(ensure_installed)
		require("mason-tool-installer").setup({ ensure_installed = ensure_installed })

		require("mason-lspconfig").setup({
			handlers = {
				function(server_name)
					-- This handles overriding only values explicitly passed
					-- by the server configuration above. Useful when disabling
					-- certain features of an LSP (for example, turning off formatting for tsserver)
					setup_server(server_name)
				end,
			},
		})

		-- Servers marked mason = false must be configured directly.
		for server_name, server_opts in pairs(servers or {}) do
			if server_opts.mason == false then
				setup_server(server_name)
			end
		end
	end,
}
