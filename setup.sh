#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

is_wsl() {
    [[ -n "${WSL_DISTRO_NAME:-}" ]] || grep -qiE '(microsoft|wsl)' /proc/version 2>/dev/null
}

case "$(uname -s)" in
    Darwin)
        exec "$REPO_ROOT/bootstrap-mac.sh" "$@"
        ;;
    Linux)
        if is_wsl; then
            exec "$REPO_ROOT/scripts/dev-unix.sh" --target wsl-ubuntu "$@"
        fi
        printf 'This repo now targets macOS hosts and Windows hosts with WSL Ubuntu.\n' >&2
        printf 'Use bootstrap-mac.sh on macOS or bootstrap-windows.ps1 on Windows.\n' >&2
        exit 1
        ;;
    *)
        printf 'Use bootstrap-windows.ps1 on Windows or bootstrap-mac.sh on macOS.\n' >&2
        exit 1
        ;;
esac
