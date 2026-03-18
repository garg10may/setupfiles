# Shared developer shell bootstrap for macOS and WSL Ubuntu.

set -gx PATH "$HOME/.local/bin" $PATH
set -gx PATH "$HOME/.cargo/bin" $PATH
set -gx PATH "/opt/homebrew/bin" $PATH
set -gx PATH "/usr/local/bin" $PATH

# Enable vi-style editing on the fish command line.
set -g fish_key_bindings fish_vi_key_bindings
# Keep multi-key custom bindings responsive without making lone "j" feel laggy.
set -g fish_sequence_key_delay_ms 200

function fish_user_key_bindings
    fish_vi_key_bindings

    # Keep history navigation scoped to the current command prefix.
    bind -M insert up history-prefix-search-backward
    bind -M insert down history-prefix-search-forward
    bind -M default up history-prefix-search-backward
    bind -M default down history-prefix-search-forward

    # Restore fuzzy history search if an fzf binding function is present.
    if type -q fzf_configure_bindings
        fzf_configure_bindings --directory=\cf --git_log=\cg --git_status=\cs --history=\cr --variables=\cv
    else if type -q fzf_history_widget
        bind -M insert ctrl-r fzf_history_widget
        bind -M default ctrl-r fzf_history_widget
    else
        bind -M insert ctrl-r history-pager
        bind -M default ctrl-r history-pager
    end

    # Allow leaving insert mode with "jj" in addition to Escape.
    bind -M insert -m default j,j repaint-mode
end

function fish_mode_prompt
    fish_default_mode_prompt
end

if command -v starship > /dev/null
    starship init fish | source
end

if command -v zoxide > /dev/null
    zoxide init fish | source
end

if command -v direnv > /dev/null
    direnv hook fish | source
end

if command -v fnm > /dev/null
    fnm env --use-on-cd | source
end

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

abbr gs "git status"
abbr ga "git add"
abbr gc "git commit -m"
abbr gp "git push"
abbr gl "git log --oneline --graph --decorate"
abbr gd "git diff"
abbr gco "git checkout"
abbr gsw "git switch"
abbr grs "git restore"
abbr pr "gh pr create"

abbr zj "zellij"
abbr za "zellij attach"

abbr ua "uv add"
abbr us "uv sync"
abbr ur "uv run"
abbr ut "uv tree"
abbr up "uv run pytest"
abbr venv "source .venv/bin/activate.fish"

abbr nd "npm run dev"
abbr nb "npm run build"
abbr ns "npm start"
abbr pd "pnpm dev"
abbr yd "yarn dev"

abbr dcu "docker compose up"
abbr dcd "docker compose down"
abbr k "kubectl"

abbr .. "cd .."
abbr ... "cd ../.."
abbr h "history"
abbr cl "clear"
abbr ports "lsof -i -P -n | grep LISTEN"

abbr nv "nvim"
abbr nvc "cd ~/.config/nvim && nvim"
