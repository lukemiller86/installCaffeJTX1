#!/bin/sh
# Script for installing Caffe support on Jetson TX1 Development Kits
# Using Caffe fork from NVIDIA with FP16 support.
# 31-01-17
# MIT License
# Install and compile Caffe on NVIDIA Jetson TX1 Development Kit
# Prerequisites (which can be installed with JetPack 2):
# L4T 24.2 (Ubuntu 16.04)
# OpenCV4Tegra
# CUDA 8.0
# cuDNN v5.1
sudo add-apt-repository universe
sudo apt-get update -y
/bin/echo -e "\e[1;32mLoading Caffe Dependencies.\e[0m"
sudo apt-get install cmake -y
# General Dependencies
sudo apt-get install libprotobuf-dev libleveldb-dev libsnappy-dev \
libhdf5-serial-dev protobuf-compiler -y
sudo apt-get install --no-install-recommends libboost-all-dev -y
# BLAS
sudo apt-get install libatlas-base-dev -y
# Remaining Dependencies
sudo apt-get install libgflags-dev libgoogle-glog-dev liblmdb-dev -y
sudo apt-get install python-dev python-numpy -y
# The Snappy package needs a symbolic link created for Caffe to link correctly
sudo ln -s /usr/lib/libsnappy.so.1 /usr/lib/libsnappy.so
sudo ldconfig

sudo usermod -a -G video $USER
/bin/echo -e "\e[1;32mCloning Caffe into the home directory\e[0m"
# Place caffe in the home directory
cd $HOME
# Git clone Caffe
git clone -b experimental/fp16 https://github.com/NVIDIA/caffe
cd caffe 
cp Makefile.config.example Makefile.config
# Regen the makefile; On 16.04, aarch64 has issues with a static cuda runtime
cmake -DCUDA_USE_STATIC_CUDA_RUNTIME=OFF
# Include the hdf5 directory for the includes; 16.04 has issues for some reason
echo "INCLUDE_DIRS += /usr/include/hdf5/serial/" >> Makefile.config
# Enable FP16
sed -i 's/# NATIVE_FP16/NATIVE_FP16/g' Makefile.config
# Enable cuDNN
sed -i 's/# USE_CUDNN/USE_CUDNN/g' Makefile.config
# Enable compute_53/sm_53
sed -i 's/-gencode arch=compute_50,code=compute_50/-gencode arch=compute_53,code=sm_53 -gencode arch=compute_53,code=compute_53/g' Makefile.config

/bin/echo -e "\e[1;32mCompiling Caffe\e[0m"
make -j4 all
# Run the tests to make sure everything works
/bin/echo -e "\e[1;32mRunning Caffe Tests\e[0m"
make -j4 runtest
# The following is a quick timing test ...
# tools/caffe time --model=models/bvlc_alexnet/deploy.prototxt --gpu=0

# Could be needed?
#sudo apt-get install libboost-thread1.55-dev libhdf5-dev libatlas-dev libatlas3-base