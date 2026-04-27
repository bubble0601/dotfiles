# zsh-abbr による abbreviation 定義 (session scope, 起動毎に再宣言)
# session で宣言することで dotfiles 側のみで管理 (user 永続化ファイルは使わない)
# ABBR_QUIETER=1: -f で同名コマンドを上書きする際の起動時通知を抑制
typeset -gi ABBR_QUIETER=1
if (( $+functions[abbr] )); then
    abbr -S -q -f add gs='git status'
    abbr -S -q -f add pn='pnpm'
    abbr -S -q -f add dc='docker compose'
    abbr -S -q -f add nr='npm run'
    abbr -S -q -f add psg='ps aux | grep'
    abbr -S -q -f add szrc='source ~/.zshrc'
    abbr -S -q -f add nv='nvim'
    abbr -S -q -f add where='command -v'
fi
