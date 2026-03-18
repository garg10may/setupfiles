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
