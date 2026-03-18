# Shared developer shell bootstrap for macOS and WSL Ubuntu.

set -gx PATH "$HOME/.local/bin" $PATH
set -gx PATH "$HOME/.cargo/bin" $PATH
set -gx PATH "/opt/homebrew/bin" $PATH
set -gx PATH "/usr/local/bin" $PATH

if command -v starship > /dev/null
    starship init fish | source
end

if command -v zoxide > /dev/null
    zoxide init fish | source
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
abbr pr "gh pr create"

abbr zj "zellij"
abbr za "zellij attach"

abbr ua "uv add"
abbr us "uv sync"
abbr ur "uv run"
abbr ut "uv tree"
abbr venv "source .venv/bin/activate.fish"

abbr nd "npm run dev"
abbr nb "npm run build"
abbr ns "npm start"
abbr pd "pnpm dev"
abbr yd "yarn dev"

abbr .. "cd .."
abbr ... "cd ../.."
abbr h "history"
abbr cl "clear"
abbr ports "lsof -i -P -n | grep LISTEN"

abbr nv "nvim"
abbr nvc "cd ~/.config/nvim && nvim"
