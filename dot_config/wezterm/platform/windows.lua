local M = {}

function M.apply(config)
	-- Default shell for Windows
	config.default_prog = { "powershell" }

	-- Launch menu options for Windows
	config.launch_menu = {
		{ label = "PowerShell", args = { "powershell" } },
		{ label = "Command Prompt", args = { "cmd" } },
		{ label = "Nushell", args = { "nu" } },
		{ label = "Msys2", args = { "ucrt64.cmd" } },
	}

	-- Windows(11)-specific settings

	-- blurry text fix
	config.freetype_load_target = "Normal"
	config.freetype_render_target = "Normal"

	-- prevent alt key conflicts
	config.send_composed_key_when_left_alt_is_pressed = false
	config.send_composed_key_when_right_alt_is_pressed = true
	config.use_dead_keys = false

	-- ensure WSL domains are properly configured
	config.default_domain = "local"

	-- prevent odd path seperators
	config.set_environment_variables = {
		LANG = "en_US.UTF-8",
	}
end

return M
