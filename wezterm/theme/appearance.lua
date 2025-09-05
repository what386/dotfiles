local gpu_adapters = require("utils").gpu_adapter

local M = {}

function M.apply(config)
	-- Performance settings
	config.max_fps = 120
	config.front_end = "WebGpu"
	config.webgpu_power_preference = "HighPerformance"
	config.webgpu_preferred_adapter = gpu_adapters:pick_best()
	config.underline_thickness = "1.5pt"

	-- Cursor settings
	config.animation_fps = 120
	config.default_cursor_style = "BlinkingBlock"
	config.cursor_blink_ease_in = "Constant"
	config.cursor_blink_ease_out = "Constant"
	config.cursor_blink_rate = 650

	-- Scrollbar
	config.enable_scroll_bar = true

	-- Tab bar settings
	config.tab_bar_at_bottom = false
	config.enable_tab_bar = true
	config.hide_tab_bar_if_only_one_tab = false
	config.use_fancy_tab_bar = false
	config.tab_max_width = 50
	config.show_tab_index_in_tab_bar = false
	config.switch_to_last_active_tab_when_closing_tab = true

	-- Window settings
	config.window_padding = {
		left = 0,
		right = 0,
		top = 10,
		bottom = 7.5,
	}
	config.adjust_window_size_when_changing_font_size = false
	config.window_frame = {
		active_titlebar_bg = "#202020",
	}
	config.window_background_opacity = 0.40

	-- Pane settings
	config.inactive_pane_hsb = {
		saturation = 0.9,
		brightness = 0.65,
	}

	-- Visual bell
	config.visual_bell = {
		fade_in_function = "EaseIn",
		fade_in_duration_ms = 250,
		fade_out_function = "EaseOut",
		fade_out_duration_ms = 250,
		target = "CursorColor",
	}
end

return M
