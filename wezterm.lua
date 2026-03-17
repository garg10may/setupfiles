local wezterm = require 'wezterm'
local config = wezterm.config_builder()

-- 1. THE ENGINE (Now pointing to Ubuntu)
config.default_prog = { 'wsl.exe', '~', '-d', 'Ubuntu' }

-- 2. THE ENVIRONMENT (Cleaned for WSL)
config.set_environment_variables = {
  -- We don't need MSYS2 paths anymore!
  TERM = "xterm-256color",
}

-- 3. VISUALS & FONTS
config.color_scheme = 'AdventureTime'
config.font = wezterm.font('JetBrainsMono Nerd Font', { weight = 'Bold' })
config.font_size = 11.5 -- Bumped slightly for readability
config.line_height = 1.1
config.use_fancy_tab_bar = false
config.window_padding = { left = 5, right = 5, top = 5, bottom = 0 }

-- 4. STATUS BAR (Simplified for Linux)
wezterm.on('update-right-status', function(window, pane)
  local date = wezterm.strftime('%H:%M')
  local cwd = pane:get_current_working_dir()
  local display_cwd = ""
  if cwd then
    display_cwd = tostring(cwd.file_path):gsub("^/home/[^/]+", "~")
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
