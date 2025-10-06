local M = {}

function M.apply(config)
	-- Default shell for Linux
	config.default_prog = { "fish" }

	-- Launch menu options for Linux
	config.launch_menu = {
		{ label = "Fish", args = { "fish", "-l" } },
		{ label = "Bash", args = { "bash", "-l" } },
		{ label = "Zsh", args = { "zsh", "-l" } },
	}

	-- Linux-specific settings

	config.window_decorations = "RESIZE" -- Let WM handle decorations

	-- May need to adjust based on your distro font rendering
	config.freetype_load_target = "Normal"
	config.freetype_render_target = "Normal"

	-- force wezterm to use xclip
	config.selection_word_boundary = " \t\n{}[]()\"'`.,;:"

	-- fixes programs not detecting terminal / features
	config.set_environment_variables = {
		TERM = "wezterm",
		COLORTERM = "truecolor",
	}
end

return M
