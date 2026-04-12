-- anything with around 5 lines of config go here
return {
	{ -- language icons
		"nvim-tree/nvim-web-devicons",
	},
	{ -- detect tabstop and shiftwidth automatically
		"tpope/vim-sleuth",
	},
	{ -- keybind hints
		"folke/which-key.nvim",
	},
	{ -- highlight todo comments
		"folke/todo-comments.nvim",
		event = "VimEnter",
		dependencies = { "nvim-lua/plenary.nvim" },
		opts = { signs = false },
	},
	{ -- highlight hex color codes
		"norcalli/nvim-colorizer.lua",
		config = function()
			require("colorizer").setup()
		end,
	},
	{ -- lua functions
		"nvim-lua/plenary.nvim",
	},
	{ -- vim window function ports
		"nvim-lua/popup.nvim",
	},
	{ -- lowercase user commands
		"gcmt/cmdfix.nvim",
		config = function()
			require("cmdfix").setup({
				enabled = true, -- enable or disable plugin
				threshold = 2, -- minimum characters to consider before fixing the command
				ignore = { "Next" }, -- won't be fixed (default value)
				aliases = { Wf = "wf" }, -- custom aliases
			})
		end,
	},
	{ -- debug attacher
		"mfussenegger/nvim-dap",
	},
}
