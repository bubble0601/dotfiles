HISTFILE=~/.zsh_history
HISTSIZE=100000
SAVEHIST=100000

# !! や !$ で展開した結果を即実行せず編集可能な状態にする (誤実行防止)
setopt hist_verify

# 先頭がスペースのコマンドは履歴に残さない (一時的な秘匿用)
setopt hist_ignore_space

# 実行時刻と所要時間も記録
setopt extended_history

# ファイル保存時に重複を削除
setopt hist_save_no_dups

# 上限到達時、重複から先に消す
setopt hist_expire_dups_first
