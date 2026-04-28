#!/bin/bash
# ターミナルキーバインド一覧 (readline / zsh / bash 共通)

B='\033[1m'
R='\033[0m'
H='\033[38;5;110m'
S='\033[38;5;147m'
K='\033[38;5;179m'
D='\033[38;5;189m'
Q='\033[38;5;108m'

printf "${B}${H}"
printf '╔══════════════════════════════════════╗\n'
printf '║        Terminal Key Bindings         ║\n'
printf '╚══════════════════════════════════════╝\n'
printf "${R}\n"

section() { printf "${B}${S}  [%s]${R}\n" "$1"; }
key()     { printf "  ${K}%-16s${R}${D}%s${R}\n" "$1" "$2"; }
gap()     { printf "\n"; }

section "移動"
key "C-f / C-b"    "1文字 前 / 後"
key "M-f / M-b"    "1単語 前 / 後"
key "C-a / C-e"    "行頭 / 行末"
key "C-n / C-p"    "1行 下 / 上"
gap

section "編集"
key "M-d"          "カーソル以降の1単語を削除"
key "C-w"          "カーソル前の1単語を削除"
key "C-k"          "カーソルから行末まで削除"
key "C-u"          "カーソルから行頭まで削除"
key "C-y"          "貼り付け (直前の削除内容)"
gap

section "制御"
key "C-l"          "画面をクリア"
key "C-r"          "コマンド履歴を後方検索"
gap

section "タブ"
key "Cmd+Shift+←"  "タブを左に移動"
key "Cmd+Shift+→"  "タブを右に移動"
gap

printf "  ${Q}[q] で閉じる${R}\n\n"
