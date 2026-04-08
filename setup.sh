TARGETS=(.vimrc .vim .zshrc .zsh .latexmkrc)

# vim undo ディレクトリを作成
mkdir -p $HOME/.vim/undo

for tgt in ${TARGETS[@]}
do
    ln -fnsv $HOME/dotfiles/$tgt $HOME/$tgt
done

# .config 以下のディレクトリは親を作成してからリンク
CONFIG_TARGETS=(.config/wezterm .config/nvim)

mkdir -p $HOME/.config
for tgt in ${CONFIG_TARGETS[@]}
do
    ln -fnsv $HOME/dotfiles/$tgt $HOME/$tgt
done
