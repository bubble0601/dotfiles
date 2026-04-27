PLUGINS_DIR="${0:A:h}/plugins"

# fish 風の履歴ベース補完 (グレー表示、→ で採用)
[[ -f "$PLUGINS_DIR/zsh-autosuggestions/zsh-autosuggestions.zsh" ]] \
    && source "$PLUGINS_DIR/zsh-autosuggestions/zsh-autosuggestions.zsh"

# fish 風 abbreviation (スペース/Enter で展開、履歴に展開後が残る)
# 公式: zsh-syntax-highlighting より先に source する必要がある
[[ -f "$PLUGINS_DIR/zsh-abbr/zsh-abbr.zsh" ]] \
    && source "$PLUGINS_DIR/zsh-abbr/zsh-abbr.zsh"

# コマンド入力中の構文ハイライト
# 公式: 他の widget 設定より後で source する必要がある
[[ -f "$PLUGINS_DIR/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]] \
    && source "$PLUGINS_DIR/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"

# ↑/↓ で現在の入力を含む履歴に絞り込み検索
# 公式: zsh-syntax-highlighting より後で source する必要がある
if [[ -f "$PLUGINS_DIR/zsh-history-substring-search/zsh-history-substring-search.zsh" ]]; then
    source "$PLUGINS_DIR/zsh-history-substring-search/zsh-history-substring-search.zsh"
    bindkey '^[[A' history-substring-search-up
    bindkey '^[[B' history-substring-search-down
fi
