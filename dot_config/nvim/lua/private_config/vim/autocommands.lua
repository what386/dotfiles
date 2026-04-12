-- Trim trailing whitespace on save
vim.api.nvim_create_autocmd("BufWritePre", {
	pattern = "*",
	callback = function()
		vim.cmd([[%s/\s\+$//e]])
	end,
})

-- Autoreload config
vim.api.nvim_create_autocmd("BufWritePost", {
	pattern = "~/.config/nvim/*",
	callback = function()
		vim.cmd("source <afile>")
		print("Reloaded nvim config!")
	end,
})

-- Highlight yanked text
vim.api.nvim_create_autocmd("TextYankPost", {
	callback = function()
		vim.highlight.on_yank({ higroup = "IncSearch", timeout = 200 })
	end,
})

-- Remember last cursor position
vim.api.nvim_create_autocmd("BufReadPost", {
	callback = function()
		local mark = vim.api.nvim_buf_get_mark(0, '"')
		local lcount = vim.api.nvim_buf_line_count(0)
		if mark[1] > 0 and mark[1] <= lcount then
			pcall(vim.api.nvim_win_set_cursor, 0, mark)
		end
	end,
})

-- Auto-create missing directories
vim.api.nvim_create_autocmd("BufWritePre", {
	callback = function()
		local file = vim.fn.expand("%:p:h")
		if vim.fn.isdirectory(file) == 0 then
			vim.fn.mkdir(file, "p")
		end
	end,
})

-- Enable spellcheck for txt and md
vim.api.nvim_create_autocmd("FileType", {
	pattern = { "markdown", "text" },
	callback = function()
		vim.opt_local.spell = true
		vim.opt_local.wrap = true
	end,
})

-- Auto reload changed files
vim.api.nvim_create_autocmd("FocusGained", {
	callback = function()
		vim.cmd("checktime")
	end,
})

-- Show diagnostics on cursor idle
vim.api.nvim_create_autocmd("CursorHold", {
	callback = function()
		vim.diagnostic.open_float(nil, { focus = false })
	end,
})
