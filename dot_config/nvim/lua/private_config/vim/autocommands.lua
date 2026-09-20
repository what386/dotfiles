vim.api.nvim_create_user_command("TrimWhitespace", function()
	local view = vim.fn.winsaveview()
	vim.cmd([[%s/\s\+$//e]])
	vim.fn.winrestview(view)
end, { desc = "Remove trailing whitespace from the current buffer" })

-- Retire empty placeholder buffers once a real file is opened.
vim.api.nvim_create_autocmd("BufEnter", {
	group = vim.api.nvim_create_augroup("close-empty-unnamed-buffers", { clear = true }),
	callback = function(event)
		local file = event.buf
		vim.schedule(function()
			if not vim.api.nvim_buf_is_valid(file) or vim.api.nvim_get_current_buf() ~= file then
				return
			end
			local name = vim.api.nvim_buf_get_name(file)
			if vim.bo[file].buftype ~= "" or name == "" or vim.fn.isdirectory(name) == 1 then
				return
			end
			for _, buf in ipairs(vim.api.nvim_list_bufs()) do
				if
					buf ~= file
					and vim.api.nvim_buf_is_loaded(buf)
					and vim.bo[buf].buflisted
					and vim.bo[buf].buftype == ""
					and not vim.bo[buf].modified
					and vim.api.nvim_buf_get_name(buf) == ""
					and #vim.fn.win_findbuf(buf) == 0
					and vim.api.nvim_buf_line_count(buf) == 1
					and vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1] == ""
				then
					vim.api.nvim_buf_delete(buf, { force = false })
				end
			end
		end)
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
