local wezterm = require("wezterm")
local platform = require("utils.platform")

local font_size = 13

return {
   font = wezterm.font({
      family = "JetBrainsMono Nerd Font",
      stretch = "Expanded",
      weight = "Regular",
   }),

   font_size = font_size,

   --ref: https://wezfurlong.org/wezterm/config/lua/config/freetype_pcf_long_family_names.html#why-doesnt-wezterm-use-the-distro-freetype-or-match-its-configuration
   freetype_load_target = "Normal", ---@type 'Normal'|'Light'|'Mono'|'HorizontalLcd'
   freetype_render_target = "Normal", ---@type 'Normal'|'Light'|'Mono'|'HorizontalLcd'
}
