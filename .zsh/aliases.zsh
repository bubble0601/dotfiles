alias ls='ls -G'
alias la='ls -a'
alias ll='ls -l'
alias lal='ls -al'
alias lla='ls -al'
alias lf='ls -F'

alias vi="nvim"
alias nv="nvim"

# sudo の後のコマンドでエイリアスを有効にする
alias sudo='sudo '

# グローバルエイリアス
alias -g L='| less'
alias -g G='| grep'

alias where='command -v'

alias szrc="source ~/.zshrc"
alias gs="git status"
alias psg="ps aux | grep"

alias pn="pnpm"
alias dc="docker compose"
alias nr="npm run"

gpr() {
    grep "$1" -rn ./*
}

difit() {
  if [[ $# -eq 0 ]]; then
    bunx difit working
  else
    bunx difit "$@"
  fi
}
