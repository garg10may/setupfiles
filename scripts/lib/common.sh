#!/usr/bin/env bash

log() {
    printf '\n==> %s\n' "$1"
}

warn() {
    printf 'WARN: %s\n' "$1"
}

info() {
    printf 'INFO: %s\n' "$1"
}

fail() {
    printf 'ERROR: %s\n' "$1" >&2
    exit 1
}

ensure_local_bin() {
    mkdir -p "$HOME/.local/bin" "$HOME/.local/opt"
    export PATH="$HOME/.local/bin:$PATH"
}

copy_file_if_different() {
    local source_path="$1"
    local destination_path="$2"
    local mode="${3:-}"

    mkdir -p "$(dirname "$destination_path")"

    if [[ -e "$destination_path" ]] && cmp -s "$source_path" "$destination_path"; then
        if [[ -n "$mode" ]]; then
            chmod "$mode" "$destination_path"
        fi
        return 1
    fi

    cp "$source_path" "$destination_path"
    if [[ -n "$mode" ]]; then
        chmod "$mode" "$destination_path"
    fi

    return 0
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
