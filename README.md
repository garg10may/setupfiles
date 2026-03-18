# Setupfiles

Fresh-machine bootstrap for two personal environments:

- macOS host with a local Unix developer setup
- Windows host with native GUI apps plus a WSL Ubuntu developer setup

## Entry points

On macOS:

```bash
./bootstrap-mac.sh
```

On Windows PowerShell:

```powershell
.\bootstrap-windows.ps1
```

Compatibility wrapper:

```bash
./setup.sh
```

`setup.sh` now dispatches to `bootstrap-mac.sh` on macOS, or runs the shared Unix bootstrap when you invoke it inside WSL Ubuntu.

## What gets installed

macOS host:

- Homebrew
- WezTerm
- Visual Studio Code
- yabai, skhd, Hammerspoon, stackline
- Nerd Fonts
- Shared Unix developer tools

Windows host:

- WezTerm
- Visual Studio Code
- WSL Ubuntu
- Shared Unix developer tools inside WSL Ubuntu

Shared Unix developer setup:

- Fish
- Neovim
- LazyVim starter plus repo defaults
- Git, gh
- uv, ruff, httpie, pre-commit
- fnm, Node.js LTS, pnpm, yarn, typescript, tsx
- zellij, starship, zoxide, ripgrep, fd, fzf, eza
- bat, direnv, git-delta, just, btop, shellcheck

## Assumptions

- These scripts target fresh personal machines.
- Windows development happens inside WSL Ubuntu, not in native Windows shells.
- If `~/.config/nvim` already exists, the LazyVim bootstrap is skipped.
- WezTerm and LazyVim defaults live under `config/` in this repo.
- The legacy `setup_ssl_ignore.sh` script is not part of the new flow.

## Repo Defaults

Fish:

- starship, zoxide, direnv, fnm, and fzf bindings are initialized when available
- extra abbreviations are included for Git, Python, Node, Docker, and kubectl

LazyVim:

- editor options and keymaps live under `config/nvim/lua/config`
- plugin defaults live under `config/nvim/lua/plugins`
- includes LazyGit, ToggleTerm, formatting defaults, LSP defaults, and a fixed colorscheme

macOS window manager:

- `yabai` config lives at `config/yabai/yabairc`
- `skhd` config lives at `config/skhd/skhdrc`
- Hammerspoon and stackline defaults live under `config/hammerspoon`
