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

# ヒストリに保存するときに余分なスペースを削除する
setopt hist_reduce_blanks

# 高機能なワイルドカード展開を使用する
setopt extended_glob

# --prefix=~/foo の = の右辺もチルダ展開
setopt magic_equal_subst

# file1, file2, ..., file10 を数字順にソート
setopt numeric_glob_sort

# 候補を詰めて表示
setopt list_packed

# 履歴検索
autoload history-search-end
zle -N history-beginning-search-backward-end history-search-end
zle -N history-beginning-search-forward-end history-search-end
bindkey "^P" history-beginning-search-backward-end
bindkey "^N" history-beginning-search-forward-end
