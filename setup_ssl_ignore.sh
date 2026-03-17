#!/bin/bash

# Exit on error
set -e

# --- Firewall/Proxy Workaround ---
# This tells Git to ignore SSL errors for the duration of this script
export GIT_SSL_NO_VERIFY=true

echo "🚀 Starting God-Mode Fullstack Developer Environment Setup (Insecure Mode)..."

# Ensure local bin exists for the current user (used for manual binaries)
mkdir -p "$HOME/.local/bin"
export PATH="$HOME/.local/bin:$PATH"

# Detect Operating System
OS_TYPE=$(uname -s)
echo "🔍 Detecting Operating System..."

# ==========================================
# 1. Package Manager, Core Tools & Build Essentials
# ==========================================
if [ "$OS_TYPE" = "Darwin" ]; then
    echo "🍏 macOS detected."
    
    if ! command -v brew &> /dev/null; then
        echo "📦 Homebrew not found. Installing Homebrew..."
        # Added -k to curl
        /bin/bash -c "$(curl -fsSLk https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        if [[ $(uname -m) == "arm64" ]]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
        else
            eval "$(/usr/local/bin/brew shellenv)"
        fi
    fi

    echo "🛠️ Installing core tools via Homebrew..."
    brew update
    brew install gcc make cmake fish neovim git curl wget jq ripgrep fd zoxide fzf eza python zellij gh

elif [ "$OS_TYPE" = "Linux" ]; then
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        
        # --- DEBIAN / UBUNTU (GCP) ---
        if [[ "$ID" == "ubuntu" || "$ID" == "debian" ]]; then
            echo "🐧 Debian/Ubuntu detected."
            sudo apt update
            sudo apt install -y software-properties-common build-essential cmake pkg-config unzip tar fontconfig \
                fish git curl wget jq ripgrep fd-find fzf python3-pip python3-venv
            sudo apt install -y zoxide eza || echo "⚠️ zoxide/eza not found in standard repos, skipping..."

        # --- AMAZON LINUX / RHEL / FEDORA / CENTOS ---
        elif [[ "$ID" == "amzn" || "$ID" == "fedora" || "$ID" == "centos" || "$ID_LIKE" == *"rhel"* ]]; then
            echo "☁️ Enterprise Linux detected."
            PKG_MGR="yum"
            if command -v dnf &> /dev/null; then PKG_MGR="dnf"; fi
            
            sudo $PKG_MGR install -y epel-release util-linux-user || true 
            sudo $PKG_MGR install -y gcc gcc-c++ make cmake automake autoconf pkgconfig unzip tar fontconfig \
                fish git curl wget jq ripgrep fd-find fzf python3-pip
            sudo $PKG_MGR install -y zoxide eza || echo "⚠️ zoxide/eza not found in standard repos, skipping..."
        else
            echo "❌ Unsupported Linux distribution: $ID"
            exit 1
        fi

        # ==========================================
        # Linux Custom Binary Downloads (Bypass Repos)
        # ==========================================
        echo "📥 Downloading latest Neovim..."
        # Added -k to curl
        curl -LkO https://github.com/neovim/neovim/releases/latest/download/nvim-linux64.tar.gz
        sudo rm -rf /opt/nvim-linux64
        sudo tar -C /opt -xzf nvim-linux64.tar.gz
        rm nvim-linux64.tar.gz

        echo "📥 Downloading latest Zellij (Terminal Multiplexer)..."
        # Added -k to curl
        curl -LkO https://github.com/zellij-org/zellij/releases/latest/download/zellij-x86_64-unknown-linux-musl.tar.gz
        tar -xzf zellij-x86_64-unknown-linux-musl.tar.gz
        mv zellij "$HOME/.local/bin/"
        rm zellij-x86_64-unknown-linux-musl.tar.gz

        echo "📥 Downloading latest GitHub CLI (gh)..."
        # Added -k to curl
        GH_LATEST=$(curl -sk https://api.github.com/repos/cli/cli/releases/latest | grep '"tag_name":' | sed -E 's/.*"v([^"]+)".*/\1/')
        curl -LkO "https://github.com/cli/cli/releases/download/v${GH_LATEST}/gh_${GH_LATEST}_linux_amd64.tar.gz"
        tar -xzf "gh_${GH_LATEST}_linux_amd64.tar.gz"
        mv "gh_${GH_LATEST}_linux_amd64/bin/gh" "$HOME/.local/bin/"
        rm -rf "gh_${GH_LATEST}_linux_amd64"*
    else
        echo "❌ /etc/os-release not found."
        exit 1
    fi
else
    echo "❌ Unsupported Operating System: $OS_TYPE"
    exit 1
fi

# ==========================================
# 2. Nerd Fonts Installation
# ==========================================
echo "🔤 Installing FiraCode Nerd Font..."
if [ "$OS_TYPE" = "Darwin" ]; then
    brew install --cask font-fira-code-nerd-font || echo "⚠️ Could not install font via brew."
elif [ "$OS_TYPE" = "Linux" ]; then
    mkdir -p ~/.local/share/fonts
    # Added -k to curl
    curl -LkO https://github.com/ryanoasis/nerd-fonts/releases/latest/download/FiraCode.zip
    unzip -qo FiraCode.zip -d ~/.local/share/fonts/
    rm FiraCode.zip
    if command -v fc-cache &> /dev/null; then
        fc-cache -fv || true
    fi
fi

# ==========================================
# 3. Sensible Git Defaults
# ==========================================
echo "⚙️ Configuring sensible Git defaults..."
git config --global core.editor "nvim"
git config --global init.defaultBranch "main"
git config --global pull.rebase true
git config --global fetch.prune true
# Make the "ignore certificate" change permanent for this user's git
git config --global http.sslVerify false

# ==========================================
# 4. Python Setup (via UV)
# ==========================================
echo "🐍 Installing UV and Python Fullstack Tools..."
# Added -k to curl
curl -LsSfk https://astral.sh/uv/install.sh | sh
export PATH="$HOME/.cargo/bin:$PATH"

# uv might need a flag or env var too if it hits SSL issues:
export UV_HTTP_TIMEOUT=300
uv tool install ruff     
uv tool install httpie      
uv tool install pre-commit  

# ==========================================
# 5. Node.js Setup (via FNM)
# ==========================================
echo "🌐 Installing Node.js via fnm..."
# Added -k to curl
curl -fsSLk https://fnm.vercel.app/install | bash -s -- --install-dir "$HOME/.local/bin" --skip-shell
eval "$($HOME/.local/bin/fnm env)"

fnm install --lts
fnm default lts
fnm use lts
# npm also needs to ignore SSL
npm config set strict-ssl false
npm install -g pnpm yarn typescript tsx npm-check-updates

# ==========================================
# 6. Install Starship Prompt
# ==========================================
echo "✨ Installing Starship..."
# Added -k to curl
curl -sSk https://starship.rs/install.sh | sh -s -- -y --bin-dir "$HOME/.local/bin"

# ==========================================
# 7. Clean configs & Setup Command Cockpit
# ==========================================
# (Config logic remains unchanged)
mkdir -p ~/.config/fish
mkdir -p ~/.config/nvim

cat <<EOF > ~/.config/fish/config.fish
# --- Pathing ---
set -gx PATH "\$HOME/.local/bin" \$PATH
set -gx PATH "\$HOME/.cargo/bin" \$PATH 
set -gx PATH "/opt/homebrew/bin" \$PATH 
set -gx PATH "/opt/nvim-linux64/bin" \$PATH 

# --- Tool Inits ---
starship init fish | source

if command -v zoxide > /dev/null
    zoxide init fish | source
end

if command -v fnm > /dev/null
    fnm env --use-on-cd | source
end

# --- Navigation & Basics ---
if command -v eza > /dev/null
    alias ls="eza --icons -a --group-directories-first"
    alias l="eza -lbF --git --icons"
    alias ll="eza -lbGF --git --icons"
else
    alias ls="ls -a"
    alias l="ls -la"
    alias ll="ls -la"
end

alias v="nvim"
alias vi="nvim"
alias cd="z"

# --- ABBREVIATIONS ---
abbr gs  "git status"
abbr ga  "git add"
abbr gc  "git commit -m"
abbr gp  "git push"
abbr gl  "git log --oneline --graph --decorate"
abbr pr  "gh pr create"
abbr z   "zellij"
abbr za  "zellij attach"
abbr ua  "uv add"
abbr us  "uv sync"
abbr ur  "uv run"
abbr ut  "uv tree"
abbr venv "source .venv/bin/activate.fish"
abbr nd  "npm run dev"
abbr nb  "npm run build"
abbr ns  "npm start"
abbr pd  "pnpm dev"
abbr yd  "yarn dev"
abbr ..   "cd .."
abbr ...  "cd ../.."
abbr h    "history"
abbr cl   "clear"
abbr ports "lsof -i -P -n | grep LISTEN"
abbr nv    "nvim"
abbr nvc   "cd ~/.config/nvim && nvim"
EOF

# ==========================================
# 8. Setup LazyVim
# ==========================================
echo "💤 Installing LazyVim Starter..."
rm -rf ~/.config/nvim
# Since we exported GIT_SSL_NO_VERIFY=true, this should work
git clone https://github.com/LazyVim/starter ~/.config/nvim
rm -rf ~/.config/nvim/.git

# ==========================================
# 9. Finalize
# ==========================================
echo "✅ Setup Complete!"
echo "👉 Run: 'chsh -s \$(which fish)' to make Fish your default shell."
echo "👉 Restart your terminal or reconnect via SSH."
