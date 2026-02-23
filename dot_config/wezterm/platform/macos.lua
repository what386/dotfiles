local M = {}

function M.apply(config)
	-- Default shell for macOS
	config.default_prog = { "fish" }

	-- Launch menu options for macOS
	config.launch_menu = {
		{ label = "Fish", args = { "/opt/homebrew/bin/fish", "-l" } },
		{ label = "Bash", args = { "bash", "-l" } },
		{ label = "Zsh", args = { "zsh", "-l" } },
		{ label = "Nushell", args = { "/opt/homebrew/bin/nu", "-l" } },
	}

	-- MacOS-specific settings
	config.send_composed_key_when_right_alt_is_pressed = true
end

return M
