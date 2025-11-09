require("core.options")
require("core.keymaps")

-- Register hydrogen filetype EARLY (before lazy)
--vim.filetype.add({
--    extension = {
--        hy = "hydrogen",
--        hydrogen = "hydrogen",
--    },
--})

-- install lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
    local lazyrepo = "https://github.com/folke/lazy.nvim.git"
    local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
    if vim.v.shell_error ~= 0 then
        error("Error cloning lazy.nvim:\n" .. out)
    end
end
vim.opt.rtp:prepend(lazypath)
vim.opt.termguicolors = true

require("lazy").setup({
    require("plugins.colortheme"),
    require("plugins.neotree"),
    require("plugins.bufferline"),
    require("plugins.lualine"),
    require("plugins.smart-splits"),
    require("plugins.treesitter"),
    require("plugins.telescope"),
    require("plugins.lsp"),
    require("plugins.autocompletion"),
    require("plugins.none-ls"),
    require("plugins.language-extras"),
    require("plugins.alpha"),
    require("plugins.indent-blankline"),
    require("plugins.gitsigns"),
    require("plugins.misc"),
})

--vim.opt.runtimepath:append(vim.fn.stdpath("config") .. "/languages/hydrogen")
--dofile(vim.fn.stdpath("config") .. "/languages/hydrogen/lua/hydrogen/init.lua")
