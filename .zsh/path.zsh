# PATH の重複エントリを自動排除
typeset -U path PATH

export PATH="$HOME/.anyenv/bin:$PATH"
eval "$(anyenv init -)"

eval "$(fnm env --use-on-cd)"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# Claude, etc
export PATH="$HOME/.local/bin:$PATH"

# zoxide (z コマンドで頻度ベースのディレクトリジャンプ、cd は据置)
command -v zoxide >/dev/null && eval "$(zoxide init zsh)"
