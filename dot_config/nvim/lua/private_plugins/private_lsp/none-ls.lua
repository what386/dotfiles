-- Format on save and linters
return {
	"nvimtools/none-ls.nvim",
	dependencies = {
		"nvimtools/none-ls-extras.nvim",
		"jayp0521/mason-null-ls.nvim", -- ensure dependencies are installed
	},
	config = function()
		local null_ls = require("null-ls")
		local formatting = null_ls.builtins.formatting
		local diagnostics = null_ls.builtins.diagnostics

		-- list of formatters & linters for mason to install
		require("mason-null-ls").setup({
			ensure_installed = require("config.lsp.formatters"),
			automatic_installation = true,
		})

		local sources = {
			-- ── Diagnostics / Linters ────────────────────────────────────────
			diagnostics.checkmake,
			diagnostics.hadolint, -- Dockerfile
			diagnostics.dotenv_linter, -- .env files
			diagnostics.jsonlint, -- JSON
			diagnostics.yamllint, -- YAML
			diagnostics.markdownlint, -- Markdown (markdownlint-cli2)
			diagnostics.htmlhint, -- HTML
			diagnostics.rstcheck, -- reStructuredText
			diagnostics.sqlfluff.with({ -- SQL
				extra_args = { "--dialect", "ansi" }, -- change dialect as needed
			}),
			require("none-ls.diagnostics.eslint_d"), -- JS/TS

			-- ── Formatters ───────────────────────────────────────────────────
			-- C / C++
			formatting.clang_format.with({
				command = "clang-format-20",
				extra_args = { "--style=file" },
				filetypes = { "c", "cpp" },
			}),

			-- C#
			formatting.csharpier, -- .cs

			-- Java
			formatting.google_java_format, -- .java

			-- Lua
			formatting.stylua,

			-- Shell / Bash
			formatting.shfmt.with({ args = { "-i", "4" } }),

			-- Python
			require("none-ls.formatting.ruff").with({ extra_args = { "--extend-select", "I" } }),
			require("none-ls.formatting.ruff_format"),

			-- JavaScript / TypeScript / HTML / CSS / JSON / YAML / Markdown
			formatting.prettier.with({
				filetypes = {
					"html",
					"css",
					"javascript",
					"javascriptreact",
					"typescript",
					"typescriptreact",
					"json",
					"jsonc",
					"yaml",
					"markdown",
					"graphql",
				},
			}),

			-- Tailwind CSS class sorting (rustywind)
			formatting.rustywind.with({
				filetypes = {
					"html",
					"css",
					"javascript",
					"javascriptreact",
					"typescript",
					"typescriptreact",
				},
			}),

			-- Ruby
			formatting.rubocop, -- .rb

			-- Rust  (rustfmt via rust-analyzer is preferred, but rubocop covers ruby above)

			-- SQL
			formatting.sqlfluff.with({
				extra_args = { "--dialect", "ansi" }, -- change dialect as needed
			}),

			-- Terraform
			formatting.terraform_fmt,

			-- XML
			formatting.xmlformat, -- xmlformatter

			-- CMake
			formatting.cmake_format, -- cmakelang

			-- PowerShell (none-ls has no built-in; handled by powershell_es LSP)
		}

		local augroup = vim.api.nvim_create_augroup("LspFormatting", {})

		null_ls.setup({
			-- debug = true, -- Enable debug mode. Inspect logs with :NullLsLog.
			sources = sources,
			on_attach = function(client, bufnr)
				if client.supports_method("textDocument/formatting") then
					vim.api.nvim_clear_autocmds({ group = augroup, buffer = bufnr })
					vim.api.nvim_create_autocmd("BufWritePre", {
						group = augroup,
						buffer = bufnr,
						callback = function()
							vim.lsp.buf.format({
								async = false,
								filter = function(fmt_client)
									return fmt_client.name == "null-ls"
								end,
							})
						end,
					})
				end
			end,
		})
	end,
}
