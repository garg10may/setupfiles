local wezterm = require 'wezterm'
local config = wezterm.config_builder()
local target = wezterm.target_triple
local is_windows = target:find('windows') ~= nil
local is_macos = target:find('apple%-darwin') ~= nil

local function file_exists(path)
  local file = io.open(path, 'r')
  if file then
    file:close()
    return true
  end
  return false
end

-- 1. THE ENGINE
if is_windows then
  config.default_prog = { 'wsl.exe', '~', '-d', 'Ubuntu' }
elseif is_macos then
  if file_exists('/opt/homebrew/bin/fish') then
    config.default_prog = { '/opt/homebrew/bin/fish', '-l' }
  elseif file_exists('/usr/local/bin/fish') then
    config.default_prog = { '/usr/local/bin/fish', '-l' }
  else
    config.default_prog = { '/bin/zsh', '-l' }
  end
end

-- 2. THE ENVIRONMENT
config.set_environment_variables = {
  TERM = "xterm-256color",
}

-- 3. VISUALS & FONTS
config.color_scheme = 'AdventureTime'
config.font = wezterm.font_with_fallback({
  'FiraCode Nerd Font',
  'FiraCode NFM',
  'JetBrainsMono Nerd Font',
  'JetBrainsMonoNL Nerd Font',
  'JetBrainsMonoNL Nerd Font Mono',
  'Menlo',
})
config.font_size = is_macos and 13.0 or 11.5
config.line_height = 1.1
config.use_fancy_tab_bar = false
config.window_padding = { left = 5, right = 5, top = 5, bottom = 0 }
config.window_decorations = is_macos and 'RESIZE' or 'TITLE | RESIZE'

-- 4. STATUS BAR
wezterm.on('update-right-status', function(window, pane)
  local date = wezterm.strftime('%H:%M')
  local cwd = pane:get_current_working_dir()
  local display_cwd = ""
  if cwd then
    display_cwd = tostring(cwd.file_path)
    if is_windows then
      display_cwd = display_cwd:gsub("^/home/[^/]+", "~")
    elseif is_macos then
      display_cwd = display_cwd:gsub("^/Users/[^/]+", "~")
    end
  end

  window:set_right_status(wezterm.format({
    { Foreground = { AnsiColor = 'Aqua' } },
    { Text = " 📂 " .. display_cwd .. "  " },
    { Foreground = { AnsiColor = 'Yellow' } },
    { Text = " 🕒 " .. date .. " " },
  }))
end)

-- 5. THE KEYBOARD COCKPIT
config.keys = {
  -- TABS (Project Management)
  { key = 't', mods = 'CTRL',       action = wezterm.action.SpawnTab 'CurrentPaneDomain' },
  { key = 'w', mods = 'CTRL',       action = wezterm.action.CloseCurrentPane { confirm = true } },
  { key = 'Tab', mods = 'CTRL',     action = wezterm.action.ActivateTabRelative(1) },
  { key = 'Tab', mods = 'CTRL|SHIFT', action = wezterm.action.ActivateTabRelative(-1) },

  -- SPLITS (Horizontal for Terminal Drawer)
  { key = '|', mods = 'CTRL|SHIFT', action = wezterm.action.SplitHorizontal { domain = 'CurrentPaneDomain' } },
  { key = '_', mods = 'CTRL|SHIFT', action = wezterm.action.SplitVertical { domain = 'CurrentPaneDomain' } },

  -- NAVIGATION (Alt + hjkl)
  { key = 'h', mods = 'ALT', action = wezterm.action.ActivatePaneDirection 'Left' },
  { key = 'l', mods = 'ALT', action = wezterm.action.ActivatePaneDirection 'Right' },
  { key = 'k', mods = 'ALT', action = wezterm.action.ActivatePaneDirection 'Up' },
  { key = 'j', mods = 'ALT', action = wezterm.action.ActivatePaneDirection 'Down' },

  -- PRO TOOLS
  { key = 'z', mods = 'ALT', action = wezterm.action.TogglePaneZoomState },
  { key = 'f', mods = 'CTRL|SHIFT', action = wezterm.action.Search { CaseSensitiveString = "" } },
}

return config
