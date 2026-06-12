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
alias -g C='| pbcopy'

gpr() {
    grep "$1" -rn ./*
}

difit() {
  local difit_bin="$HOME/Documents/playground/difit/dist/cli/index.js"
  local cmd
  if [[ -f "$difit_bin" ]]; then
    cmd=(node "$difit_bin")
  else
    cmd=(bunx difit)
  fi
  if [[ $# -eq 0 ]]; then
    "${cmd[@]}" staged
  else
    "${cmd[@]}" "$@"
  fi
}

fbr() {
  local branches branch
  branches=$(git --no-pager branch -vv) &&
  branch=$(echo "$branches" | fzf +m) &&
  git checkout $(echo "$branch" | sed 's/^\*\? *//' | awk '{print $1}')
}

fbrr() {
  local branches branch
  branches=$(git branch --all | grep -v HEAD) &&
  branch=$(echo "$branches" |
           fzf --height=$(( 2 + $(wc -l <<< "$branches") )) +m) &&
  git checkout $(echo "$branch" | sed "s/.* //" | sed "s#remotes/[^/]*/##")
}
