require("config")

-- Install lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
	local lazyrepo = "https://github.com/folke/lazy.nvim.git"
	local out = vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"--branch=stable",
		lazyrepo,
		lazypath,
	})
	if vim.v.shell_error ~= 0 then
		error("Error cloning lazy.nvim:\n" .. out)
	end
end
vim.opt.rtp:prepend(lazypath)
vim.opt.termguicolors = true

require("lazy").setup({
	require("plugins.editor.gitsigns"),
	require("plugins.editor.neotree"),
	require("plugins.editor.smart-splits"),
	require("plugins.editor.telescope"),
	require("plugins.editor.treesitter"),
	require("plugins.editor.oil"),
	require("plugins.editor.multicursor"),

	require("plugins.lsp.language-server"),
	require("plugins.lsp.blink-cmp"),
	require("plugins.lsp.none-ls"),

	require("plugins.ui.alpha"),
	require("plugins.ui.colortheme"),
	require("plugins.ui.indent-blankline"),
	require("plugins.ui.noice"),
	require("plugins.ui.incline"),

	require("plugins.extras.language-extras"),
	require("plugins.extras.misc"),
}, {
	icons = vim.g.have_nerd_font and {} or {
		cmd = "⌘",
		config = "🛠",
		event = "📅",
		ft = "📂",
		init = "⚙",
		keys = "🗝",
		plugin = "🔌",
		runtime = "💻",
		require = "🌙",
		source = "📄",
		start = "🚀",
		task = "📌",
		lazy = "💤 ",
	},
})

print("config loaded!")
