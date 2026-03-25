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

-- CMD押下でマウスレポーティングをバイパス（デフォルトのSHIFTから変更）
-- tmuxのマウスモード有効時でもCMD+クリックでテキスト選択やURL開くが可能
config.bypass_mouse_reporting_modifiers = 'CMD'

config.keys = {
  -- Cmd+Shift+C でtmuxコピーモードに入る (prefix=Ctrl-q + [)
  {
    key = 'C',
    mods = 'CMD|SHIFT',
    action = act.Multiple {
      act.SendKey { key = 'q', mods = 'CTRL' },
      act.SendKey { key = '[' },
    },
  },
  -- Cmd+C で選択テキストをコピー
  {
    key = 'c',
    mods = 'CMD',
    action = wezterm.action_callback(function(window, pane)
      local has_selection = window:get_selection_text_for_pane(pane) ~= ''
      if has_selection then
        window:perform_action(act.CopyTo 'ClipboardAndPrimarySelection', pane)
      else
        window:perform_action(act.SendKey { key = 'c', mods = 'CTRL' }, pane)
      end
    end),
  },
}

-- CMD+クリックでURLを開く
config.mouse_bindings = {
  -- CMD+クリックのDownイベントを無効化（アプリに渡さない）
  {
    event = { Down = { streak = 1, button = 'Left' } },
    mods = 'CMD',
    action = act.Nop,
  },
  -- CMD+クリックのUpイベントでURLを開く
  {
    event = { Up = { streak = 1, button = 'Left' } },
    mods = 'CMD',
    action = act.OpenLinkAtMouseCursor,
  },
}

return config
