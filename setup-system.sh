#!/bin/bash

sudo apt-get update

if [ ! -e $HOME/dotfiles ]; then
    cd $HOME
    git clone https://github.com/matttrent/dotfiles.git
    cd dotfiles
    bash install.sh
    echo "installed dotfiles"
fi

if [[ ! $SHELL =~ 'zsh' ]]; then
    sudo apt-get -y install zsh
    sudo chsh -s $(which zsh) ubuntu
    echo "shell changed to zsh"
fi

cd $HOME
