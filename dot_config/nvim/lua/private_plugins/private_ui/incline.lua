local function status(props)
	if not props.focused then
		return
	end
	local mode = vim.api.nvim_get_mode().mode
	local label = ({
		n = "Normal",
		i = "Insert",
		v = "Visual",
		V = "Visual Line",
		[string.char(22)] = "Visual Block",
		R = "Replace",
		c = "Command",
		t = "Terminal",
	})[mode] or mode
	local recording = vim.fn.reg_recording()
	local cursor = vim.api.nvim_win_get_cursor(props.win)
	local position = string.format("%d⋮%d", cursor[1], cursor[2] + 1)
	if mode:match("^[vV\22]") then
		local start = vim.fn.getpos("v")
		position = string.format("%d⋮%d", math.abs(start[2] - cursor[1]) + 1, math.abs(start[3] - cursor[2] - 1) + 1)
	end
	return (recording ~= "" and ("@" .. recording .. " ") or "") .. label .. " | " .. position
end

local function info(props)
	if not props.focused then
		return
	end
	local parts = {}
	local git = vim.b[props.buf].gitsigns_status_dict or {}
	for _, item in ipairs({
		{ "added", "+", "DiffAdd" },
		{ "changed", "~", "DiffChange" },
		{ "removed", "-", "DiffDelete" },
	}) do
		if (git[item[1]] or 0) > 0 then
			parts[#parts + 1] = { item[2] .. git[item[1]] .. " ", group = item[3] }
		end
	end
	parts[#parts + 1] = vim.bo[props.buf].filetype
	return parts
end

local function buffers(props)
	if not props.focused then
		return
	end
	local listed = vim.fn.getbufinfo({ buflisted = 1 })
	local current = 1
	for index, buf in ipairs(listed) do
		if buf.bufnr == props.buf then
			current = index
		end
	end
	-- Keep the active buffer visible, including beyond the first nine buffers.
	local first = math.max(1, current - 4)
	local parts = {}
	if first > 1 then
		parts[#parts + 1] = "… "
	end
	for index = first, math.min(#listed, first + 8) do
		local buf = listed[index]
		local name = buf.name == "" and "[No Name]" or vim.fn.fnamemodify(buf.name, ":t")
		local active = buf.bufnr == props.buf
		parts[#parts + 1] = {
			(active and "[" or "") .. name .. (buf.changed == 1 and " ●" or "") .. (active and "]" or "") .. " ",
			gui = active and "bold" or "none",
		}
	end
	if first + 8 < #listed then
		parts[#parts + 1] = "…"
	end
	return parts
end

return {
	name = "incline.nvim",
	dir = vim.fn.stdpath("config") .. "/lua/deps/incline.nvim",
	event = "VeryLazy",
	opts = {
		hide = { cursorline = false },
		window = {
			placement = { vertical = "bottom" },
			margin = { horizontal = 1, vertical = 1 },
			zindex = 10000,
		},
		panels = {
			{ render = status, window = { placement = { horizontal = "left" }, width = "fit" } },
			{ render = buffers, window = { placement = { horizontal = "center" }, width = "fit" } },
			{ render = info, window = { placement = { horizontal = "right" }, width = "fit" } },
		},
	},
}
