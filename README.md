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

## Assumptions

- These scripts target fresh personal machines.
- Windows development happens inside WSL Ubuntu, not in native Windows shells.
- If `~/.config/nvim` already exists, the LazyVim bootstrap is skipped.
- WezTerm and LazyVim defaults live under `config/` in this repo.
- The legacy `setup_ssl_ignore.sh` script is not part of the new flow.
