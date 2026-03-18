#!/bin/bash

# Exit on error
set -e

# --- Firewall/Proxy Workaround ---
# This tells Git to ignore SSL errors for the duration of this script
export GIT_SSL_NO_VERIFY=true

echo "≡ƒÜÇ Starting God-Mode Fullstack Developer Environment Setup (Insecure Mode)..."

# Ensure local bin exists for the current user (used for manual binaries)
mkdir -p "$HOME/.local/bin"
export PATH="$HOME/.local/bin:$PATH"

# Detect Operating System
OS_TYPE=$(uname -s)
echo "≡ƒöì Detecting Operating System..."

# ==========================================
# 1. Package Manager, Core Tools & Build Essentials
# ==========================================
if [ "$OS_TYPE" = "Darwin" ]; then
    echo "≡ƒìÅ macOS detected."
    
    if ! command -v brew &> /dev/null; then
        echo "≡ƒôª Homebrew not found. Installing Homebrew..."
        # Added -k to curl
        /bin/bash -c "$(curl -fsSLk https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        if [[ $(uname -m) == "arm64" ]]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
        else
            eval "$(/usr/local/bin/brew shellenv)"
        fi
    fi

    echo "≡ƒ¢á∩╕Å Installing core tools via Homebrew..."
    brew update
    brew install gcc make cmake fish neovim git curl wget jq ripgrep fd zoxide fzf eza python zellij gh

elif [ "$OS_TYPE" = "Linux" ]; then
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        
        # --- DEBIAN / UBUNTU (GCP) ---
        if [[ "$ID" == "ubuntu" || "$ID" == "debian" ]]; then
            echo "≡ƒÉº Debian/Ubuntu detected."
            sudo apt update
            sudo apt install -y software-properties-common build-essential cmake pkg-config unzip tar fontconfig \
                fish git curl wget jq ripgrep fd-find fzf python3-pip python3-venv
            sudo apt install -y zoxide eza || echo "ΓÜá∩╕Å zoxide/eza not found in standard repos, skipping..."

        # --- AMAZON LINUX / RHEL / FEDORA / CENTOS ---
        elif [[ "$ID" == "amzn" || "$ID" == "fedora" || "$ID" == "centos" || "$ID_LIKE" == *"rhel"* ]]; then
            echo "Γÿü∩╕Å Enterprise Linux detected."
            PKG_MGR="yum"
            if command -v dnf &> /dev/null; then PKG_MGR="dnf"; fi
            
            sudo $PKG_MGR install -y epel-release util-linux-user || true 
            sudo $PKG_MGR install -y gcc gcc-c++ make cmake automake autoconf pkgconfig unzip tar fontconfig \
                fish git curl wget jq ripgrep fd-find fzf python3-pip
            sudo $PKG_MGR install -y zoxide eza || echo "ΓÜá∩╕Å zoxide/eza not found in standard repos, skipping..."
        else
            echo "Γ¥î Unsupported Linux distribution: $ID"
            exit 1
        fi

        # ==========================================
        # Linux Custom Binary Downloads (Bypass Repos)
        # ==========================================
        echo "Downloading latest Neovim..."
        NVIM_RELEASE_API="https://api.github.com/repos/neovim/neovim/releases/latest"
        NVIM_ARCH_REGEX=".*"
        case "$(uname -m)" in
            x86_64|amd64) NVIM_ARCH_REGEX="(x86_64|64)" ;;
            aarch64|arm64) NVIM_ARCH_REGEX="(arm64|aarch64)" ;;
        esac

        NVIM_ASSET=$(curl -sSk "$NVIM_RELEASE_API" | jq -r '.assets[].name' | grep -E "^nvim-linux-${NVIM_ARCH_REGEX}\.tar\.gz$" | head -n1)
        if [ -z "$NVIM_ASSET" ]; then
            NVIM_ASSET=$(curl -sSk "$NVIM_RELEASE_API" | jq -r '.assets[].name' | grep -E '^nvim-linux.*\.tar\.gz$' | head -n1)
        fi

        if [ -z "$NVIM_ASSET" ]; then
            echo "ERROR: Failed to determine Neovim Linux tarball asset from GitHub releases."
            exit 1
        fi

        curl -fLk -o nvim-linux.tar.gz "https://github.com/neovim/neovim/releases/latest/download/${NVIM_ASSET}"
        if ! tar -tzf nvim-linux.tar.gz > /dev/null 2>&1; then
            echo "ERROR: Downloaded Neovim archive is invalid (not a tar.gz)."
            exit 1
        fi

        sudo rm -rf /opt/nvim-linux64 /opt/nvim-linux-x86_64 /opt/nvim-linux-arm64
        sudo tar -C /opt -xzf nvim-linux.tar.gz
        rm nvim-linux.tar.gz

        # Keep existing fish PATH config working regardless of extracted folder name.
        if [ -d /opt/nvim-linux-x86_64 ] && [ ! -d /opt/nvim-linux64 ]; then
            sudo ln -sfn /opt/nvim-linux-x86_64 /opt/nvim-linux64
        fi
        if [ -d /opt/nvim-linux-arm64 ] && [ ! -d /opt/nvim-linux64 ]; then
            sudo ln -sfn /opt/nvim-linux-arm64 /opt/nvim-linux64
        fi

        echo "Downloading latest Zellij (Terminal Multiplexer)..."
        ZELLIJ_RELEASE_API="https://api.github.com/repos/zellij-org/zellij/releases/latest"
        ZELLIJ_ARCH="x86_64"
        case "$(uname -m)" in
            x86_64|amd64) ZELLIJ_ARCH="x86_64" ;;
            aarch64|arm64) ZELLIJ_ARCH="aarch64" ;;
        esac

        ZELLIJ_ASSET=$(curl -sSk "$ZELLIJ_RELEASE_API" | jq -r '.assets[].name' | grep -E "^zellij-${ZELLIJ_ARCH}-unknown-linux-(musl|gnu)\.tar\.gz$" | head -n1)
        if [ -z "$ZELLIJ_ASSET" ]; then
            ZELLIJ_ASSET=$(curl -sSk "$ZELLIJ_RELEASE_API" | jq -r '.assets[].name' | grep -E '^zellij-.*-unknown-linux-.*\.tar\.gz$' | head -n1)
        fi

        if [ -z "$ZELLIJ_ASSET" ]; then
            echo "ERROR: Failed to determine Zellij Linux tarball asset from GitHub releases."
            exit 1
        fi

        curl -fLk -o zellij-linux.tar.gz "https://github.com/zellij-org/zellij/releases/latest/download/${ZELLIJ_ASSET}"
        if ! tar -tzf zellij-linux.tar.gz > /dev/null 2>&1; then
            echo "ERROR: Downloaded Zellij archive is invalid (not a tar.gz)."
            exit 1
        fi

        ZELLIJ_TMP_DIR=$(mktemp -d)
        tar -xzf zellij-linux.tar.gz -C "$ZELLIJ_TMP_DIR"
        ZELLIJ_BIN_PATH=$(find "$ZELLIJ_TMP_DIR" -type f -name zellij | head -n1)
        if [ -z "$ZELLIJ_BIN_PATH" ]; then
            echo "ERROR: Zellij binary not found in downloaded archive."
            rm -rf "$ZELLIJ_TMP_DIR" zellij-linux.tar.gz
            exit 1
        fi
        install -m 0755 "$ZELLIJ_BIN_PATH" "$HOME/.local/bin/zellij"
        rm -rf "$ZELLIJ_TMP_DIR" zellij-linux.tar.gz

        echo "Downloading latest GitHub CLI (gh)..."
        GH_RELEASE_API="https://api.github.com/repos/cli/cli/releases/latest"
        GH_ARCH="amd64"
        case "$(uname -m)" in
            x86_64|amd64) GH_ARCH="amd64" ;;
            aarch64|arm64) GH_ARCH="arm64" ;;
        esac

        GH_TAG=$(curl -sSk "$GH_RELEASE_API" | jq -r '.tag_name')
        GH_VERSION="${GH_TAG#v}"
        if [ -z "$GH_VERSION" ] || [ "$GH_VERSION" = "null" ]; then
            echo "ERROR: Failed to determine GitHub CLI version from GitHub releases."
            exit 1
        fi

        GH_ASSET=$(curl -sSk "$GH_RELEASE_API" | jq -r '.assets[].name' | grep -E "^gh_${GH_VERSION}_linux_${GH_ARCH}\.tar\.gz$" | head -n1)
        if [ -z "$GH_ASSET" ]; then
            GH_ASSET=$(curl -sSk "$GH_RELEASE_API" | jq -r '.assets[].name' | grep -E '^gh_.*_linux_.*\.tar\.gz$' | head -n1)
        fi

        if [ -z "$GH_ASSET" ]; then
            echo "ERROR: Failed to determine GitHub CLI Linux tarball asset from GitHub releases."
            exit 1
        fi

        curl -fLk -o gh-linux.tar.gz "https://github.com/cli/cli/releases/latest/download/${GH_ASSET}"
        if ! tar -tzf gh-linux.tar.gz > /dev/null 2>&1; then
            echo "ERROR: Downloaded GitHub CLI archive is invalid (not a tar.gz)."
            exit 1
        fi

        GH_TMP_DIR=$(mktemp -d)
        tar -xzf gh-linux.tar.gz -C "$GH_TMP_DIR"
        GH_BIN_PATH=$(find "$GH_TMP_DIR" -type f -path '*/bin/gh' | head -n1)
        if [ -z "$GH_BIN_PATH" ]; then
            echo "ERROR: gh binary not found in downloaded archive."
            rm -rf "$GH_TMP_DIR" gh-linux.tar.gz
            exit 1
        fi
        install -m 0755 "$GH_BIN_PATH" "$HOME/.local/bin/gh"
        rm -rf "$GH_TMP_DIR" gh-linux.tar.gz
    else
        echo "Γ¥î /etc/os-release not found."
        exit 1
    fi
else
    echo "Γ¥î Unsupported Operating System: $OS_TYPE"
    exit 1
fi

# ==========================================
# 2. Nerd Fonts Installation
# ==========================================
echo "≡ƒöñ Installing FiraCode Nerd Font..."
if [ "$OS_TYPE" = "Darwin" ]; then
    brew install --cask font-fira-code-nerd-font || echo "ΓÜá∩╕Å Could not install font via brew."
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
echo "ΓÜÖ∩╕Å Configuring sensible Git defaults..."
git config --global core.editor "nvim"
git config --global init.defaultBranch "main"
git config --global pull.rebase true
git config --global fetch.prune true
# Make the "ignore certificate" change permanent for this user's git
git config --global http.sslVerify false

# Make curl behave consistently with this script's insecure mode.
cat <<EOF > ~/.curlrc
insecure
EOF

# ==========================================
# 4. Python Setup (via UV)
# ==========================================
echo "≡ƒÉì Installing UV and Python Fullstack Tools..."
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
echo "≡ƒîÉ Installing Node.js via fnm..."
# Install fnm directly from GitHub release assets to avoid installer TLS issues.
FNM_ARCH_ASSET="fnm-linux.zip"
case "$(uname -m)" in
    x86_64|amd64) FNM_ARCH_ASSET="fnm-linux.zip" ;;
    aarch64|arm64) FNM_ARCH_ASSET="fnm-arm64.zip" ;;
    armv7l|armv6l) FNM_ARCH_ASSET="fnm-arm32.zip" ;;
esac

curl -fLk -o fnm.zip "https://github.com/Schniz/fnm/releases/latest/download/${FNM_ARCH_ASSET}"
FNM_TMP_DIR=$(mktemp -d)
unzip -qo fnm.zip -d "$FNM_TMP_DIR"
FNM_BIN_PATH=$(find "$FNM_TMP_DIR" -type f -name fnm | head -n1)
if [ -z "$FNM_BIN_PATH" ]; then
    echo "ERROR: fnm binary not found in downloaded archive."
    rm -rf "$FNM_TMP_DIR" fnm.zip
    exit 1
fi
install -m 0755 "$FNM_BIN_PATH" "$HOME/.local/bin/fnm"
rm -rf "$FNM_TMP_DIR" fnm.zip

eval "$("$HOME/.local/bin/fnm" env --shell bash)"

if fnm install --lts; then
    if fnm list | grep -q 'lts-latest'; then
        fnm default lts-latest
        fnm use lts-latest
    else
        FNM_LTS_VERSION=$(fnm list | sed -n 's/.*\(v[0-9][0-9.]*\).*/\1/p' | head -n1)
        if [ -n "$FNM_LTS_VERSION" ]; then
            fnm default "$FNM_LTS_VERSION"
            fnm use "$FNM_LTS_VERSION"
        fi
    fi
else
    echo "WARN: fnm failed to install Node.js LTS (likely TLS interception). Falling back to system package manager."
    if command -v apt-get > /dev/null 2>&1; then
        sudo apt update
        sudo apt install -y nodejs npm
    elif command -v dnf > /dev/null 2>&1; then
        sudo dnf install -y nodejs npm
    elif command -v yum > /dev/null 2>&1; then
        sudo yum install -y nodejs npm
    else
        echo "ERROR: No supported package manager found for Node.js fallback install."
        exit 1
    fi
fi

if ! command -v node > /dev/null 2>&1 || ! command -v npm > /dev/null 2>&1; then
    echo "ERROR: Node.js or npm is not available after installation step."
    exit 1
fi

# npm also needs to ignore SSL
npm config set strict-ssl false
npm install -g pnpm yarn typescript tsx npm-check-updates

# ==========================================
# 6. Install Starship Prompt
# ==========================================
echo "Γ£¿ Installing Starship..."
STARSHIP_ARCH="x86_64"
STARSHIP_LIBC="gnu"
case "$(uname -m)" in
    x86_64|amd64) STARSHIP_ARCH="x86_64" ;;
    aarch64|arm64) STARSHIP_ARCH="aarch64" ;;
    armv7l|armv6l) STARSHIP_ARCH="arm" ;;
    i686|i386) STARSHIP_ARCH="i686" ;;
esac

if ldd --version 2>&1 | grep -qi musl; then
    STARSHIP_LIBC="musl"
fi

STARSHIP_RELEASE_API="https://api.github.com/repos/starship/starship/releases/latest"
STARSHIP_ASSET=$(curl -sSk "$STARSHIP_RELEASE_API" | jq -r '.assets[].name' | grep -E "^starship-${STARSHIP_ARCH}-unknown-linux-${STARSHIP_LIBC}.*\.tar\.gz$" | head -n1)
if [ -z "$STARSHIP_ASSET" ]; then
    STARSHIP_ASSET=$(curl -sSk "$STARSHIP_RELEASE_API" | jq -r '.assets[].name' | grep -E "^starship-${STARSHIP_ARCH}-unknown-linux-.*\.tar\.gz$" | head -n1)
fi

if [ -z "$STARSHIP_ASSET" ]; then
    echo "ERROR: Failed to determine Starship Linux tarball asset from GitHub releases."
    exit 1
fi

curl -fLk -o starship-linux.tar.gz "https://github.com/starship/starship/releases/latest/download/${STARSHIP_ASSET}"
if ! tar -tzf starship-linux.tar.gz > /dev/null 2>&1; then
    echo "ERROR: Downloaded Starship archive is invalid (not a tar.gz)."
    exit 1
fi

STARSHIP_TMP_DIR=$(mktemp -d)
tar -xzf starship-linux.tar.gz -C "$STARSHIP_TMP_DIR"
STARSHIP_BIN_PATH=$(find "$STARSHIP_TMP_DIR" -type f -name starship | head -n1)
if [ -z "$STARSHIP_BIN_PATH" ]; then
    echo "ERROR: Starship binary not found in downloaded archive."
    rm -rf "$STARSHIP_TMP_DIR" starship-linux.tar.gz
    exit 1
fi
install -m 0755 "$STARSHIP_BIN_PATH" "$HOME/.local/bin/starship"
rm -rf "$STARSHIP_TMP_DIR" starship-linux.tar.gz

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
echo "≡ƒÆñ Installing LazyVim Starter..."
rm -rf ~/.config/nvim
# Since we exported GIT_SSL_NO_VERIFY=true, this should work
git clone https://github.com/LazyVim/starter ~/.config/nvim
rm -rf ~/.config/nvim/.git
mkdir -p ~/.config/nvim/lua/plugins

cat <<EOF > ~/.config/nvim/lua/plugins/blink.lua
return {
    {
        "saghen/blink.cmp",
        opts = {
            fuzzy = {
                prebuilt_binaries = {
                    extra_curl_args = { "--insecure" },
                },
            },
        },
    },
}
EOF

# ==========================================
# 9. Finalize
# ==========================================
echo "Γ£à Setup Complete!"
echo "≡ƒæë Run: 'chsh -s \$(which fish)' to make Fish your default shell."
echo "≡ƒæë Restart your terminal or reconnect via SSH."
