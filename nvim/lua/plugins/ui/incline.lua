return {
	"b0o/incline.nvim",
	opts = {},
	event = "VeryLazy",
	config = function()
		local fg = ""
		local bg = "#00000000"

		local devicons = require("nvim-web-devicons")
		local incline = require("incline")
		local manager = require("incline.manager")
		local util = require("incline.util")

		local function get_git_diff(buf)
			local icons = { removed = "", changed = "", added = "" }
			local signs = vim.b[buf].gitsigns_status_dict
			local labels = {}
			if signs == nil then
				return labels
			end
			for name, icon in pairs(icons) do
				if tonumber(signs[name]) and signs[name] > 0 then
					table.insert(labels, { icon .. signs[name] .. " ", group = "Diff" .. name })
				end
			end
			if #labels > 0 then
				table.insert(labels, { "┊ " })
			end
			return labels
		end

		incline.setup({
			render = function(props)
				if not props.focused then
					return
				end

				local mode = vim.api.nvim_get_mode().mode
				local fmt_mode = ""

				if mode:match("^[vV�]") then
					fmt_mode = "Visual"
				elseif mode:match("^[iI�]") then
					fmt_mode = "Insert"
				elseif mode:match("^[cC�]") then
					fmt_mode = "Command"
				else
					fmt_mode = "Normal"
				end

				local reg = vim.fn.reg_recording()

				if reg ~= "" then
					fmt_mode = string.format("%s  %s", reg, fmt_mode)
				end

				return {
					{ get_git_diff(props.buf), guifg = fg, guibg = bg },
					{ fmt_mode, guifg = fg, guibg = bg },
				}
			end,
			window = {
				margin = { horizontal = 1, vertical = 1 },
				placement = { horizontal = "right", vertical = "bottom" },
			},
		})

		util.clear_augroup()

		vim.api.nvim_create_autocmd({ "RecordingEnter", "RecordingLeave", "ModeChanged", "CursorMoved" }, {
			callback = function()
				manager.update({ refresh = true })
			end,
		})

		-- Horrible jank to load two panels

		package.loaded["incline"] = false
		package.loaded["incline.config"] = false
		package.loaded["incline.debounce"] = false
		package.loaded["incline.highlight"] = false
		package.loaded["incline.manager"] = false
		package.loaded["incline.tabpage"] = false
		package.loaded["incline.util"] = false
		package.loaded["incline.winline"] = false

		local incline = require("incline")
		local manager = require("incline.manager")
		local util = require("incline.util")

		local fg = "#ffffff"
		local bg = "#00000000"

		incline.setup({
			render = function(props)
				local filename = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(props.buf), ":t")
				if filename == "" then
					filename = "[No Name]"
				end
				local ft_icon, ft_color = devicons.get_icon_color(filename)

				if not props.focused then
					return
				end

				local cursorinfo = ""
				local mode = vim.api.nvim_get_mode().mode

				if mode:match("^[vV�]") then
					local start = vim.fn.getpos("v")
					local c = vim.api.nvim_win_get_cursor(0)

					local row = math.abs(start[2] - c[1]) + 1
					local column = 0

					if c[2] >= start[3] then
						column = c[2] - start[3] + 2
					else
						column = start[3] - c[2]
					end

					cursorinfo = string.format("%d⋮%d", row, column)
				end

				if cursorinfo == "" then
					local c = vim.api.nvim_win_get_cursor(0)
					cursorinfo = string.format("%d⋮%d", c[1], c[2])
				end

				return {
					{
						(ft_icon or "") .. " ",
						guifg = ft_color,
						guibg = "none",
					},
					{ filename .. " | ", gui = vim.bo[props.buf].modified and "bold,italic" or "bold" },
					{ cursorinfo },
				}
			end,
			window = {
				margin = { horizontal = 1, vertical = 1 },
				placement = { horizontal = "left", vertical = "bottom" },
			},
		})

		util.clear_augroup()

		vim.api.nvim_create_autocmd({ "CursorMoved", "TextChanged", "ModeChanged" }, {
			callback = function()
				manager.update({ refresh = true })
			end,
		})
	end,
}
