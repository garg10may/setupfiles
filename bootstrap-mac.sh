#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=scripts/lib/common.sh
source "$REPO_ROOT/scripts/lib/common.sh"
# shellcheck source=scripts/lib/macos.sh
source "$REPO_ROOT/scripts/lib/macos.sh"

SKIP_GUI=0
PASSTHROUGH_ARGS=()
WEZTERM_CONFIG_CHANGED=0
YABAI_CONFIG_CHANGED=0
SKHD_CONFIG_CHANGED=0
HAMMERSPOON_CONFIG_CHANGED=0
STACKLINE_INSTALLED=0
YABAI_INSTALLED=0
SKHD_INSTALLED=0
HAMMERSPOON_INSTALLED=0

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
    log "Ensuring macOS GUI apps"
    ensure_brew_tap "koekeishiya/formulae"
    ensure_brew_formula "koekeishiya/formulae/yabai"
    if ((BREW_ACTION_TAKEN == 1)); then
        YABAI_INSTALLED=1
    fi
    ensure_brew_formula "koekeishiya/formulae/skhd"
    if ((BREW_ACTION_TAKEN == 1)); then
        SKHD_INSTALLED=1
    fi
    ensure_brew_cask "wezterm" "/Applications/WezTerm.app"
    ensure_brew_cask "visual-studio-code" "/Applications/Visual Studio Code.app"
    ensure_brew_cask "hammerspoon" "/Applications/Hammerspoon.app"
    if ((BREW_ACTION_TAKEN == 1)); then
        HAMMERSPOON_INSTALLED=1
    fi
    ensure_brew_cask "font-fira-code-nerd-font"
    ensure_brew_cask "font-jetbrains-mono-nerd-font"
}

install_wezterm_config() {
    if copy_file_if_different "$REPO_ROOT/config/wezterm/wezterm.lua" "$HOME/.config/wezterm/wezterm.lua"; then
        WEZTERM_CONFIG_CHANGED=1
        log "Installed WezTerm config"
    fi
}

install_yabai_config() {
    if copy_file_if_different "$REPO_ROOT/config/yabai/yabairc" "$HOME/.config/yabai/yabairc" 0755; then
        YABAI_CONFIG_CHANGED=1
        log "Installed yabai config"
    fi
}

install_skhd_config() {
    if copy_file_if_different "$REPO_ROOT/config/skhd/skhdrc" "$HOME/.config/skhd/skhdrc"; then
        SKHD_CONFIG_CHANGED=1
        log "Installed skhd config"
    fi
}

install_stackline() {
    mkdir -p "$HOME/.hammerspoon"

    if [[ ! -d "$HOME/.hammerspoon/stackline/.git" ]]; then
        STACKLINE_INSTALLED=1
        log "Installing stackline"
        git clone https://github.com/AdamWagner/stackline.git "$HOME/.hammerspoon/stackline"
    fi

    if copy_file_if_different "$REPO_ROOT/config/hammerspoon/init.lua" "$HOME/.hammerspoon/init.lua"; then
        HAMMERSPOON_CONFIG_CHANGED=1
        log "Installed Hammerspoon init config"
    fi

    if copy_file_if_different "$REPO_ROOT/config/hammerspoon/stackline-conf.lua" "$HOME/.hammerspoon/stackline/conf.lua"; then
        HAMMERSPOON_CONFIG_CHANGED=1
        log "Installed stackline config"
    fi
}

start_macos_services() {
    log "Starting macOS window manager services"
    if pgrep -x yabai >/dev/null 2>&1; then
        if ((YABAI_CONFIG_CHANGED == 1)); then
            /opt/homebrew/bin/yabai --restart-service >/dev/null 2>&1 || warn "Could not restart yabai automatically"
        fi
    elif ! /opt/homebrew/bin/yabai --start-service >/dev/null 2>&1; then
        warn "Could not start yabai automatically"
    fi

    if pgrep -x skhd >/dev/null 2>&1; then
        if ((SKHD_CONFIG_CHANGED == 1)); then
            /opt/homebrew/bin/skhd --restart-service >/dev/null 2>&1 || warn "Could not restart skhd automatically"
        fi
    elif ! /opt/homebrew/bin/skhd --start-service >/dev/null 2>&1; then
        warn "Could not start skhd automatically"
    fi

    if pgrep -x Hammerspoon >/dev/null 2>&1; then
        if ((HAMMERSPOON_CONFIG_CHANGED == 0 && STACKLINE_INSTALLED == 0)); then
            return
        fi
    fi

    if [[ -d "/Applications/Hammerspoon.app" ]]; then
        open "/Applications/Hammerspoon.app" || warn "Could not open Hammerspoon"
    elif [[ -d "$HOME/Applications/Hammerspoon.app" ]]; then
        open "$HOME/Applications/Hammerspoon.app" || warn "Could not open Hammerspoon"
    else
        warn "Hammerspoon.app was not found in /Applications or ~/Applications"
    fi
}

print_macos_manual_steps() {
    if ((YABAI_INSTALLED == 0 && SKHD_INSTALLED == 0 && HAMMERSPOON_INSTALLED == 0)); then
        return
    fi

    log "macOS manual steps"
    printf "System Settings > Privacy & Security > Accessibility:\n"
    printf "  - Enable skhd\n"
    printf "  - Enable Hammerspoon\n"
    printf "  - Enable yabai if macOS prompts for it\n"
    printf "System Settings > Privacy & Security > Screen & System Audio Recording:\n"
    printf "  - Enable Hammerspoon if stackline or automation features need it\n"
    printf "Open Hammerspoon once and allow any permission prompts.\n"
    printf "If you want full yabai scripting-addition features, complete the sudoers/SIP steps from:\n"
    printf "  https://github.com/asmvik/yabai/wiki/Installing-yabai-(latest-release)#configure-scripting-addition\n"
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
        print_macos_manual_steps
    else
        log "Skipping macOS GUI apps"
    fi

    if ((${#PASSTHROUGH_ARGS[@]} > 0)); then
        exec "$REPO_ROOT/scripts/dev-unix.sh" --target mac-personal "${PASSTHROUGH_ARGS[@]}"
    fi

    exec "$REPO_ROOT/scripts/dev-unix.sh" --target mac-personal
}

main
