alias ls='ls -G'
alias la='ls -a'
alias ll='ls -l'
alias lal='ls -al'
alias lla='ls -al'
alias lf='ls -F'

alias rmi='rm -i'
alias cpi='cp -i'
alias mvi='mv -i'

alias mkdir='mkdir -p'

alias vi="vim"
alias nv="nvim"

# sudo の後のコマンドでエイリアスを有効にする
alias sudo='sudo '

# グローバルエイリアス
alias -g L='| less'
alias -g G='| grep'

alias where='command -v'

alias vzrc="vim ~/.zshrc"
alias szrc="source ~/.zshrc"
alias gca="git commit -a -m"
alias psg="ps aux | grep"

function gpr() {
    grep "$1" -rn ./*
}

difit() {
  if [[ $# -eq 0 ]]; then
    bunx difit working
  else
    bunx difit "$@"
  fi
}
