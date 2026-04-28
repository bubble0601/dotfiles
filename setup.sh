TARGETS=(.vimrc .vim .latexmkrc)

# vim undo ディレクトリを作成
mkdir -p $HOME/.vim/undo

for tgt in ${TARGETS[@]}
do
    ln -fnsv $HOME/dotfiles/$tgt $HOME/$tgt
done

# ~/.zshrc は machine-local な実ファイルにする (dotfiles/.zshrc を source する)
# 既存ファイルがあれば触らない
if [ ! -e $HOME/.zshrc ]; then
    echo 'source ~/dotfiles/.zshrc' > $HOME/.zshrc
    echo "created $HOME/.zshrc (sources ~/dotfiles/.zshrc)"
fi

# zsh プラグインを install / update (idempotent)
zsh $HOME/dotfiles/.zsh/update-plugins.sh

# .config 以下のディレクトリは親を作成してからリンク
CONFIG_TARGETS=(.config/wezterm .config/nvim)

mkdir -p $HOME/.config
for tgt in ${CONFIG_TARGETS[@]}
do
    ln -fnsv $HOME/dotfiles/$tgt $HOME/$tgt
done

# ~/.claude 以下も親を作成してから個別ファイル/ディレクトリで symlink
# (~/.claude には会話履歴等のランタイム生成物も含むため、ディレクトリ全体は symlink しない)
CLAUDE_TARGETS=(.claude/settings.json .claude/skills .claude/statusline.sh .claude/statusline-wrapper.sh)

mkdir -p $HOME/.claude
for tgt in ${CLAUDE_TARGETS[@]}
do
    ln -fnsv $HOME/dotfiles/$tgt $HOME/$tgt
done

# ~/.claude/CLAUDE.md は machine-local な実ファイル (dotfiles の CLAUDE.md を @ で include)
if [ ! -e $HOME/.claude/CLAUDE.md ]; then
    echo '@~/dotfiles/.claude/CLAUDE.md' > $HOME/.claude/CLAUDE.md
    echo "created $HOME/.claude/CLAUDE.md (includes ~/dotfiles/.claude/CLAUDE.md)"
fi

# ~/.codex 以下も同様に個別 symlink (auth.json, history, sessions 等のランタイム生成物は除外)
CODEX_TARGETS=(.codex/config.toml .codex/AGENTS.md .codex/agents .codex/rules)

mkdir -p $HOME/.codex
for tgt in ${CODEX_TARGETS[@]}
do
    ln -fnsv $HOME/dotfiles/$tgt $HOME/$tgt
done

# ~/.gitconfig に dotfiles の alias 定義を include (未設定時のみ)
if ! git config --global --get-all include.path 2>/dev/null | grep -q 'dotfiles/\.gitconfig_aliases'; then
    git config --global --add include.path '~/dotfiles/.gitconfig_aliases'
    echo "added include.path=~/dotfiles/.gitconfig_aliases to ~/.gitconfig"
fi
