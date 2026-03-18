#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# shellcheck source=scripts/lib/common.sh
source "$REPO_ROOT/scripts/lib/common.sh"
# shellcheck source=scripts/lib/macos.sh
source "$REPO_ROOT/scripts/lib/macos.sh"

TARGET=""

parse_args() {
    while (($# > 0)); do
        case "$1" in
            --target)
                [[ $# -ge 2 ]] || fail "--target requires a value"
                TARGET="$2"
                shift 2
                ;;
            --target=*)
                TARGET="${1#*=}"
                shift
                ;;
            *)
                fail "Unknown argument: $1"
                ;;
        esac
    done
}

ensure_npm_global_package() {
    local package_name="$1"
    local command_name="$2"

    if command -v "$command_name" >/dev/null 2>&1; then
        return
    fi

    npm install -g "$package_name" >/dev/null
}

pick_github_asset() {
    local repo="$1"
    local regex="$2"

    curl -fsSL "https://api.github.com/repos/${repo}/releases/latest" | jq -r '.assets[].name' | grep -E "$regex" | head -n 1
}

install_neovim_linux() {
    local asset archive temp_dir extracted_dir regex

    regex='^nvim-linux-.*\.tar\.gz$'
    if [[ "$ARCH" == "amd64" ]]; then
        regex='^nvim-linux-(x86_64|64).*\.tar\.gz$'
    elif [[ "$ARCH" == "arm64" ]]; then
        regex='^nvim-linux-(arm64|aarch64).*\.tar\.gz$'
    fi

    asset="$(pick_github_asset neovim/neovim "$regex")"
    [[ -n "$asset" ]] || fail "Could not resolve the latest Neovim archive"

    archive="$(mktemp -t nvim-archive.XXXXXX.tar.gz)"
    temp_dir="$(mktemp -d)"

    curl -fL "https://github.com/neovim/neovim/releases/latest/download/${asset}" -o "$archive"
    tar -xzf "$archive" -C "$temp_dir"

    extracted_dir="$(find "$temp_dir" -mindepth 1 -maxdepth 1 -type d | head -n 1)"
    [[ -n "$extracted_dir" ]] || fail "Could not unpack the Neovim archive"

    rm -rf "$HOME/.local/opt/nvim"
    mv "$extracted_dir" "$HOME/.local/opt/nvim"
    ln -sfn "$HOME/.local/opt/nvim/bin/nvim" "$HOME/.local/bin/nvim"

    rm -rf "$temp_dir" "$archive"
}

install_zellij_linux() {
    local asset archive temp_dir binary_path regex

    if [[ "$ARCH" == "amd64" ]]; then
        regex='^zellij-x86_64-unknown-linux-(musl|gnu)\.tar\.gz$'
    else
        regex='^zellij-aarch64-unknown-linux-(musl|gnu)\.tar\.gz$'
    fi

    asset="$(pick_github_asset zellij-org/zellij "$regex")"
    [[ -n "$asset" ]] || fail "Could not resolve the latest Zellij archive"

    archive="$(mktemp -t zellij-archive.XXXXXX.tar.gz)"
    temp_dir="$(mktemp -d)"

    curl -fL "https://github.com/zellij-org/zellij/releases/latest/download/${asset}" -o "$archive"
    tar -xzf "$archive" -C "$temp_dir"

    binary_path="$(find "$temp_dir" -type f -name zellij | head -n 1)"
    [[ -n "$binary_path" ]] || fail "Could not find the Zellij binary in the archive"

    install -m 0755 "$binary_path" "$HOME/.local/bin/zellij"

    rm -rf "$temp_dir" "$archive"
}

install_gh_linux() {
    local tag version asset archive temp_dir binary_path

    tag="$(curl -fsSL https://api.github.com/repos/cli/cli/releases/latest | jq -r '.tag_name')"
    version="${tag#v}"
    [[ -n "$version" && "$version" != "null" ]] || fail "Could not resolve the latest GitHub CLI version"

    asset="gh_${version}_${GH_ARCHIVE_SUFFIX}.tar.gz"
    archive="$(mktemp -t gh-archive.XXXXXX.tar.gz)"
    temp_dir="$(mktemp -d)"

    curl -fL "https://github.com/cli/cli/releases/download/v${version}/${asset}" -o "$archive"
    tar -xzf "$archive" -C "$temp_dir"

    binary_path="$(find "$temp_dir" -type f -path '*/bin/gh' | head -n 1)"
    [[ -n "$binary_path" ]] || fail "Could not find the gh binary in the archive"

    install -m 0755 "$binary_path" "$HOME/.local/bin/gh"

    rm -rf "$temp_dir" "$archive"
}

install_macos_package_groups() {
    log "Ensuring macOS base CLI packages"
    ensure_brew_formula gcc
    ensure_brew_formula make
    ensure_brew_formula cmake
    ensure_brew_formula fish
    ensure_brew_formula neovim
    ensure_brew_formula git
    ensure_brew_formula curl
    ensure_brew_formula wget
    ensure_brew_formula jq
    ensure_brew_formula ripgrep
    ensure_brew_formula fd
    ensure_brew_formula zoxide
    ensure_brew_formula fzf
    ensure_brew_formula eza
    ensure_brew_formula zellij
    ensure_brew_formula gh
    ensure_brew_formula starship
    ensure_brew_formula bat
    ensure_brew_formula dust
    ensure_brew_formula direnv
    ensure_brew_formula git-delta
    ensure_brew_formula just
    ensure_brew_formula btop
    ensure_brew_formula shellcheck
    ensure_brew_formula tldr
    ensure_brew_formula xh

    log "Ensuring macOS language toolchains"
    ensure_brew_formula python
    ensure_brew_formula uv
    ensure_brew_formula fnm
}

setup_macos() {
    log "Setting up macOS developer tools"
    ensure_homebrew
    install_macos_package_groups
}

install_wsl_package_groups() {
    log "Installing Ubuntu base CLI packages for WSL"
    sudo apt install -y software-properties-common build-essential cmake pkg-config unzip tar fontconfig \
        fish git curl wget jq ripgrep fd-find fzf zoxide python3 python3-pip python3-venv \
        bat direnv just shellcheck tldr

    log "Installing Ubuntu convenience packages for WSL"
    sudo apt install -y eza git-delta btop dust xh || warn "Some convenience packages are not available in the default Ubuntu repositories"
}

setup_wsl_ubuntu() {
    local distro_id

    is_wsl || warn "Target is WSL Ubuntu, but the environment does not look like WSL"
    [[ -f /etc/os-release ]] || fail "/etc/os-release not found"
    # shellcheck disable=SC1091
    source /etc/os-release
    distro_id="${ID:-}"

    [[ "$distro_id" == "ubuntu" ]] || fail "Expected Ubuntu inside WSL, found: ${distro_id:-unknown}"

    detect_arch

    sudo apt update
    install_wsl_package_groups

    log "Installing user-space binaries"
    install_neovim_linux
    install_zellij_linux
    install_gh_linux
}

configure_git() {
    log "Configuring Git defaults"
    git config --global core.editor "nvim"
    git config --global init.defaultBranch "main"
    git config --global pull.rebase true
    git config --global fetch.prune true
    git config --global merge.conflictstyle zdiff3
    git config --global rebase.autostash true
    if command -v delta >/dev/null 2>&1; then
        git config --global core.pager "delta"
        git config --global interactive.diffFilter "delta --color-only"
        git config --global delta.navigate true
        git config --global delta.light false
    fi
}

install_gitignore_global() {
    if copy_file_if_different "$REPO_ROOT/config/git/ignore" "$HOME/.config/git/ignore"; then
        log "Installed global gitignore"
    fi
    git config --global core.excludesfile "$HOME/.config/git/ignore"
}

install_python_tools() {
    log "Ensuring Python developer tools"

    if ! command -v uv >/dev/null 2>&1; then
        curl -LsSf https://astral.sh/uv/install.sh | sh
        export PATH="$HOME/.cargo/bin:$PATH"
    fi

    if ! command -v ruff >/dev/null 2>&1; then
        uv tool install ruff
    fi
    if ! command -v http >/dev/null 2>&1; then
        uv tool install httpie
    fi
    if ! command -v pre-commit >/dev/null 2>&1; then
        uv tool install pre-commit
    fi
    if ! command -v basedpyright >/dev/null 2>&1; then
        uv tool install basedpyright
    fi
}

install_node_tools() {
    local fnm_bin node_lts_version

    log "Ensuring Node.js via fnm"

    if ! command -v fnm >/dev/null 2>&1; then
        curl -fsSL https://fnm.vercel.app/install | bash -s -- --install-dir "$HOME/.local/bin" --skip-shell
    fi

    fnm_bin="$(command -v fnm || true)"
    if [[ -z "$fnm_bin" && -x "$HOME/.local/bin/fnm" ]]; then
        fnm_bin="$HOME/.local/bin/fnm"
    fi

    [[ -n "$fnm_bin" ]] || fail "fnm was not installed correctly"

    eval "$("$fnm_bin" env --shell bash)"

    node_lts_version="$("$fnm_bin" current)"
    if [[ -z "$node_lts_version" || "$node_lts_version" == "system" ]]; then
        "$fnm_bin" install --lts >/dev/null
        node_lts_version="$("$fnm_bin" current)"
        [[ -n "$node_lts_version" && "$node_lts_version" != "system" ]] || fail "fnm did not activate an LTS Node version"
        "$fnm_bin" default "$node_lts_version" >/dev/null
        "$fnm_bin" use "$node_lts_version" >/dev/null
    fi

    ensure_npm_global_package pnpm pnpm
    ensure_npm_global_package yarn yarn
    ensure_npm_global_package typescript tsc
    ensure_npm_global_package tsx tsx
    ensure_npm_global_package npm-check-updates ncu
}

install_starship() {
    if command -v starship >/dev/null 2>&1; then
        return
    fi

    log "Installing Starship"
    curl -sS https://starship.rs/install.sh | sh -s -- -y --bin-dir "$HOME/.local/bin"
}

install_fish_config() {
    if copy_file_if_different "$REPO_ROOT/config/fish/dev-bootstrap.fish" "$HOME/.config/fish/conf.d/dev-bootstrap.fish"; then
        log "Installed Fish config"
    fi
}

install_repo_nvim_defaults() {
    log "Installing repo LazyVim defaults"
    cp -R "$REPO_ROOT/config/nvim/." "$HOME/.config/nvim/"
}

setup_lazyvim() {
    if [[ -e "$HOME/.config/nvim" ]]; then
        info "Skipping LazyVim bootstrap because ~/.config/nvim already exists"
        return
    fi

    log "Installing LazyVim starter"
    mkdir -p "$HOME/.config"
    git clone https://github.com/LazyVim/starter "$HOME/.config/nvim"
    rm -rf "$HOME/.config/nvim/.git"
    install_repo_nvim_defaults
}

print_versions() {
    log "Installed tool versions"

    if command -v git >/dev/null 2>&1; then
        printf 'git: %s\n' "$(git --version)"
    fi
    if command -v nvim >/dev/null 2>&1; then
        printf 'nvim: %s\n' "$(nvim --version | head -n 1)"
    fi
    if command -v fish >/dev/null 2>&1; then
        printf 'fish: %s\n' "$(fish --version)"
    fi
    if command -v uv >/dev/null 2>&1; then
        printf 'uv: %s\n' "$(uv --version)"
    fi
    if command -v node >/dev/null 2>&1; then
        printf 'node: %s\n' "$(node --version)"
    fi
    if command -v npm >/dev/null 2>&1; then
        printf 'npm: %s\n' "$(npm --version)"
    fi
    if command -v pnpm >/dev/null 2>&1; then
        printf 'pnpm: %s\n' "$(pnpm --version)"
    fi
    if command -v yarn >/dev/null 2>&1; then
        printf 'yarn: %s\n' "$(yarn --version)"
    fi
    if command -v bat >/dev/null 2>&1; then
        printf 'bat: %s\n' "$(bat --version | head -n 1)"
    fi
    if command -v btop >/dev/null 2>&1; then
        printf 'btop: %s\n' "$(btop --version | head -n 1)"
    fi
    if command -v delta >/dev/null 2>&1; then
        printf 'delta: %s\n' "$(delta --version | head -n 1)"
    fi
    if command -v direnv >/dev/null 2>&1; then
        printf 'direnv: %s\n' "$(direnv version)"
    fi
    if command -v dust >/dev/null 2>&1; then
        printf 'dust: %s\n' "$(dust --version)"
    fi
    if command -v just >/dev/null 2>&1; then
        printf 'just: %s\n' "$(just --version)"
    fi
    if command -v tldr >/dev/null 2>&1; then
        printf 'tldr: %s\n' "$(tldr --version | head -n 1)"
    fi
    if command -v xh >/dev/null 2>&1; then
        printf 'xh: %s\n' "$(xh --version | head -n 1)"
    fi
    if command -v zellij >/dev/null 2>&1; then
        printf 'zellij: %s\n' "$(zellij --version)"
    fi
    if command -v starship >/dev/null 2>&1; then
        printf 'starship: %s\n' "$(starship --version | head -n 1)"
    fi
    if command -v gh >/dev/null 2>&1; then
        printf 'gh: %s\n' "$(gh --version | head -n 1)"
    fi
}

print_next_steps() {
    log "Setup complete for ${TARGET}"
    printf "Run: chsh -s \$(which fish)\n"
    printf "Run: git config --global user.name \"Your Name\"\n"
    printf "Run: git config --global user.email \"you@example.com\"\n"
    printf "Restart the terminal session after the install finishes.\n"
}

main() {
    parse_args "$@"

    if [[ -z "$TARGET" ]]; then
        if [[ "$(uname -s)" == "Darwin" ]]; then
            TARGET="mac-personal"
        elif is_wsl; then
            TARGET="wsl-ubuntu"
        else
            fail "Could not infer a supported target. Use --target mac-personal or --target wsl-ubuntu."
        fi
    fi

    ensure_local_bin

    case "$TARGET" in
        mac-personal)
            setup_macos
            ;;
        wsl-ubuntu)
            setup_wsl_ubuntu
            ;;
        *)
            fail "Unsupported target: $TARGET"
            ;;
    esac

    configure_git
    install_gitignore_global
    install_python_tools
    install_node_tools
    install_starship
    install_fish_config
    setup_lazyvim
    print_versions
    print_next_steps
}

main "$@"
