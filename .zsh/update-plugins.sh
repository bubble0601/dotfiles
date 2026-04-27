#!/usr/bin/env zsh
# zsh プラグインを一括 install / update する
# 使い方: zsh ~/dotfiles/.zsh/update-plugins.sh

set -e

PLUGINS_DIR="${0:A:h}/plugins"
mkdir -p "$PLUGINS_DIR"

PLUGINS=(
    "https://github.com/zsh-users/zsh-autosuggestions"
    "https://github.com/olets/zsh-abbr"
    "https://github.com/zsh-users/zsh-syntax-highlighting"
    "https://github.com/zsh-users/zsh-history-substring-search"
)

for repo in "${PLUGINS[@]}"; do
    name="${repo:t}"
    dir="$PLUGINS_DIR/$name"
    if [[ -d "$dir/.git" ]]; then
        echo "→ updating $name"
        git -C "$dir" pull --ff-only
        git -C "$dir" submodule update --init --recursive
    else
        echo "→ cloning $name"
        git clone --depth 1 --recurse-submodules "$repo" "$dir"
    fi
done

echo
echo "✓ done. start a new shell or run 'source ~/.zshrc' to apply."
