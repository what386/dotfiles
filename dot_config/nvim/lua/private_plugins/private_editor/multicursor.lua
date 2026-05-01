return {
    "jake-stewart/multicursor.nvim",
    branch = "1.0",
    config = function()
        local mc = require("multicursor-nvim")
        mc.setup()

        local function map(mode, lhs, rhs, opts)
            local options = { noremap = true, silent = true }
            if opts then
                options = vim.tbl_extend("force", options, opts)
            end
            vim.keymap.set(mode, lhs, rhs, options)
        end

        -- Add or skip cursor above/below the main cursor.
        map({"n", "x"}, "<up>",            function() mc.lineAddCursor(-1) end,  { desc = "Add cursor above" })
        map({"n", "x"}, "<down>",          function() mc.lineAddCursor(1) end,   { desc = "Add cursor below" })
        map({"n", "x"}, "<leader><up>",    function() mc.lineSkipCursor(-1) end, { desc = "Skip cursor above" })
        map({"n", "x"}, "<leader><down>",  function() mc.lineSkipCursor(1) end,  { desc = "Skip cursor below" })

        -- Add or skip adding a new cursor by matching word/selection.
        map({"n", "x"}, "<leader>n", function() mc.matchAddCursor(1) end,   { desc = "Add cursor on next match" })
        map({"n", "x"}, "<leader>s", function() mc.matchSkipCursor(1) end,  { desc = "Skip cursor on next match" })
        map({"n", "x"}, "<leader>N", function() mc.matchAddCursor(-1) end,  { desc = "Add cursor on prev match" })
        map({"n", "x"}, "<leader>S", function() mc.matchSkipCursor(-1) end, { desc = "Skip cursor on prev match" })

        -- Add and remove cursors with control + left click.
        map("n", "<c-leftmouse>",   mc.handleMouse,        { desc = "Toggle cursor on click" })
        map("n", "<c-leftdrag>",    mc.handleMouseDrag,    { desc = "Add cursors by dragging" })
        map("n", "<c-leftrelease>", mc.handleMouseRelease, { desc = "Finish cursor drag" })

        -- Disable and enable cursors.
        map({"n", "x"}, "<c-q>", mc.toggleCursor, { desc = "Toggle cursor" })

        -- Mappings defined in a keymap layer only apply when there are
        -- multiple cursors. This lets you have overlapping mappings.
        mc.addKeymapLayer(function(layerSet)
            local function lmap(mode, lhs, rhs, opts)
                local options = { noremap = true, silent = true }
                if opts then
                    options = vim.tbl_extend("force", options, opts)
                end
                layerSet(mode, lhs, rhs, options)
            end

            -- Select a different cursor as the main one.
            lmap({"n", "x"}, "<left>",     mc.prevCursor,   { desc = "Select prev cursor" })
            lmap({"n", "x"}, "<right>",    mc.nextCursor,   { desc = "Select next cursor" })

            -- Delete the main cursor.
            lmap({"n", "x"}, "<leader>x",  mc.deleteCursor, { desc = "Delete cursor" })

            -- Enable and clear cursors using escape.
            lmap("n", "<esc>", function()
                if not mc.cursorsEnabled() then
                    mc.enableCursors()
                else
                    mc.clearCursors()
                end
            end, { desc = "Enable/clear cursors" })
        end)

        -- Customize how cursors look.
        local hl = vim.api.nvim_set_hl
        hl(0, "MultiCursorCursor",          { reverse = true })
        hl(0, "MultiCursorVisual",          { link = "Visual" })
        hl(0, "MultiCursorSign",            { link = "SignColumn" })
        hl(0, "MultiCursorMatchPreview",    { link = "Search" })
        hl(0, "MultiCursorDisabledCursor",  { reverse = true })
        hl(0, "MultiCursorDisabledVisual",  { link = "Visual" })
        hl(0, "MultiCursorDisabledSign",    { link = "SignColumn" })
    end
}
