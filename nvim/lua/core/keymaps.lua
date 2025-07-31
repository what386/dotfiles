local defaults = { noremap = true, silent = true }

function map(mode, lhs, rhs, opts)
	local options = defaults
	if opts then
		options = vim.tbl_extend("force", options, opts)
	end
	vim.keymap.set(mode, lhs, rhs, options)
end

-- set leader key
map({ "n", "v" }, "<Space>", "<Nop>")
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- commands
vim.api.nvim_create_user_command("Wf", ":noautocmd w <CR>", { nargs = 0 }) -- write (no formatting)
vim.api.nvim_create_user_command(
	"Gfp",
	[[<cmd>let @+ = expand("%:p")<cr><cmd>lua print("Copied path to: " .. vim.fn.expand("%:p"))<cr>]],
	{ nargs = 0 }
) -- get file path and save to register

---- weird VIM defaults that need to be destroyed forever
-- Explicitly yank to system clipboard (highlighted and entire row)
map({ "n", "v" }, "<leader>y", [["+y]])
map("n", "<leader>Y", [["+Y]])

map("v", "p", '"_dP') -- keep yank after pasting

-- stay in indent mode
map("v", "<", "<gv")
map("v", ">", ">gv")

-- allow moving cursor through wrapped lines with j and k
map("n", "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
map("n", "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })

--- scroll and find w/ centering
map("n", "<C-d>", "<C-d>zz")
map("n", "<C-u>", "<C-u>zz")
map("n", "n", "nzzzv")
map("n", "N", "Nzzzv")

---- actual keybinds
-- selections
map("n", "<leader>pa", "ggVGp", { desc = "[P]aste [A]ll" })
map("n", "<leader>sa", "ggVG", { desc = "[S]elect [A]ll" })
map("n", "<leader>sp", "`[v`]", { desc = "[S]elect [P]asted" })

map("n", "<leader>yf", "<cmd>%y<cr>", { desc = "[Y]ank [F]ile" })
map("n", "<leader>df", "<cmd>%d_<cr>", { desc = "[D]elete [F]ile" })

-- search and/or replace
map("n", "<leader>sr", "<cmd>s/\\v", { desc = "[S]earch and [R]eplace" })
map("n", "<leader>SR", "<cmd>%s/\\v", { desc = "[S]earch and [R]eplace (in file)" })

map("n", "<leader>rw", "*``cgn", { desc = "[R]eplace [W]ord" })
map("n", "<leader>rf", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]], { desc = "[R]eplace word in [F]ile" })

-- Shift + Up/Down to move line(s) up/down
map("n", "<S-Up>", "yyddkP")
map("n", "<S-Down>", "yyddp")
-- visual mode jank to allow multi-line movement
map("v", "<S-Up>", "@='xkP`[V`]'<CR>")
map("v", "<S-Down>", "@='xp`[V`]'<CR>")

map("n", "<BS>", "^", { desc = "Move to first non-blank character" })

map("n", "<S-O>", ':<C-u>call append(line(".")-1, repeat([""], v:count1))<CR>') -- shift+o to insert newline

-- jk to return to normal mode
map("i", "jk", "<ESC>")
map("i", "kj", "<ESC>")

-- shift + H or L go to beginning or end of line
map("n", "<S-h>", "_")
map("n", "<S-h>", "$")

-- buffer navigation
map("n", "<Tab>", ":bnext<CR>")       -- next file
map("n", "<S-Tab>", ":bprevious<CR>") -- prev file
map("n", "<leader>x", ":Bdelete!<CR>", { desc = "e[X]it buffer" })
map("n", "<leader>c", "<cmd> enew <CR>", { desc = "[C]reate buffer" })

--for i = 1, 9 d--o
--	local num = tostring(i)
--	map("n", "<leader>" .. num, "<cmd>buffer " .. num .. "<cr>", { desc = "Switch to tab " .. num })
--end

-- Window management
map("n", "<leader>wv", "<C-w>v", { desc = "split [W]indow [V]ertical" })   -- split window vertically
map("n", "<leader>wh", "<C-w>s", { desc = "split [W]indow [H]orizontal" }) -- split window horizontally
map("n", "<leader>we", "<C-w>=", { desc = "split [W]indow [E]qualize" })   -- make split windows equal width & height
map("n", "<leader>wx", ":close<CR>", { desc = "split [W]indow e[X]it" })   -- close current split window

-- Diagnostic keymaps
-- map("n", "[d", vim.diagnostic.goto_prev, { desc = "Go to previous diagnostic message" })
-- map("n", "]d", vim.diagnostic.goto_next, { desc = "Go to next diagnostic message" })
-- map("n", "<leader>d", vim.diagnostic.open_float, { desc = "Open floating diagnostic message" })
-- map("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Open diagnostics list" })
