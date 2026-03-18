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
    brew install --cask wezterm visual-studio-code font-fira-code-nerd-font font-jetbrains-mono-nerd-font
}

install_wezterm_config() {
    log "Installing WezTerm config"
    mkdir -p "$HOME/.config/wezterm"
    cp "$REPO_ROOT/config/wezterm/wezterm.lua" "$HOME/.config/wezterm/wezterm.lua"
}

main() {
    log "Starting macOS bootstrap"
    ensure_homebrew

    if ((SKIP_GUI == 0)); then
        install_macos_gui_apps
        install_wezterm_config
    else
        log "Skipping macOS GUI apps"
    fi

    exec "$REPO_ROOT/scripts/dev-unix.sh" --target mac-personal "${PASSTHROUGH_ARGS[@]}"
}

main
