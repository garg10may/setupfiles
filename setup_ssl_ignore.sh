#!/bin/bash

# --- Error Handling ---
# This function runs automatically if any command fails
failure_notice() {
    echo -e "\n\033[0;31m❌ ERROR: Command failed at line $1\033[0m"
    echo -e "\033[0;31m🔍 Check the output above for specific firewall or SSL messages.\033[0m"
}
trap 'failure_notice $LINENO' ERR
set -e

# --- Firewall/Proxy Workaround ---
export GIT_SSL_NO_VERIFY=true

echo "🚀 Starting God-Mode Fullstack Developer Environment Setup..."

# Ensure local bin exists
mkdir -p "$HOME/.local/bin"
export PATH="$HOME/.local/bin:$PATH"

OS_TYPE=$(uname -s)
echo "🔍 Detecting Operating System..."

# ==========================================
# 1. Package Manager & Core Tools
# ==========================================
if [ "$OS_TYPE" = "Darwin" ]; then
    echo "🍏 macOS detected."
    
    if ! command -v brew &> /dev/null; then
        echo "📦 Installing Homebrew (Insecure Mode)..."
        # -fsSLk: f (fail silently), s (silent), S (show error), L (follow redirects), k (insecure)
        /bin/bash -c "$(curl -fsSLk https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        [[ $(uname -m) == "arm64" ]] && eval "$(/opt/homebrew/bin/brew shellenv)" || eval "$(/usr/local/bin/brew shellenv)"
    fi

    echo "🛠️ Installing tools via Homebrew..."
    brew update
    brew install gcc make cmake fish neovim git curl wget jq ripgrep fd zoxide fzf eza python zellij gh

elif [ "$OS_TYPE" = "Linux" ]; then
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        
        if [[ "$ID" == "ubuntu" || "$ID" == "debian" ]]; then
            sudo apt update && sudo apt install -y software-properties-common build-essential cmake pkg-config unzip tar fontconfig fish git curl wget jq ripgrep fd-find fzf python3-pip python3-venv
        elif [[ "$ID" == "amzn" || "$ID" == "fedora" || "$ID" == "centos" || "$ID_LIKE" == *"rhel"* ]]; then
            PKG_MGR=$(command -v dnf &> /dev/null && echo "dnf" || echo "yum")
            sudo $PKG_MGR install -y epel-release util-linux-user || true 
            sudo $PKG_MGR install -y gcc gcc-c++ make cmake automake autoconf pkgconfig unzip tar fontconfig fish git curl wget jq ripgrep fd-find fzf python3-pip
        fi

        # --- Manual Binary Downloads ---
        echo "📥 Downloading Neovim..."
        curl -SLkO https://github.com/neovim/neovim/releases/latest/download/nvim-linux64.tar.gz
        sudo rm -rf /opt/nvim-linux64 && sudo tar -C /opt -xzf nvim-linux64.tar.gz && rm nvim-linux64.tar.gz

        echo "📥 Downloading Zellij..."
        curl -SLkO https://github.com/zellij-org/zellij/releases/latest/download/zellij-x86_64-unknown-linux-musl.tar.gz
        tar -xzf zellij-x86_64-unknown-linux-musl.tar.gz && mv zellij "$HOME/.local/bin/" && rm zellij-*.tar.gz

        echo "📥 Downloading GitHub CLI..."
        GH_LATEST=$(curl -sk https://api.github.com/repos/cli/cli/releases/latest | grep '"tag_name":' | sed -E 's/.*"v([^"]+)".*/\1/')
        curl -SLkO "https://github.com/cli/cli/releases/download/v${GH_LATEST}/gh_${GH_LATEST}_linux_amd64.tar.gz"
        tar -xzf "gh_${GH_LATEST}_linux_amd64.tar.gz" && mv "gh_${GH_LATEST}_linux_amd64/bin/gh" "$HOME/.local/bin/" && rm -rf "gh_${GH_LATEST}_linux_amd64"*
    fi
fi

# ==========================================
# 2. Nerd Fonts
# ==========================================
echo "🔤 Installing FiraCode Nerd Font..."
if [ "$OS_TYPE" = "Linux" ]; then
    mkdir -p ~/.local/share/fonts
    curl -SLkO https://github.com/ryanoasis/nerd-fonts/releases/latest/download/FiraCode.zip
    unzip -qo FiraCode.zip -d ~/.local/share/fonts/ && rm FiraCode.zip
    command -v fc-cache &> /dev/null && fc-cache -fv || true
fi

# ==========================================
# 3. Git & Python (UV)
# ==========================================
git config --global http.sslVerify false

echo "🐍 Installing UV..."
curl -LsSfk https://astral.sh/uv/install.sh | sh
export PATH="$HOME/.cargo/bin:$PATH"
uv tool install ruff httpie pre-commit || echo "⚠️ UV tools failed to install, skipping..."

# ==========================================
# 4. Node.js (FNM)
# ==========================================
echo "🌐 Installing Node.js via fnm..."
curl -fsSLk https://fnm.vercel.app/install | bash -s -- --install-dir "$HOME/.local/bin" --skip-shell
eval "$($HOME/.local/bin/fnm env)"
fnm install --lts && fnm default lts
npm config set strict-ssl false
npm install -g pnpm yarn typescript tsx

# ==========================================
# 5. Starship & LazyVim
# ==========================================
echo "✨ Installing Starship..."
curl -sSk https://starship.rs/install.sh | sh -s -- -y --bin-dir "$HOME/.local/bin"

echo "💤 Installing LazyVim..."
rm -rf ~/.config/nvim
git clone https://github.com/LazyVim/starter ~/.config/nvim
rm -rf ~/.config/nvim/.git

echo -e "\n✅ \033[0;32mSetup Complete!\033[0m"
