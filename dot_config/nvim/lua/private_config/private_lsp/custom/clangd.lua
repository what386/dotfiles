local esp_idf_export_marker = "source /opt/esp-idf/export.sh"

local clangd_base_cmd = {
	"clangd-20",
	"--background-index",
	"--clang-tidy",
	"--header-insertion=iwyu",
	"--completion-style=detailed",
	"--function-arg-placeholders=true",
	"--fallback-style=llvm",
	"--experimental-modules-support",
}

local function is_esp_idf_project(root_dir)
	if not root_dir or root_dir == "" then
		return false
	end

	local envrc = vim.fs.joinpath(root_dir, ".envrc")
	if vim.fn.filereadable(envrc) == 0 then
		return false
	end

	local lines = vim.fn.readfile(envrc)
	return vim.iter(lines):any(function(line)
		return line:find(esp_idf_export_marker, 1, true) ~= nil
	end)
end

local function clangd_cmd(root_dir)
	if is_esp_idf_project(root_dir) then
		return vim.list_extend({ "direnv", "exec", root_dir, "clangd" }, vim.list_slice(clangd_base_cmd, 2))
	end

	return vim.deepcopy(clangd_base_cmd)
end

return {
	keys = {
		{ "<leader>ch", "<cmd>LspClangdSwitchSourceHeader<cr>", desc = "Switch Source/Header (C/C++)" },
	},
	root_markers = {
		"compile_commands.json",
		"compile_flags.txt",
		"Makefile",
		"configure.ac", -- AutoTools
		"configure.in",
		"config.h.in",
		"meson.build",
		"meson_options.txt",
		"build.ninja",
		".git",
	},
	capabilities = { offsetEncoding = { "utf-16" } },
	cmd = vim.deepcopy(clangd_base_cmd),
	init_options = {
		usePlaceholders = true,
		completeUnimported = true,
		clangdFileStatus = true,
	},
	on_new_config = function(new_config, new_root_dir)
		new_config.cmd = clangd_cmd(new_root_dir)
	end,
	mason = false,
}
