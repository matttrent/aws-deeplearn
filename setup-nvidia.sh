#!/bin/bash

####################################################################################
## deep learning setup script                                                     ##
## Matthew Trentacoste                                                            ##
## web@matttrent.com                                                              ##
## GitHub location: https://github.com/matttrent/aws-deeplearn                    ##
## Date updated: 2017-06-13                                                       ##
####################################################################################

# Default shell config file--works with bash and zsh
shellrc=".zshrc"

# Choose Anaconda (full distribution) or Miniconda (only install selected packages)
# anaconda_python_version="Anaconda3-latest"
anaconda_python_version="Miniconda3-latest"

nvidia_cuda_version="8.0.61"
cudnn_version="6.0"

############################# END USER SETTINGS #############################

# BASH prompt colors
BLUE='\033[1;34m'
RED='\033[1;31m'
NC='\033[0m'

echo ""
echo -e $BLUE"############################################################################"$NC
echo -e $BLUE"#                     Compatible with Ubuntu 16.04                         #"$NC
echo -e $BLUE"############################################################################"$NC
echo ""
sleep 2

# echo ""
# echo -e $BLUE"Using: anaconda_python_version       = $anaconda_python_version"$NC
# if [[ $python_only == "false" ]]; then
# 	echo -e $BLUE"       nvidia_cuda_version           = $nvidia_cuda_version"$NC
# fi
# echo -e $BLUE"       cudnn_version                 = $cudnn_version"$NC
# echo ""
# sleep 2

# Ensure system is updated and has my toolkit
sudo apt-get update


# Install the CUDA repository
wget "http://developer.download.nvidia.com/compute/cuda/repos/ubuntu1604/x86_64/cuda-repo-ubuntu1604_${nvidia_cuda_version}-1_amd64.deb" \
        -O "cuda-repo-ubuntu1604_${nvidia_cuda_version}_amd64.deb"
sudo dpkg -i cuda-repo-ubuntu1604_${nvidia_cuda_version}_amd64.deb

# Download and install GPU drivers
sudo apt-get -y install cuda-8-0
sudo modprobe nvidia
nvidia-smi
# echo "export PATH=\"/usr/local/cuda/bin:\$PATH\"" >> $HOME/$shellrc
# export PATH="/usr/local/cuda/bin:$PATH"

# sudo ln -s -f /usr/local/cuda-8.0/targets/x86_64-linux/include/* /usr/local/cuda/include/

# optimize nvidia settings, turn off adaptive clock rate, set to max
# sudo nvidia-smi -pm 1
# sudo nvidia-smi --auto-boost-default=0
# sudo nvidia-smi -ac 2505,875
