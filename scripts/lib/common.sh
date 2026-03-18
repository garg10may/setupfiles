#!/usr/bin/env bash

log() {
    printf '\n==> %s\n' "$1"
}

warn() {
    printf 'WARN: %s\n' "$1"
}

fail() {
    printf 'ERROR: %s\n' "$1" >&2
    exit 1
}

ensure_local_bin() {
    mkdir -p "$HOME/.local/bin" "$HOME/.local/opt"
    export PATH="$HOME/.local/bin:$PATH"
}

is_wsl() {
    [[ -n "${WSL_DISTRO_NAME:-}" ]] || grep -qiE '(microsoft|wsl)' /proc/version 2>/dev/null
}

detect_arch() {
    case "$(uname -m)" in
        x86_64|amd64)
            ARCH="amd64"
            GH_ARCHIVE_SUFFIX="linux_amd64"
            ;;
        arm64|aarch64)
            ARCH="arm64"
            GH_ARCHIVE_SUFFIX="linux_arm64"
            ;;
        *)
            fail "Unsupported CPU architecture: $(uname -m)"
            ;;
    esac
}
