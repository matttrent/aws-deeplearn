#!/bin/bash

cd $HOME

git clone https://github.com/matttrent/dotfiles.git
cd dotfiles
bash install.sh
bash aws-set-zsh.sh