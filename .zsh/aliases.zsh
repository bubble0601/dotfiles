alias ls='ls -G'
alias la='ls -a'
alias ll='ls -l'
alias lal='ls -al'
alias lla='ls -al'
alias lf='ls -F'

alias vi="nvim"

# sudo の後のコマンドでエイリアスを有効にする
alias sudo='sudo '

# グローバルエイリアス
alias -g L='| less'
alias -g G='| grep'

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
