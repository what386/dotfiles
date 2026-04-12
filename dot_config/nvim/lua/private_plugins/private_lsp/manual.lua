vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
	pattern = { "*.axaml" },
	callback = function(event)
		vim.lsp.start({
			name = "avalonia",
			cmd = { "avalonia-ls" },
			root_dir = vim.fn.getcwd(),
		})
	end,
})
vim.filetype.add({
	extension = {
		axaml = "xml",
	},
})
