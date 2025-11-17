local defaults = { noremap = true, silent = true }

function map(mode, lhs, rhs, opts)
	local options = defaults
	if opts then
		options = vim.tbl_extend("force", options, opts)
	end
	vim.keymap.set(mode, lhs, rhs, options)
end

-- Set leader key (must be before any leader mappings)
vim.g.mapleader = " "
vim.g.maplocalleader = " "
map({ "n", "v" }, "<Space>", "<Nop>")

-- Commands
vim.api.nvim_create_user_command("Wf", ":noautocmd w <CR>", { nargs = 0 }) -- write (no formatting)

-- ============================================================================
-- ERGONOMICS: Better defaults and quality of life
-- ============================================================================

-- Better escape sequences
map("i", "jk", "<ESC>")
map("i", "kj", "<ESC>")

-- Keep cursor centered during navigation
map("n", "<C-d>", "<C-d>zz")
map("n", "<C-u>", "<C-u>zz")
map("n", "n", "nzzzv")
map("n", "N", "Nzzzv")
map("n", "J", "mzJ`z")

-- Better wrapped line navigation
map("n", "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
map("n", "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })

-- Quick line start/end
map({ "n", "v" }, "H", "_")
map({ "n", "v" }, "L", "$")

-- Clear search highlighting
map("n", "<Esc>", "<cmd>nohlsearch<CR>")

-- Terminal mode navigation
map("t", "<Esc>", "<C-\\><C-n>")
map("t", "<C-h>", "<C-\\><C-n><C-w>h")
map("t", "<C-j>", "<C-\\><C-n><C-w>j")
map("t", "<C-k>", "<C-\\><C-n><C-w>k")
map("t", "<C-l>", "<C-\\><C-n><C-w>l")

-- ============================================================================
-- <leader>y: YANK operations (clipboard)
-- ============================================================================

map({ "n", "v" }, "<leader>y", [["+y]], { desc = "[Y]ank to clipboard" })
map("n", "<leader>Y", [["+Y]], { desc = "[Y]ank line to clipboard" })

-- ============================================================================
-- <leader>p: PASTE operations (clipboard)
-- ============================================================================

map({ "n", "v" }, "<leader>p", [["+p]], { desc = "[P]aste from clipboard" })
map({ "n", "v" }, "<leader>P", [["+P]], { desc = "[P]aste before from clipboard" })

-- Keep clipboard when pasting over selection
map("v", "p", '"_dP')
map("x", "p", [["_dP]])

-- ============================================================================
-- <leader>d: DELETE operations (no yank)
-- ============================================================================

map({ "n", "v" }, "<leader>d", [["_d]], { desc = "[D]elete (no yank)" })
map({ "n", "v" }, "x", [["_x]])
map({ "n", "v" }, "X", [["_X]])
map("n", "<leader>dw", [[:%s/\s\+$//e<CR>]], { desc = "[D]elete trailing [W]hitespace" })
map("n", "<leader>dp", "yyp", { desc = "[D]u[P]licate line" })
map("v", "<leader>dp", "y`>p", { desc = "[D]u[P]licate selection" })

-- ============================================================================
-- <leader>s: SEARCH and REPLACE operations
-- ============================================================================

map("n", "<leader>s", ":%s/\\v", { desc = "[S]earch and replace" })
map("v", "<leader>s", ":s/\\v", { desc = "[S]earch and replace in selection" })
map("n", "<leader>sw", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]], { desc = "[S]earch [W]ord and replace" })
map("n", "<leader>sa", "ggVG", { desc = "[S]elect [A]ll" })
map("n", "<leader>sp", "`[v`]", { desc = "[S]elect [P]asted" })

-- ============================================================================
-- <leader>w: WINDOW management
-- ============================================================================

map("n", "<leader>wv", "<C-w>v", { desc = "[W]indow split [V]ertical" })
map("n", "<leader>wh", "<C-w>s", { desc = "[W]indow split [H]orizontal" })
map("n", "<leader>we", "<C-w>=", { desc = "[W]indow [E]qualize" })
map("n", "<leader>wx", ":close<CR>", { desc = "[W]indow e[X]it" })
map("n", "<leader>wo", "<C-w>o", { desc = "[W]indow [O]nly (close others)" })

-- Window navigation
map("n", "<C-h>", "<C-w>h")
map("n", "<C-j>", "<C-w>j")
map("n", "<C-k>", "<C-w>k")
map("n", "<C-l>", "<C-w>l")

-- Window resizing
map("n", "<C-Up>", ":resize +2<CR>")
map("n", "<C-Down>", ":resize -2<CR>")
map("n", "<C-Left>", ":vertical resize -2<CR>")
map("n", "<C-Right>", ":vertical resize +2<CR>")

-- ============================================================================
-- <leader>b: BUFFER management
-- ============================================================================

map("n", "<Tab>", ":bnext<CR>")
map("n", "<S-Tab>", ":bprevious<CR>")
map("n", "<leader>x", ":Bdelete!<CR>", { desc = "e[X]it buffer" })
map("n", "<leader>bx", ":Bdelete!<CR>", { desc = "[B]uffer e[X]it" })
map("n", "<leader>bX", ":%bd|e#|bd#<CR>", { desc = "[B]uffer e[X]it all except current" })
map("n", "<leader>bn", "<cmd>enew<CR>", { desc = "[B]uffer [N]ew" })

-- ============================================================================
-- <leader>q: QUICKFIX and diagnostics (debugging)
-- ============================================================================

-- Quickfix list
map("n", "<leader>qo", ":copen<CR>", { desc = "[Q]uickfix [O]pen" })
map("n", "<leader>qc", ":cclose<CR>", { desc = "[Q]uickfix [C]lose" })
map("n", "<leader>qn", ":cnext<CR>", { desc = "[Q]uickfix [N]ext" })
map("n", "<leader>qp", ":cprev<CR>", { desc = "[Q]uickfix [P]revious" })
map("n", "<leader>qf", ":cfirst<CR>", { desc = "[Q]uickfix [F]irst" })
map("n", "<leader>ql", ":clast<CR>", { desc = "[Q]uickfix [L]ast" })

-- Diagnostics
map("n", "<leader>qd", vim.diagnostic.open_float, { desc = "[Q]uickfix show [D]iagnostic" })
map("n", "<leader>qq", vim.diagnostic.setloclist, { desc = "[Q]uickfix diagnostic list" })
map("n", "[d", vim.diagnostic.goto_prev, { desc = "Previous diagnostic" })
map("n", "]d", vim.diagnostic.goto_next, { desc = "Next diagnostic" })

-- ============================================================================
-- <leader>m: Make file operations
-- ============================================================================
map("n", "<leader>rr", function()
	local filetype = vim.bo.filetype
	local filename = vim.fn.expand("%")
	local runners = {
		python = "python3 " .. filename,
		javascript = "node " .. filename,
		lua = "lua " .. filename,
		sh = "bash " .. filename,
	}
	local cmd = runners[filetype]
	if cmd then
		vim.cmd("!" .. cmd)
	else
		print("No runner configured for filetype: " .. filetype)
	end
end, { desc = "[R]un current file" })

map("n", "<leader>rx", ":!chmod +x %<CR>", { desc = "[R]un chmod e[X]ecutable" })
map("n", "<leader>rs", ":source %<CR>", { desc = "[R]un file [S]ource" })

-- Expand %% to current file's directory in command mode
vim.keymap.set("c", "%%", function()
	if vim.fn.getcmdtype() == ":" then
		return vim.fn.expand("%:h") .. "/"
	else
		return "%%"
	end
end, { expr = true, desc = "Expand to current file directory" })

-- ============================================================================
-- <leader>g: GIT operations (Gitsigns)
-- ============================================================================
map("n", "<leader>gb", ":Gitsigns blame_line<CR>", { desc = "[G]it [B]lame line" })
map("n", "<leader>gB", ":Gitsigns blame<CR>", { desc = "[G]it [B]lame" })
map("n", "<leader>gd", ":Gitsigns diffthis<CR>", { desc = "[G]it [D]iff" })
map("n", "<leader>gD", ":Gitsigns toggle_deleted<CR>", { desc = "[G]it toggle [D]eleted" })
map("n", "<leader>gp", ":Gitsigns preview_hunk<CR>", { desc = "[G]it [P]review hunk" })
map("n", "<leader>gs", ":Gitsigns stage_hunk<CR>", { desc = "[G]it [S]tage hunk" })
map("v", "<leader>gs", ":Gitsigns stage_hunk<CR>", { desc = "[G]it [S]tage hunk" })
map("n", "<leader>gu", ":Gitsigns undo_stage_hunk<CR>", { desc = "[G]it [U]ndo stage hunk" })
map("n", "<leader>gr", ":Gitsigns reset_hunk<CR>", { desc = "[G]it [R]eset hunk" })
map("v", "<leader>gr", ":Gitsigns reset_hunk<CR>", { desc = "[G]it [R]eset hunk" })
map("n", "<leader>gS", ":Gitsigns stage_buffer<CR>", { desc = "[G]it [S]tage buffer" })
map("n", "<leader>gR", ":Gitsigns reset_buffer<CR>", { desc = "[G]it [R]eset buffer" })
-- Hunk navigation
map("n", "]h", ":Gitsigns next_hunk<CR>", { desc = "Next git hunk" })
map("n", "[h", ":Gitsigns prev_hunk<CR>", { desc = "Previous git hunk" })
-- Text objects for hunks
map({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>", { desc = "Inside git hunk" })

-- ============================================================================
-- <leader>u: UI TOGGLES
-- ============================================================================
map("n", "<leader>uw", ":set wrap!<CR>", { desc = "[U]I toggle [W]rap" })
map("n", "<leader>ur", ":set relativenumber!<CR>", { desc = "[U]I toggle [R]elative numbers" })
map("n", "<leader>us", ":set spell!<CR>", { desc = "[U]I toggle [S]pell check" })
map("n", "<leader>uc", function()
	if vim.opt.conceallevel:get() == 0 then
		vim.opt.conceallevel = 2
	else
		vim.opt.conceallevel = 0
	end
end, { desc = "[U]I toggle [C]onceal" })

-- ============================================================================
-- <leader>o: TEXT OBJECTS and MOTIONS
-- ============================================================================

-- Insert blank lines without leaving normal mode
map("n", "<leader>o", "o<ESC>", { desc = "[O]pen line below" })
map("n", "<leader>O", "O<ESC>", { desc = "[O]pen line above" })

-- Better text objects
map("o", "ae", ":<C-u>normal! ggVG<CR>", { desc = "Around entire buffer" })
map("x", "ae", ":<C-u>normal! ggVG<CR>", { desc = "Around entire buffer" })
map("o", "il", ":<C-u>normal! ^v$h<CR>", { desc = "Inside line (no whitespace)" })
map("x", "il", ":<C-u>normal! ^v$h<CR>", { desc = "Inside line (no whitespace)" })

-- ============================================================================
-- <leader>z: FOLDING
-- ============================================================================

map("n", "<leader>zo", "zo", { desc = "[Z]fold [O]pen" })
map("n", "<leader>zc", "zc", { desc = "[Z]fold [C]lose" })
map("n", "<leader>za", "za", { desc = "[Z]fold toggle" })
map("n", "<leader>zO", "zR", { desc = "[Z]fold [O]pen all" })
map("n", "<leader>zC", "zM", { desc = "[Z]fold [C]lose all" })

-- ============================================================================
-- VISUAL MODE: Indent and move lines
-- ============================================================================

-- Stay in indent mode
map("v", "<", "<gv")
map("v", ">", ">gv")

-- Move lines up/down
map("n", "<A-j>", ":m .+1<CR>==")
map("n", "<A-k>", ":m .-2<CR>==")
map("v", "<A-j>", ":m '>+1<CR>gv=gv")
map("v", "<A-k>", ":m '<-2<CR>gv=gv")

-- Shift+Arrow fallback (if Alt doesn't work)
map("n", "<S-Down>", ":m .+1<CR>==")
map("n", "<S-Up>", ":m .-2<CR>==")
map("v", "<S-Down>", ":m '>+1<CR>gv=gv")
map("v", "<S-Up>", ":m '<-2<CR>gv=gv")

-- ============================================================================
-- MISC: Useful one-off mappings
-- ============================================================================

-- Undo breakpoints for better granularity
map("i", ",", ",<C-g>u")
map("i", ".", ".<C-g>u")
map("i", "!", "!<C-g>u")
map("i", "?", "?<C-g>u")
map("i", ";", ";<C-g>u")

-- Command history with filtering
map("c", "<C-p>", "<Up>", { noremap = true })
map("c", "<C-n>", "<Down>", { noremap = true })

-- Join lines without space
map("n", "gJ", ":join!<CR>")

-- Split line at cursor (opposite of J)
map("n", "K", "i<CR><Esc>")

-- Re-select pasted text
map("n", "gp", "`[v`]")

-- Keep cursor at start when yanking
map("v", "y", "ygv<Esc>")
