return {
	"folke/noice.nvim",
	config = function()
		require("noice").setup({
			lsp = {
				override = {
					["vim.lsp.util.convert_input_to_markdown_lines"] = true,
					["vim.lsp.util.stylize_markdown"] = true,
					["cmp.entry.get_documentation"] = true,
				},
			},
			position = {
				row = "100%",
				col = "100%",
			},
			presets = {
				bottom_search = true,
				command_palette = true,
				long_message_to_split = true,
				inc_rename = false,
				lsp_doc_border = false,
			},
			views = {
				cmdline_popup = {
					position = { row = "100%", col = "88%" },
					size = { width = 50, height = "auto" },
					anchor = "SE",
					border = { style = "rounded" },
					win_options = { winhighlight = "NormalFloat:NormalFloat" },
				},
				popupmenu = {
					relative = "editor",
					position = { row = "100%", col = "100%" },
					size = { width = 50, height = 10 },
					anchor = "SE",
					border = { style = "rounded" },
				},
				notify = {
					replace = true,
					merge = true,
					position = { row = "100%", col = "100%" },
					anchor = "SE",
				},
			},
		})
	end,
	event = "VeryLazy",
	opts = {
		-- add any options here
	},
	dependencies = {
		"MunifTanjim/nui.nvim",
		"rcarriga/nvim-notify",
	},
}
