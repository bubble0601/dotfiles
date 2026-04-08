local wezterm = require("wezterm")
local config = wezterm.config_builder()

-- フォント
config.font_size = 14.0

-- カラースキーム
config.color_scheme = "iceberg-dark"

-- ウィンドウ
config.window_background_opacity = 0.95
config.macos_window_background_blur = 20
config.window_padding = {
  left = 8,
  right = 8,
  top = 8,
  bottom = 8,
}

-- タブバー
config.tab_max_width = 20
config.show_new_tab_button_in_tab_bar = false
config.show_close_tab_button_in_tabs = false

-- スクロールバック
config.scrollback_lines = 10000

-- ステータス更新間隔
config.status_update_interval = 1000

-- キーバインド
-- Ctrl+a は Emacs キーバインド (行頭移動) と被るため Ctrl+q を使用
config.leader = { key = "q", mods = "CTRL", timeout_milliseconds = 1500 }
config.keys = {
  -- ペイン分割
  { key = "s", mods = "LEADER", action = wezterm.action.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
  { key = "h", mods = "LEADER", action = wezterm.action.SplitVertical({ domain = "CurrentPaneDomain" }) },
  -- ペインを閉じる
  { key = "x", mods = "LEADER", action = wezterm.action.CloseCurrentPane({ confirm = false }) },
  -- ペイン移動
  { key = "LeftArrow",  mods = "SUPER", action = wezterm.action.ActivatePaneDirection("Left") },
  { key = "DownArrow",  mods = "SUPER", action = wezterm.action.ActivatePaneDirection("Down") },
  { key = "UpArrow",    mods = "SUPER", action = wezterm.action.ActivatePaneDirection("Up") },
  { key = "RightArrow", mods = "SUPER", action = wezterm.action.ActivatePaneDirection("Right") },
  -- ペインモード起動 (サイズ変更など連続操作)
  { key = "q", mods = "LEADER", action = wezterm.action.ActivateKeyTable({ name = "pane_mode", one_shot = false }) },
  -- タブ操作
  { key = "t",          mods = "SUPER", action = wezterm.action.SpawnCommandInNewTab({ cwd = wezterm.home_dir }) },
  { key = "LeftArrow",  mods = "CTRL|SHIFT",  action = wezterm.action.ActivateTabRelative(-1) },
  { key = "RightArrow", mods = "CTRL|SHIFT",  action = wezterm.action.ActivateTabRelative(1) },
  { key = "LeftArrow",  mods = "SUPER|SHIFT", action = wezterm.action.MoveTabRelative(-1) },
  { key = "RightArrow", mods = "SUPER|SHIFT", action = wezterm.action.MoveTabRelative(1) },
  -- コマンドパレット
  { key = "p", mods = "SUPER", action = wezterm.action.ActivateCommandPalette },
  -- コピーモード
  { key = "[", mods = "LEADER", action = wezterm.action.ActivateCopyMode },
  -- Emacs ショートカット一覧オーバーレイ
  { key = "?", mods = "LEADER", action = wezterm.action_callback(function(window, pane)
    window:perform_action(
      wezterm.action.SplitPane({
        direction = "Right",
        size = { Percent = 45 },
        command = {
          args = {
            "bash", "-c",
            os.getenv("HOME") .. "/.config/wezterm/keybindings.sh | less -R"
          }
        }
      }),
      pane
    )
  end) },
}

config.key_tables = {
  pane_mode = {
    -- 分割
    { key = "s",          action = wezterm.action.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
    { key = "v",          action = wezterm.action.SplitVertical({ domain = "CurrentPaneDomain" }) },
    -- 閉じる
    { key = "x",          action = wezterm.action.CloseCurrentPane({ confirm = false }) },
    -- 移動
    { key = "LeftArrow",  action = wezterm.action.ActivatePaneDirection("Left") },
    { key = "DownArrow",  action = wezterm.action.ActivatePaneDirection("Down") },
    { key = "UpArrow",    action = wezterm.action.ActivatePaneDirection("Up") },
    { key = "RightArrow", action = wezterm.action.ActivatePaneDirection("Right") },
    -- サイズ変更
    { key = "h",          action = wezterm.action.AdjustPaneSize({ "Left", 5 }) },
    { key = "j",          action = wezterm.action.AdjustPaneSize({ "Down", 5 }) },
    { key = "k",          action = wezterm.action.AdjustPaneSize({ "Up", 5 }) },
    { key = "l",          action = wezterm.action.AdjustPaneSize({ "Right", 5 }) },
    -- 終了
    { key = "Escape",     action = wezterm.action.PopKeyTable },
    { key = "q",          action = wezterm.action.PopKeyTable },
  },
}

-- ステータスバー: leader キー待ち状態を左側に、フルスクリーン時は右側に日時とバッテリーを表示
wezterm.on("update-status", function(window, pane)
  -- 左: leader 待ち状態
  local left = ""
  if window:leader_is_active() then
    left = wezterm.format({
      { Foreground = { Color = "#e2a478" } },
      { Text = " LEADER " },
    })
  end
  local key_table = window:active_key_table()
  if key_table then
    left = left .. wezterm.format({
      { Foreground = { Color = "#a093c7" } },
      { Text = " " .. key_table:upper() .. " " },
    })
  end
  window:set_left_status(left)

  -- 右: フルスクリーン時のみ表示
  if not window:get_dimensions().is_full_screen then
    window:set_right_status("")
    return
  end

  -- 日時
  local date = wezterm.strftime("󰃰 %Y-%m-%d  󰥔 %H:%M")

  -- バッテリー
  local battery_text = ""
  local ok, batteries = pcall(wezterm.battery_info)
  if ok and batteries and #batteries > 0 then
    local b = batteries[1]
    local pct = math.floor(b.state_of_charge * 100)
    local icon
    if b.state == "Charging" then
      icon = "󰂄"
    elseif pct >= 80 then
      icon = "󰁹"
    elseif pct >= 60 then
      icon = "󰂀"
    elseif pct >= 40 then
      icon = "󰁾"
    elseif pct >= 20 then
      icon = "󰁼"
    else
      icon = "󰁺"
    end
    battery_text = string.format("  %s %d%%  ", icon, pct)
  end

  window:set_right_status(wezterm.format({
    { Foreground = { Color = "#84a0c6" } },
    { Text = battery_text .. date .. "  " },
  }))
end)

-- タブタイトル: アイコン + カレントディレクトリ名 + 実行中プロセス名
local process_icons = {
  ["zsh"]     = { icon = wezterm.nerdfonts.dev_terminal,      color = "#89b8c2" },
  ["bash"]    = { icon = wezterm.nerdfonts.dev_terminal,      color = "#89b8c2" },
  ["vim"]     = { icon = wezterm.nerdfonts.custom_vim,        color = "#b4be82" },
  ["nvim"]    = { icon = wezterm.nerdfonts.custom_neovim,     color = "#b4be82" },
  ["git"]     = { icon = wezterm.nerdfonts.dev_git,           color = "#e2a478" },
  ["python"]  = { icon = wezterm.nerdfonts.dev_python,        color = "#84a0c6" },
  ["python3"] = { icon = wezterm.nerdfonts.dev_python,        color = "#84a0c6" },
  ["uv"]      = { icon = wezterm.nerdfonts.dev_python,        color = "#84a0c6" },
  ["node"]    = { icon = wezterm.nerdfonts.dev_nodejs_small,  color = "#b4be82" },
  ["docker"]  = { icon = wezterm.nerdfonts.dev_docker,        color = "#84a0c6" },
  ["ssh"]     = { icon = wezterm.nerdfonts.md_server_network, color = "#a093c7" },
  ["yarn"]    = { icon = wezterm.nerdfonts.dev_yarn,           color = "#84a0c6" },
  ["irb"]     = { icon = wezterm.nerdfonts.dev_ruby,           color = "#e27878" },
  ["psql"]    = { icon = wezterm.nerdfonts.dev_postgresql,     color = "#84a0c6" },
  ["aws"]     = { icon = wezterm.nerdfonts.dev_aws,            color = "#e2a478" },
  ["codex"]   = { icon = wezterm.nerdfonts.md_hexagon_multiple_outline, color = "#7b9fd4" },
  ["claude"]  = { icon = wezterm.nerdfonts.oct_north_star,    color = "#e27878" },
}

wezterm.on("format-tab-title", function(tab, tabs, panes, config, hover, max_width)
  local pane = tab.active_pane
  local process_path = pane.foreground_process_name
  local process = process_path:match("([^/]+)$") or ""
  -- フルパスに "claude" が含まれる場合は claude として扱う
  if process_path:find("claude", 1, true) then
    process = "claude"
  end
  local cwd = pane.current_working_dir
  local dir = ""
  if cwd then
    local path = cwd.file_path
    dir = path:match("([^/]+)/?$") or path
    if path == wezterm.home_dir then
      dir = "~"
    end
  end

  local meta = process_icons[process] or { icon = wezterm.nerdfonts.dev_terminal, color = "#d2d4de" }

  local title
  if process == "zsh" or process == "bash" or process == "" then
    title = dir
  else
    title = process .. " - " .. dir
  end

  local fg = tab.is_active and "#d2d4de" or "#a0a5be"

  return wezterm.format({
    { Foreground = { Color = meta.color } },
    { Text = string.format(" %s", meta.icon) },
    { Foreground = { Color = fg } },
    { Text = string.format(" %s ", title) },
  })
end)

-- zsh は確認なしで閉じる
config.skip_close_confirmation_for_processes_named = { "zsh" }

return config
