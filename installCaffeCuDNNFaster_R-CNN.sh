#!/bin/sh
# Script for installing Caffe with cuDNN support on Jetson TX1 Development Kitls
# 9-15-16 JetsonHacks.com
# MIT License
# Install and compile Caffe on NVIDIA Jetson TX1 Development Kit
# Prerequisites (which can be installed with JetPack 2):
# L4T 24.2 (Ubuntu 16.04)
# OpenCV4Tegra
# CUDA 8.0
# cuDNN v5.1
# Tested with last Github Caffe commit: ???
sudo add-apt-repository universe
sudo apt-get update -y
/bin/echo -e "\e[1;32mLoading Caffe Dependencies.\e[0m"
sudo apt-get install git cmake curl -y
# General Dependencies
sudo apt-get install libprotobuf-dev libleveldb-dev libsnappy-dev \
libhdf5-serial-dev protobuf-compiler -y
sudo apt-get install --no-install-recommends libboost-all-dev -y
# BLAS
sudo apt-get install libatlas-base-dev -y
# Remaining Dependencies
sudo apt-get install libgflags-dev libgoogle-glog-dev liblmdb-dev -y
sudo apt-get install python-dev python-numpy -y
# Join 'video' group in Ubuntu.
sudo usermod -a -G video $USER
/bin/echo -e "\e[1;32mCloning Caffe into the home directory\e[0m"

# Install pip
curl -O https://bootstrap.pypa.io/get-pip.py && \
python get-pip.py && \
rm get-pip.py

# Add SNI support to Python
# pip --no-cache-dir install pyopenssl ndg-httpsclient pyasn1

# Install python dependencies
sudo apt-get update && apt-get install python-scipy python-nose python-h5py \
python-skimage python-matplotlib python-pandas python-sklearn python-sympy -y
apt-get clean && apt-get autoremove -y && rm -rf /var/lib/apt/lists/*

pip --no-cache-dir install --upgrade ipython && \
pip --no-cache-dir install Cython easydict ipykernel jupyter path.py \
Pillow protobuf pygments PyYAML six sphinx wheel zmq \
&& python -m ipykernel.kernelspec

# Install python (bindings?) for opencv
sudo apt-get update $$ apt-get install libopencv4tegra-python python-opencv -y

# Place Faster_R-CNN and Caffe in the home directory
cd $HOME
# Git clone Faster R-CNN WITHOUT recursion
git clone https://github.com/rbgirshick/py-faster-rcnn.git faster_rcnn
# Git clone Caffe with Fast R-CNN modification from lukemiller86
git clone https://github.com/lukemiller86/caffe-fast-rcnn.git --branch caffe-update --single-branch faster_rcnn/caffe-fast-rcnn

# cd into Caffe directory and use the TX1 config file
cd faster_rcnn/caffe-fast-rcnn
cp Makefile.config.tx1 Makefile.config
# Enable cuDNN usage
sed -i 's/# USE_CUDNN/USE_CUDNN/g' Makefile.config
# Regen the makefile; On 16.04, aarch64 has issues with a static cuda runtime
cmake -DCUDA_USE_STATIC_CUDA_RUNTIME=OFF
# Include the hdf5 directory for the includes; 16.04 has issues for some reason
echo "INCLUDE_DIRS += /usr/include/hdf5/serial/" >> Makefile.config

# additional LM
echo "LIBRARY_DIRS += /usr/local/share/" >> Makefile.config
# echo "LIBRARY_DIRS += OpenCV/3rdparty/lib/" >> Makefile.config

# Enable support layers written in python
sed -i 's/# WITH_PYTHON_LAYER/WITH_PYTHON_LAYER/g' Makefile.config


#touch ~/.bash_profile
#echo "source ~/.bashrc && source ~/.profile" >> ~.bash_profile

#echo "export CAFFE_ROOT=~/faster_rcnn/caffe-fast-rcnn" >> ~/.bash_profile
#source ~/.bash_profile
#echo "export PYCAFFE_ROOT=$CAFFE_ROOT/python" >> ~/.bash_profile
#source ~/.bash_profile
#echo "export PYTHONPATH=$PYCAFFE_ROOT:$PYTHONPATH" >> ~/.bash_profile
#source ~/.bash_profile
#echo "export PATH=$CAFFE_ROOT/build/tools:$PYCAFFE_ROOT:$PATH" >> ~/.bash_profile
#source ~/.bash_profile

#echo "$CAFFE_ROOT/build/lib" >> /etc/ld.so.conf.d/caffe.conf && ldconfig

/bin/echo -e "\e[1;32mCompiling Caffe\e[0m"
make all -j $(($(nproc) + 1))
make pycaffe

# Rename file in order to run Caffe tests
# mv src/caffe/test/test_smooth_L1_loss_layer.cpp src/caffe/test/test_smooth_L1_loss_layer.cpp.orig
# Run the tests to make sure everything works
# /bin/echo -e "\e[1;32mRunning Caffe Tests\e[0m"
# make runtest -j $(($(nproc) + 1))
# Restore file we moved earlier
# mv src/caffe/test/test_smooth_L1_loss_layer.cpp.orig src/caffe/test/test_smooth_L1_loss_layer.cpp

# Build Cython modules
cd $HOME/faster_rcnn/lib/ && make

# Download pre-computed Faster R-CNN detectors
cd $HOME/faster_rcnn/ && ./data/scripts/fetch_faster_rcnn_models.sh

# The following is a quick timing test ...
# tools/caffe time --model=models/bvlc_alexnet/deploy.prototxt --gpu=0
