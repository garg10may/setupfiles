local wezterm = require 'wezterm'
local config = {}

if wezterm.config_builder then
  config = wezterm.config_builder()
end

-- 1. THE ENGINE
config.default_prog = { "C:/msys64/usr/bin/fish.exe", "--login" }

-- 2. THE ENVIRONMENT
config.set_environment_variables = {
  MSYS2_PATH_TYPE = "inherit", 
  XDG_CONFIG_HOME = "C:/Users/garg1/.config",
  HOME = "C:/Users/garg1",
}

-- 3. VISUALS & FONTS
config.color_scheme = 'AdventureTime'
config.font = wezterm.font('JetBrainsMono Nerd Font', { weight = 'Bold', italic = false })
config.font_size = 10
config.line_height = 1.1

-- 4. STATUS BAR (Right Side)
wezterm.on('update-right-status', function(window, pane)
  local date = wezterm.strftime('%Y-%m-%d %H:%M:%S')
  local cwd = pane:get_current_working_dir()
  local home = "file:///C:/Users/garg1"
  
  local display_cwd = ""
  if cwd then
    display_cwd = tostring(cwd):gsub(home, "~")
  end

  window:set_right_status(wezterm.format({
    { Foreground = { AnsiColor = 'Aqua' } },
    { Text = " 📂 " .. display_cwd .. "  " },
    { Foreground = { AnsiColor = 'Yellow' } },
    { Text = " 🕒 " .. date .. " " },
  }))
end)

config.keys = {
  -- TABS (Chrome/VS Code Standard)
  { key = 't', mods = 'CTRL',       action = wezterm.action.SpawnTab 'CurrentPaneDomain' },
  { key = 'w', mods = 'CTRL',       action = wezterm.action.CloseCurrentPane { confirm = true } },
  { key = 'Tab', mods = 'CTRL',     action = wezterm.action.ActivateTabRelative(1) },
  { key = 'Tab', mods = 'CTRL|SHIFT', action = wezterm.action.ActivateTabRelative(-1) },

  -- SPLITS (Visual Standard: | for Vertical line, _ for Horizontal line)
  { key = '|', mods = 'CTRL|SHIFT', action = wezterm.action.SplitHorizontal { domain = 'CurrentPaneDomain' } },
  { key = '_', mods = 'CTRL|SHIFT', action = wezterm.action.SplitVertical { domain = 'CurrentPaneDomain' } },

  -- NAVIGATION (Vim HJKL Standard)
  { key = 'h', mods = 'ALT', action = wezterm.action.ActivatePaneDirection 'Left' },
  { key = 'l', mods = 'ALT', action = wezterm.action.ActivatePaneDirection 'Right' },
  { key = 'k', mods = 'ALT', action = wezterm.action.ActivatePaneDirection 'Up' },
  { key = 'j', mods = 'ALT', action = wezterm.action.ActivatePaneDirection 'Down' },

  -- PRO TOOLS
  { key = 'z', mods = 'ALT', action = wezterm.action.TogglePaneZoomState },
  { key = ' ', mods = 'CTRL|SHIFT', action = wezterm.action.QuickSelect },
  { key = 'f', mods = 'CTRL|SHIFT', action = wezterm.action.Search { CaseSensitiveString = "" } },
}

return config
