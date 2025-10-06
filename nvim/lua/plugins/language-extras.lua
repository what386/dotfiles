-- anything related to language support / language extensions go here
return {
	{ -- autoclose of brackets, quotes etc.
		"windwp/nvim-autopairs",
		event = "InsertEnter",
		config = true,
		opts = {},
	},
	{ -- powershell support
		"TheLeoP/powershell.nvim",
		---@type powershell.user_config
		opts = {
			bundle_path = vim.fn.stdpath("data") .. "/mason/packages/powershell-editor-services",
		},
	},
	{ -- java support
		"nvim-java/nvim-java",
	},
}
