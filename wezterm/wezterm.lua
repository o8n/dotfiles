local wezterm = require 'wezterm'
local config = wezterm.config_builder()

config.font = wezterm.font_with_fallback {
  { family = 'JetBrainsMono Nerd Font', weight = 'Regular' },
  'BIZ UDGothic',
}
config.font_size = 12.0
config.font_rules = {
  {
    intensity = 'Bold',
    font = wezterm.font_with_fallback {
      { family = 'JetBrainsMono Nerd Font', weight = 'Regular' },
      'BIZ UDGothic',
    },
  },
}

return config
