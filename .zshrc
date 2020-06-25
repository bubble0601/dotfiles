###########################################################################
# 環境変数
export LANG=ja_JP.UTF-8

###########################################################################
# 補完
autoload -Uz compinit
compinit

# 補完で小文字でも大文字にマッチさせる
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

# ../ の後は今いるディレクトリを補完しない
zstyle ':completion:*' ignore-parents parent pwd ..

# sudo の後ろでコマンド名を補完する
zstyle ':completion:*:sudo:*' command-path /usr/local/sbin /usr/local/bin \
                   /usr/sbin /usr/bin /sbin /bin /usr/X11R6/bin

# ps コマンドのプロセス名補完
zstyle ':completion:*:processes' command 'ps x -o pid,s,args'

# git addが重いので普通にファイル全て表示(addされているか全て確認しているため)
__git_files() { _files }


# 色を使用出来るようにする
autoload -Uz colors
colors

export LSCOLORS="fxfxcxdxbxfgfdabagacad"

###########################################################################
# エイリアス
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

# sudo の後のコマンドでエイリアスを有効にする
alias sudo='sudo '

# グローバルエイリアス
alias -g  L='| less'
alias -g  G='| grep'

alias where='command -v'


alias vzrc="vim ~/.zshrc"
alias szrc="source ~/.zshrc"
alias gca="git commit -a -m"
alias psg="ps aux | grep"
function gpr(){
    grep "$1" -rn ./*
}

###########################################################################
# ヒストリ
HISFILE=~/.zsh_history
HISTSIZE=100000
SAVEHIST=100000

# プロンプト
#PROMPT="%/%% "
#PROMPT2="%_%% "
#SPROMPT="%r is correct? [n,y,a,e]: "

case ${UID} in
0)
    RPROMPT="%B%{[31m%}%/#%{[m%}%b "
    RPROMPT2="%B%{[31m%}%_#%{[m%}%b "
    SPROMPT="%B%{[31m%}%r is correct? [n,y,a,e]:%{[m%}%b "
    [ -n "${REMOTEHOST}${SSH_CONNECTION}" ] &&
        PROMPT="%{[37m%}${HOST%%.*} ${PROMPT}"
    ;;
*)
    RPROMPT="%{[31m%}%/%%%{[m%} "
    RPROMPT2="%{[31m%}%_%%%{[m%} "
    SPROMPT="%{[31m%}%r is correct? [n,y,a,e]:%{[m%} "
    [ -n "${REMOTEHOST}${SSH_CONNECTION}" ] &&
        PROMPT="%{[37m%}${HOST%%.*} ${PROMPT}"
    ;;
esac

###########################################################################
# オプション
# 日本語ファイル名を表示
setopt print_eight_bit

# beep無効
setopt no_beep

# フローコントロール無効
setopt no_flow_control

# Ctrl+Dでzshを終了しない
setopt ignore_eof

# '#' 以降をコメントとして扱う
setopt interactive_comments

# ディレクトリ名だけでcdする
setopt auto_cd

# cdでpushd
setopt auto_pushd
# 重複させない
setopt pushd_ignore_dups

# 同時に起動したzshの間でヒストリを共有する
setopt share_history

# 同じコマンドをヒストリに残さない
setopt hist_ignore_all_dups

# スペースから始まるコマンド行はヒストリに残さない
# setopt hist_ignore_space

# ヒストリに保存するときに余分なスペースを削除する
setopt hist_reduce_blanks

# 高機能なワイルドカード展開を使用する
setopt extended_glob

# コマンドもしかして
setopt correct

# 候補を詰めて表示
setopt list_packed

# 先方予測 便利なときは便利だが編集しにくかったり重かったりする
# autoload predict-on
# predict-on

# 履歴検索
autoload history-search-end
zle -N history-beginning-search-backward-end history-search-end
zle -N history-beginning-search-forward-end history-search-end
bindkey "^P" history-beginning-search-backward-end
bindkey "^N" history-beginning-search-forward-end

###########################################################################

load_if_exists () {
    if [ -f $1 ]; then
        source $1
    fi
}
load_if_exists "$HOME/.zshrc_local"
