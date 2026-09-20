-- Format on save and linters
return {
	"nvimtools/none-ls.nvim",
	dependencies = {
		"nvimtools/none-ls-extras.nvim",
	},
	config = function()
		local null_ls = require("null-ls")
		local formatting = null_ls.builtins.formatting
		local diagnostics = null_ls.builtins.diagnostics

		local sources = {
			-- ── Diagnostics / Linters ────────────────────────────────────────
			diagnostics.checkmake,
			diagnostics.hadolint, -- Dockerfile
			diagnostics.dotenv_linter, -- .env files
			diagnostics.yamllint, -- YAML
			diagnostics.markdownlint, -- Markdown (markdownlint-cli2)
			diagnostics.rstcheck, -- reStructuredText
			diagnostics.sqlfluff.with({ -- SQL
				extra_args = { "--dialect", "ansi" }, -- change dialect as needed
			}),
			require("none-ls.diagnostics.eslint_d"), -- JS/TS

			-- ── Formatters ───────────────────────────────────────────────────
			-- C / C++
			formatting.clang_format.with({
				command = "clang-format",
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

			-- CMake
			formatting.cmake_format, -- cmakelang

			-- PowerShell (none-ls has no built-in; handled by powershell_es LSP)
		}

		null_ls.setup({
			-- debug = true, -- Enable debug mode. Inspect logs with :NullLsLog.
			sources = sources,
		})
	end,
}
