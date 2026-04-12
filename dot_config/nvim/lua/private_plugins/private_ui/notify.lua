return {
	"rcarriga/nvim-notify",
	event = "VimEnter", -- Load on Neovim startup, or choose a more specific event
	config = function()
		-- notify.nvim configuration
		require("notify").setup({
			-- Animation style: "fade_in_slide_out", "slide_in_slide_out", "fade", "static"
			stages = "fade_in_slide_out",

			-- Timeout for notifications in milliseconds (0 = no timeout)
			timeout = 3000,

			-- Maximum width of notification window
			max_width = 60,

			-- Minimum width of notification window
			min_width = 20,

			-- Background color for notifications
			background_colour = "#000000",

			-- Icons for different notification levels
			icons = {
				ERROR = "󰅚 ",
				WARN = " ",
				INFO = " ",
				DEBUG = " ",
				TRACE = "✎ ",
			},

			-- Render function
			render = "default",

			-- Position: "top_left", "top_right", "top", "bottom_left", "bottom_right", "bottom"
			position = "bottom_right",

			-- Highlighting for different levels
			highlight = {
				ERROR = "NotifyERRORTitle",
				WARN = "NotifyWARNTitle",
				INFO = "NotifyINFOTitle",
				DEBUG = "NotifyDEBUGTitle",
				TRACE = "NotifyTRACETitle",
			},

			-- Top-left padding (row, col)
			top_down = false,

			-- Use percentage for max width (0-100)
			max_width_pct = nil,

			-- Combine notifications with the same message
			merge_duplicates = true,

			-- Sort notifications by level (higher severity first)
			level = "info",
		})

		-- Optional: Set up key mappings to manage notifications
		local notify = require("notify")

		-- Dismiss all notifications
		vim.keymap.set("n", "<leader>nd", function()
			notify.dismiss({ pending = true, silent = true })
		end, { noremap = true, silent = true, desc = "Dismiss all notifications" })

		-- Show notification history
		vim.keymap.set("n", "<leader>nh", function()
			notify.history()
		end, { noremap = true, silent = true, desc = "Notification history" })

		-- Optional: Override vim.notify to use notify.nvim
		vim.notify = notify.notify

		-- Optional: Set up notify for LSP, DAP, and other integrations
		-- Uncomment if you want to use notify for LSP notifications
		-- require("vim.lsp.log").set_format_func(vim.inspect)

		-- Optional: Custom notification for startup
		-- notify("Neovim initialized!", "info", { title = "Startup" })
	end,
}
