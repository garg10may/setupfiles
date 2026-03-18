#!/bin/bash

set -euo pipefail

log() {
    printf '\n==> %s\n' "$1"
}

warn() {
    printf '⚠️  %s\n' "$1"
}

fail() {
    printf '❌ %s\n' "$1" >&2
    exit 1
}

detect_arch() {
    case "$(uname -m)" in
        x86_64|amd64)
            ARCH="amd64"
            NEOVIM_ARCHIVE="nvim-linux64.tar.gz"
            NEOVIM_DIR="/opt/nvim-linux64"
            ZELLIJ_ARCHIVE="zellij-x86_64-unknown-linux-musl.tar.gz"
            GH_ARCHIVE_SUFFIX="linux_amd64"
            ;;
        arm64|aarch64)
            ARCH="arm64"
            NEOVIM_ARCHIVE="nvim-linux-arm64.tar.gz"
            NEOVIM_DIR="/opt/nvim-linux-arm64"
            ZELLIJ_ARCHIVE="zellij-aarch64-unknown-linux-musl.tar.gz"
            GH_ARCHIVE_SUFFIX="linux_arm64"
            ;;
        *)
            fail "Unsupported CPU architecture: $(uname -m)"
            ;;
    esac
}

ensure_homebrew() {
    if command -v brew &> /dev/null; then
        return
    fi

    log "Homebrew not found. Installing Homebrew"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    if [[ "$(uname -m)" == "arm64" ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    else
        eval "$(/usr/local/bin/brew shellenv)"
    fi
}

setup_macos() {
    log "macOS detected"
    ensure_homebrew

    log "Installing core tools via Homebrew"
    brew update
    brew install gcc make cmake fish neovim git curl wget jq ripgrep fd zoxide fzf eza python zellij gh
}

setup_linux() {
    [ -f /etc/os-release ] || fail "/etc/os-release not found"
    . /etc/os-release

    detect_arch

    if [[ "$ID" == "ubuntu" || "$ID" == "debian" ]]; then
        log "Debian/Ubuntu detected"
        sudo apt update
        sudo apt install -y software-properties-common build-essential cmake pkg-config unzip tar fontconfig \
            fish git curl wget jq ripgrep fd-find fzf python3-pip python3-venv
        sudo apt install -y zoxide eza || warn "zoxide/eza not found in standard repos, skipping"
    elif [[ "$ID" == "amzn" || "$ID" == "fedora" || "$ID" == "centos" || "${ID_LIKE:-}" == *"rhel"* ]]; then
        log "Enterprise Linux detected"
        PKG_MGR="yum"
        if command -v dnf &> /dev/null; then
            PKG_MGR="dnf"
        fi

        sudo "$PKG_MGR" install -y epel-release util-linux-user || true
        sudo "$PKG_MGR" install -y gcc gcc-c++ make cmake automake autoconf pkgconfig unzip tar fontconfig \
            fish git curl wget jq ripgrep fd-find fzf python3-pip
        sudo "$PKG_MGR" install -y zoxide eza || warn "zoxide/eza not found in standard repos, skipping"
    else
        fail "Unsupported Linux distribution: $ID"
    fi

    log "Downloading Neovim for ${ARCH}"
    curl -LO "https://github.com/neovim/neovim/releases/latest/download/${NEOVIM_ARCHIVE}"
    sudo rm -rf "$NEOVIM_DIR"
    sudo tar -C /opt -xzf "$NEOVIM_ARCHIVE"
    rm -f "$NEOVIM_ARCHIVE"

    log "Downloading Zellij for ${ARCH}"
    curl -LO "https://github.com/zellij-org/zellij/releases/latest/download/${ZELLIJ_ARCHIVE}"
    tar -xzf "$ZELLIJ_ARCHIVE"
    mv zellij "$HOME/.local/bin/"
    rm -f "$ZELLIJ_ARCHIVE"

    log "Downloading GitHub CLI for ${ARCH}"
    GH_LATEST="$(curl -s https://api.github.com/repos/cli/cli/releases/latest | grep '"tag_name":' | sed -E 's/.*"v([^"]+)".*/\1/')"
    GH_ARCHIVE="gh_${GH_LATEST}_${GH_ARCHIVE_SUFFIX}.tar.gz"
    GH_DIR="gh_${GH_LATEST}_${GH_ARCHIVE_SUFFIX}"
    curl -LO "https://github.com/cli/cli/releases/download/v${GH_LATEST}/${GH_ARCHIVE}"
    tar -xzf "$GH_ARCHIVE"
    mv "${GH_DIR}/bin/gh" "$HOME/.local/bin/"
    rm -rf "$GH_DIR" "$GH_ARCHIVE"
}

install_fonts() {
    log "Installing Nerd Fonts"
    if [ "$OS_TYPE" = "Darwin" ]; then
        brew install --cask font-fira-code-nerd-font || warn "Could not install FiraCode Nerd Font via brew"
        brew install --cask font-jetbrains-mono-nerd-font || warn "Could not install JetBrains Mono Nerd Font via brew"
        return
    fi

    mkdir -p "$HOME/.local/share/fonts"
    curl -LO https://github.com/ryanoasis/nerd-fonts/releases/latest/download/FiraCode.zip
    unzip -qo FiraCode.zip -d "$HOME/.local/share/fonts/"
    rm -f FiraCode.zip
    if command -v fc-cache &> /dev/null; then
        fc-cache -fv || true
    fi
    warn "If you SSH into this Linux machine, install a Nerd Font on your local terminal too"
}

install_wezterm_for_macos() {
    if [ "$OS_TYPE" != "Darwin" ]; then
        return
    fi

    log "Installing WezTerm"
    brew install --cask wezterm || warn "Could not install WezTerm via brew"

    log "Installing WezTerm config"
    mkdir -p "$HOME/.config/wezterm"
    cp "$REPO_ROOT/wezterm.lua" "$HOME/.config/wezterm/wezterm.lua"
}

configure_git() {
    log "Configuring sensible Git defaults"
    git config --global core.editor "nvim"
    git config --global init.defaultBranch "main"
    git config --global pull.rebase true
    git config --global fetch.prune true
}

install_python_tools() {
    log "Installing UV and Python tools"
    curl -LsSf https://astral.sh/uv/install.sh | sh
    export PATH="$HOME/.cargo/bin:$PATH"

    uv tool install ruff
    uv tool install httpie
    uv tool install pre-commit
}

install_node_tools() {
    log "Installing Node.js via fnm"
    if ! command -v fnm &> /dev/null; then
        curl -fsSL https://fnm.vercel.app/install | bash -s -- --install-dir "$HOME/.local/bin" --skip-shell
    fi

    FNM_BIN="$(command -v fnm || true)"
    if [ -z "$FNM_BIN" ] && [ -x "$HOME/.local/bin/fnm" ]; then
        FNM_BIN="$HOME/.local/bin/fnm"
    fi

    [ -n "$FNM_BIN" ] || fail "fnm was not installed correctly"

    eval "$("$FNM_BIN" env --shell bash)"

    "$FNM_BIN" install --lts
    NODE_LTS_VERSION="$("$FNM_BIN" current)"
    if [ -z "$NODE_LTS_VERSION" ] || [ "$NODE_LTS_VERSION" = "system" ]; then
        fail "fnm did not activate an LTS Node version"
    fi

    "$FNM_BIN" default "$NODE_LTS_VERSION"
    "$FNM_BIN" use "$NODE_LTS_VERSION"
    npm install -g pnpm yarn typescript tsx npm-check-updates
}

install_starship() {
    log "Installing Starship"
    curl -sS https://starship.rs/install.sh | sh -s -- -y --bin-dir "$HOME/.local/bin"
}

write_fish_config() {
    log "Writing Fish config"
    mkdir -p "$HOME/.config/fish" "$HOME/.config/nvim"

    cat <<EOF > "$HOME/.config/fish/config.fish"
# --- Pathing ---
set -gx PATH "\$HOME/.local/bin" \$PATH
set -gx PATH "\$HOME/.cargo/bin" \$PATH # For UV tools
set -gx PATH "/opt/homebrew/bin" \$PATH # macOS Apple Silicon fallback
set -gx PATH "/opt/nvim-linux64/bin" \$PATH # Linux manual Neovim fallback
set -gx PATH "/opt/nvim-linux-arm64/bin" \$PATH # Linux ARM Neovim fallback

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

# --- POWER ABBREVIATIONS ---
# Git & GitHub
abbr gs  "git status"
abbr ga  "git add"
abbr gc  "git commit -m"
abbr gp  "git push"
abbr gl  "git log --oneline --graph --decorate"
abbr pr  "gh pr create"

# Multiplexer
abbr zj "zellij"
abbr za "zellij attach"

# Python / UV
abbr ua  "uv add"
abbr us  "uv sync"
abbr ur  "uv run"
abbr ut  "uv tree"
abbr venv "source .venv/bin/activate.fish"

# Node / JS
abbr nd  "npm run dev"
abbr nb  "npm run build"
abbr ns  "npm start"
abbr pd  "pnpm dev"
abbr yd  "yarn dev"

# System
abbr ..   "cd .."
abbr ...  "cd ../.."
abbr h    "history"
abbr cl   "clear"
abbr ports "lsof -i -P -n | grep LISTEN"

# Neovim
abbr nv   "nvim"
abbr nvc  "cd ~/.config/nvim && nvim"
EOF
}

setup_lazyvim() {
    log "Installing LazyVim Starter"
    rm -rf "$HOME/.config/nvim"
    git clone https://github.com/LazyVim/starter "$HOME/.config/nvim"
    rm -rf "$HOME/.config/nvim/.git"
}

print_versions() {
    log "Installed tool versions"

    if command -v git &> /dev/null; then
        printf 'git: %s\n' "$(git --version)"
    fi
    if command -v nvim &> /dev/null; then
        printf 'nvim: %s\n' "$(nvim --version | head -n 1)"
    fi
    if command -v fish &> /dev/null; then
        printf 'fish: %s\n' "$(fish --version)"
    fi
    if command -v uv &> /dev/null; then
        printf 'uv: %s\n' "$(uv --version)"
    fi
    if command -v node &> /dev/null; then
        printf 'node: %s\n' "$(node --version)"
    fi
    if command -v npm &> /dev/null; then
        printf 'npm: %s\n' "$(npm --version)"
    fi
    if command -v pnpm &> /dev/null; then
        printf 'pnpm: %s\n' "$(pnpm --version)"
    fi
    if command -v yarn &> /dev/null; then
        printf 'yarn: %s\n' "$(yarn --version)"
    fi
    if command -v wezterm &> /dev/null; then
        printf 'wezterm: %s\n' "$(wezterm --version)"
    fi
    if command -v zellij &> /dev/null; then
        printf 'zellij: %s\n' "$(zellij --version)"
    fi
    if command -v starship &> /dev/null; then
        printf 'starship: %s\n' "$(starship --version)"
    fi
}

main() {
    REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"

    log "Starting God-Mode Fullstack Developer Environment Setup"

    mkdir -p "$HOME/.local/bin"
    export PATH="$HOME/.local/bin:$PATH"

    OS_TYPE="$(uname -s)"
    log "Detected operating system: ${OS_TYPE}"

    case "$OS_TYPE" in
        Darwin)
            setup_macos
            ;;
        Linux)
            setup_linux
            ;;
        *)
            fail "Unsupported Operating System: $OS_TYPE"
            ;;
    esac

    install_fonts
    install_wezterm_for_macos
    configure_git
    install_python_tools
    install_node_tools
    install_starship
    write_fish_config
    setup_lazyvim
    print_versions

    log "Setup complete"
    printf "👉 Run: 'chsh -s \$(which fish)' to make Fish your default shell.\n"
    printf "👉 Run: 'git config --global user.name \"Your Name\"' and 'git config --global user.email \"you@example.com\"'.\n"
    printf "👉 Then restart your terminal or reconnect via SSH.\n"
}

main "$@"
