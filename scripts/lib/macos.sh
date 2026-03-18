#!/usr/bin/env bash

load_homebrew_env() {
    if [[ -x /opt/homebrew/bin/brew ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -x /usr/local/bin/brew ]]; then
        eval "$(/usr/local/bin/brew shellenv)"
    fi
}

ensure_homebrew() {
    if command -v brew >/dev/null 2>&1; then
        load_homebrew_env
        return
    fi

    log "Homebrew not found. Installing Homebrew"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    load_homebrew_env
}

ensure_brew_tap() {
    local tap="$1"
    BREW_ACTION_TAKEN=0

    if brew tap | grep -qx "$tap"; then
        return
    fi

    brew tap "$tap"
    BREW_ACTION_TAKEN=1
}

ensure_brew_formula() {
    local formula="$1"
    BREW_ACTION_TAKEN=0

    if brew list --formula "$formula" >/dev/null 2>&1; then
        return
    fi

    brew install "$formula"
    BREW_ACTION_TAKEN=1
}

ensure_brew_cask() {
    local cask="$1"
    local app_path="${2:-}"
    BREW_ACTION_TAKEN=0

    if brew list --cask "$cask" >/dev/null 2>&1; then
        if [[ -n "$app_path" && ! -e "$app_path" ]]; then
            warn "${cask} is tracked by Homebrew but ${app_path} is missing; reinstalling"
            brew reinstall --cask "$cask"
            BREW_ACTION_TAKEN=1
        fi
        return
    fi

    if [[ -n "$app_path" && -e "$app_path" ]]; then
        return
    fi

    brew install --cask "$cask"
    BREW_ACTION_TAKEN=1
}
