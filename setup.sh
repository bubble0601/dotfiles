TARGETS=(.vimrc .vim .zshrc .latexmkrc)

for tgt in ${TARGETS[@]}
do
    ln -fnsv $HOME/dotfiles/$tgt $HOME/$tgt
done
