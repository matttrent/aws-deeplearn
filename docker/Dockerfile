FROM nvidia/cuda:8.0-cudnn6-devel-ubuntu16.04

LABEL maintainer="Matthew trentacoste <web+git@matttrent.com>"

# Config variables
ARG anaconda_base="Miniconda3-latest"
ARG anaconda_wget_url="miniconda"
# ARG anaconda_base="Anaconda3-latest"
# ARG anaconda_wget_url="archive"
ARG anaconda_name="anaconda"

ARG cudnn_version="6.0"

# Install some dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential curl pkg-config rsync software-properties-common unzip \
    && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN curl "https://repo.continuum.io/$anaconda_wget_url/${anaconda_base}-Linux-x86_64.sh" \
    --output "${anaconda_base}-Linux-x86_64.sh" --silent\
    && \
    bash "${anaconda_base}-Linux-x86_64.sh" -b -p /${anaconda_name} \
    && \
    rm -rf "${anaconda_base}-Linux-x86_64.sh"

ENV PATH "/anaconda/bin:$PATH"

# Upgrade, install 3.5, and conda other channel packages
RUN conda upgrade -y --all \
    && \
    conda install -y -n root python=3.5 \
    && \
    conda install -y -n root conda-build anaconda-client

# Install base pydata stack
RUN conda install -y -n root \
    bcolz ipython scipy numpy pandas scikit-learn h5py \
    matplotlib seaborn jupyter notebook

# Install deep learning libs
RUN conda install -y -n root tensorflow-gpu \
    && \
    conda install -y -n root -c soumith pytorch torchvision \
    && \
    pip install keras
    
# For CUDA profiling, TensorFlow requires CUPTI.
ENV LD_LIBRARY_PATH /usr/local/cuda/extras/CUPTI/lib64:$LD_LIBRARY_PATH

# Jupyter has issues with being run directly:
#   https://github.com/ipython/ipython/issues/7062
# We just add a little wrapper script.
COPY run_jupyter.sh /

# TensorBoard
EXPOSE 6006
# IPython
EXPOSE 8888
