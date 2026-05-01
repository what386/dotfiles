return {
	"b0o/incline.nvim",
	opts = {},
	event = "VeryLazy",
	config = function()
		local devicons = require("nvim-web-devicons")

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

		local function current_mode_label()
			local mode = vim.api.nvim_get_mode().mode
			if mode:match("^[vV\22]") then
				return "Visual"
			elseif mode:match("^[iI]") then
				return "Insert"
			elseif mode:match("^[cC]") then
				return "Command"
			end
			return "Normal"
		end

		local function current_cursor_info()
			local cursorinfo = ""
			local mode = vim.api.nvim_get_mode().mode

			if mode:match("^[vV\22]") then
				local start = vim.fn.getpos("v")
				local c = vim.api.nvim_win_get_cursor(0)
				local row = math.abs(start[2] - c[1]) + 1
				local column

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

			return cursorinfo
		end

		local function render_bufferline(props)
			if not props.focused then
				return
			end

			local current_buf = vim.api.nvim_win_get_buf(props.win)
			local bufs = vim.fn.getbufinfo({ buflisted = 1 })
			local items = {}
			local max_items = 9
			local added = 0

			for _, buf in ipairs(bufs) do
				if added >= max_items then
					break
				end

				if vim.api.nvim_buf_is_valid(buf.bufnr) then
					local name = vim.fn.fnamemodify(buf.name, ":p:h:t") .. "/" .. vim.fn.fnamemodify(buf.name, ":t")
					if name == "" then
						name = "[No Name]"
					end
					local ft_icon, ft_color = devicons.get_icon_color(name)
					local icon_text = ft_icon and (ft_icon .. " ") or ""

					if #name > 20 then
						name = name:sub(1, 17) .. "..."
					end

					local modified = vim.bo[buf.bufnr].modified and " ●" or ""
					local is_current = buf.bufnr == current_buf
					table.insert(items, {
						is_current and "[" or "",
						{
							icon_text,
							guifg = ft_color,
							guibg = "none",
						},
						name .. modified,
						is_current and "]" or "",
						gui = is_current and "bold" or "none",
					})
					table.insert(items, { "  " })
					added = added + 1
				end
			end

			if #bufs > max_items then
				table.insert(items, { "…" })
			elseif #items > 0 then
				table.remove(items, #items) -- remove trailing spacer
			end

			return items
		end

		local function create_panel(placement, render, events)
			local incline = require("incline")
			local manager = require("incline.manager")
			local util = require("incline.util")

			incline.setup({
				render = render,
				window = {
					margin = { horizontal = 1, vertical = 1 },
					placement = { horizontal = placement, vertical = "bottom" },
				},
			})

			util.clear_augroup()
			vim.api.nvim_create_autocmd(
				events
					or { "RecordingEnter", "RecordingLeave", "ModeChanged", "CursorMoved", "TextChanged" },
				{
					callback = function()
						manager.update({ refresh = true })
					end,
				}
			)
		end

		create_panel("left", function(props)
			if not props.focused then
				return
			end

			local mode = current_mode_label()
			local reg = vim.fn.reg_recording()

			if reg ~= "" then
				mode = string.format("%s  %s", reg, mode)
			end

			return {
				{ mode .. " | " },
				{ current_cursor_info() },
			}
		end)

		local function reset_incline()
			-- Incline supports one setup() call, so we reload modules to run another panel.
			for _, module_name in ipairs({
				"incline",
				"incline.config",
				"incline.debounce",
				"incline.highlight",
				"incline.manager",
				"incline.tabpage",
				"incline.util",
				"incline.winline",
			}) do
				package.loaded[module_name] = false
			end
		end

		reset_incline()

		create_panel("right", function(props)
			if not props.focused then
				return
			end

			return {
				{ get_git_diff(props.buf) },
			}
		end)

		reset_incline()

		create_panel(
			"center",
			function(props)
				return render_bufferline(props)
			end,
			{
				"BufAdd",
				"BufDelete",
				"BufEnter",
				"BufModifiedSet",
				"WinEnter",
				"WinLeave",
				"RecordingEnter",
				"RecordingLeave",
				"ModeChanged",
				"CursorMoved",
				"TextChanged",
			}
		)
	end,
}
