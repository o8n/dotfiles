local wezterm = require 'wezterm'
local config = wezterm.config_builder()

config.font = wezterm.font_with_fallback {
  { family = 'JetBrains Mono', weight = 'Regular' },
  { family = 'Hiragino Sans', assume_emoji_presentation = false, harfbuzz_features = { 'locl' } },
}
config.font_size = 12.0
config.font_rules = {
  {
    intensity = 'Bold',
    font = wezterm.font_with_fallback {
      { family = 'JetBrains Mono', weight = 'Bold' },
      { family = 'Hiragino Sans', weight = 'Bold', assume_emoji_presentation = false, harfbuzz_features = { 'locl' } },
    },
  },
}

-- 右ステータスバーに日付・時刻を表示
wezterm.on('update-status', function(window, pane)
  local date = wezterm.strftime '%Y-%m-%d %H:%M:%S'
  window:set_right_status(wezterm.format {
    { Text = date .. '  ' },
  })
end)

config.status_update_interval = 1000

local act = wezterm.action

config.keys = {
  -- Cmd+Shift+C でtmuxコピーモードに入る (prefix=Ctrl-b + [)
  {
    key = 'C',
    mods = 'CMD|SHIFT',
    action = act.Multiple {
      act.SendKey { key = 'b', mods = 'CTRL' },
      act.SendKey { key = '[' },
    },
  },
}

return config
