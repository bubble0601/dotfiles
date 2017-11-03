#!bin/bash

TARGETS=(.vim .vimrc .zshrc .bash_profile .latexmkrc private)

for tgt in ${TARGETS[@]}
do
    ln -fnsv $HOME/dotfiles/$tgt $HOME/$tgt
done
