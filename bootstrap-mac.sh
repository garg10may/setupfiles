#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=scripts/lib/common.sh
source "$REPO_ROOT/scripts/lib/common.sh"
# shellcheck source=scripts/lib/macos.sh
source "$REPO_ROOT/scripts/lib/macos.sh"

SKIP_GUI=0
PASSTHROUGH_ARGS=()

while (($# > 0)); do
    case "$1" in
        --skip-gui)
            SKIP_GUI=1
            shift
            ;;
        *)
            PASSTHROUGH_ARGS+=("$1")
            shift
            ;;
    esac
done

install_macos_gui_apps() {
    log "Installing macOS GUI apps"
    brew tap koekeishiya/formulae
    brew install koekeishiya/formulae/yabai koekeishiya/formulae/skhd
    brew install --cask wezterm visual-studio-code hammerspoon font-fira-code-nerd-font font-jetbrains-mono-nerd-font
}

install_wezterm_config() {
    log "Installing WezTerm config"
    mkdir -p "$HOME/.config/wezterm"
    cp "$REPO_ROOT/config/wezterm/wezterm.lua" "$HOME/.config/wezterm/wezterm.lua"
}

install_yabai_config() {
    log "Installing yabai config"
    mkdir -p "$HOME/.config/yabai"
    cp "$REPO_ROOT/config/yabai/yabairc" "$HOME/.config/yabai/yabairc"
    chmod +x "$HOME/.config/yabai/yabairc"
}

install_skhd_config() {
    log "Installing skhd config"
    mkdir -p "$HOME/.config/skhd"
    cp "$REPO_ROOT/config/skhd/skhdrc" "$HOME/.config/skhd/skhdrc"
}

install_stackline() {
    log "Installing stackline and Hammerspoon config"
    mkdir -p "$HOME/.hammerspoon"

    if [[ ! -d "$HOME/.hammerspoon/stackline/.git" ]]; then
        git clone https://github.com/AdamWagner/stackline.git "$HOME/.hammerspoon/stackline"
    fi

    cp "$REPO_ROOT/config/hammerspoon/init.lua" "$HOME/.hammerspoon/init.lua"
    cp "$REPO_ROOT/config/hammerspoon/stackline-conf.lua" "$HOME/.hammerspoon/stackline/conf.lua"
}

start_macos_services() {
    log "Starting macOS window manager services"
    brew services restart yabai
    brew services restart skhd
    open -a "Hammerspoon" || true
}

main() {
    log "Starting macOS bootstrap"
    ensure_homebrew

    if ((SKIP_GUI == 0)); then
        install_macos_gui_apps
        install_wezterm_config
        install_yabai_config
        install_skhd_config
        install_stackline
        start_macos_services
    else
        log "Skipping macOS GUI apps"
    fi

    exec "$REPO_ROOT/scripts/dev-unix.sh" --target mac-personal "${PASSTHROUGH_ARGS[@]}"
}

main
