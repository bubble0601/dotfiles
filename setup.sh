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

# .config 以下のディレクトリは親を作成してからリンク
CONFIG_TARGETS=(.config/wezterm .config/nvim)

mkdir -p $HOME/.config
for tgt in ${CONFIG_TARGETS[@]}
do
    ln -fnsv $HOME/dotfiles/$tgt $HOME/$tgt
done

# ~/.gitconfig に dotfiles の alias 定義を include (未設定時のみ)
if ! git config --global --get-all include.path 2>/dev/null | grep -q 'dotfiles/\.gitconfig_aliases'; then
    git config --global --add include.path '~/dotfiles/.gitconfig_aliases'
    echo "added include.path=~/dotfiles/.gitconfig_aliases to ~/.gitconfig"
fi
