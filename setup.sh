#!/bin/bash

# Exit on error
set -e

echo "🚀 Starting Full Developer Environment Setup..."

# 1. Update System and Add Repositories
echo "📦 Adding PPA repositories for Neovim and Fish..."
sudo apt update && sudo apt install -y software-properties-common
sudo add-apt-repository ppa:neovim-ppa/unstable -y
sudo add-apt-repository ppa:fish-shell/release-3 -y
sudo apt update

# 2. Install Core CLI Tools
echo "🛠️ Installing core tools (Fish, Neovim, Zoxide, Starship, etc)..."
sudo apt install -y \
    fish neovim git curl ripgrep fd-find zoxide fzf eza build-essential \
    python3-pip python3-venv nodejs npm

# 3. Install UV (Modern Python Manager)
echo "🐍 Installing UV..."
curl -LsSf https://astral.sh/uv/install.sh | sh

# 4. Install Starship Prompt
echo "✨ Installing Starship..."
curl -sS https://starship.rs/install.sh | sh -s -- -y

# 5. Clean configs
echo "🐚 Create clean configs"
mkdir -p ~/.config/fish
mkdir -p ~/.config/nvim

# 5. THE "COMMAND COCKPIT" (Fish Config with Pro Abbreviations)
cat <<EOF > ~/.config/fish/config.fish
# --- Pathing ---
set -gx PATH "\$HOME/.local/bin" \$PATH

# --- Tool Inits ---
starship init fish | source
zoxide init fish | source

# --- Navigation & Basics ---
alias ls="eza --icons -a --group-directories-first"
alias l="eza -lbF --git --icons"
alias ll="eza -lbGF --git --icons"
alias v="nvim"
alias vi="nvim"
alias cd="z"

# --- POWER ABBREVIATIONS ---
# Git Essentials
abbr gs  "git status"
abbr ga  "git add"
abbr gc  "git commit -m"
abbr gp  "git push"
abbr gl  "git log --oneline --graph --decorate"
abbr gco "git checkout"

# Python / UV Essentials
abbr ua  "uv add"
abbr us  "uv sync"
abbr ur  "uv run"
abbr ut  "uv tree"
abbr venv "source .venv/bin/activate.fish"

# System
abbr ..   "cd .."
abbr ...  "cd ../.."
abbr .... "cd ../../.."
abbr h    "history"
abbr cl   "clear"

# Neovim
abbr nv   "nvim"
abbr nvc  "cd ~/.config/nvim && nvim"
EOF


# 6. Setup LazyVim
echo "💤 Installing LazyVim Starter..."
rm -rf ~/.config/nvim
git clone https://github.com/LazyVim/starter ~/.config/nvim

# 7. Finalize
echo "✅ Setup Complete!"
echo "👉 Run: 'chsh -s \$(which fish)' to make Fish your default shell."
echo "👉 Then restart your terminal."
