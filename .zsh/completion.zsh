autoload -Uz compinit
compinit

# Tab で候補メニュー表示、ハイライトで選択可能
zstyle ':completion:*' menu select

# 補完候補に LS_COLORS の色付け
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}

# 小文字でも大文字にマッチさせる
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

# ブラケットペースト
autoload -Uz bracketed-paste-magic
zle -N bracketed-paste bracketed-paste-magic
zstyle :bracketed-paste-magic paste-init backward-extend-paste
