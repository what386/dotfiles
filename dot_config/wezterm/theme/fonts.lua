local wezterm = require("wezterm")
local M = {}

function M.apply(config)
    config.font_size = 12.0
    config.font = wezterm.font({
        family = "JetBrainsMono Nerd Font",
        stretch = "Expanded",
        weight = "Regular",
    })

    --ref: https://wezfurlong.org/wezterm/config/lua/config/freetype_pcf_long_family_names.html#why-doesnt-wezterm-use-the-distro-freetype-or-match-its-configuration
    --config.freetype_load_target = "Normal", ---@type 'Normal'|'Light'|'Mono'|'HorizontalLcd'
    --config.freetype_render_target = "Normal", ---@type 'Normal'|'Light'|'Mono'|'HorizontalLcd'
end

return M
