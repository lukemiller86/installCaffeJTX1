#!/bin/sh
# Script for installing Caffe & Faster R-CNN with cuDNN support on Jetson TX1 Development Kit
# 01/02/16 - Luke Miller
# MIT License
# Install and compile Caffe on NVIDIA Jetson TX1 Development Kit
# Prerequisites (which can be installed with JetPack 2):
# L4T 24.2 (Ubuntu 16.04)
# OpenCV4Tegra
# CUDA 8.0
# cuDNN v5.1
# Tested with last Github Caffe commit: 80f44100e19fd371ff55beb3ec2ad5919fb6ac43

# Install some dependencies
apt-get update && apt-get install -y \
	bc \
	build-essential \
	#cmake \    ######
	curl \
	ffmpeg \
	g++ \
	gfortran \
		git \
		#libatlas-base-dev \ ######
		libdc1394-22 \
		libdc1394-22-dev \
		libffi-dev \
		libfreetype6-dev \
		libgtk-3-dev \
		libhdf5-dev \
		libjasper-dev \
		libjpeg-dev \
		liblcms2-dev \
		libopenblas-dev \
		liblapack-dev \
#		libopenjpeg2 \
		libavcodec-dev \
		libavformat-dev \
		libswscale-dev \
		libxine2-dev \
		libgstreamer0.10-dev \
		libgstreamer-plugins-base0.10-dev \
		libv4l-dev \
		libtbb-dev \
#		libfaac-dev \
		libmp3lame-dev \
		libopencore-amrnb-dev \
		libopencore-amrwb-dev \
		libtheora-dev \
		libvorbis-dev \
		libxvidcore-dev \
		v4l-utils \
		libpng12-dev \
		libssl-dev \
		libtiff5-dev \
		libwebp-dev \
		libzmq3-dev \
		nano \
		pkg-config \
		# python-dev \
		qtbase5-dev \
		software-properties-common \
		unzip \
		vim \
		wget \
		zlib1g-dev \
		&& \
	apt-get clean && \
	apt-get autoremove && \
	rm -rf /var/lib/apt/lists/* && \
# Link BLAS library to use OpenBLAS using the alternatives mechanism (https://www.scipy.org/scipylib/building/linux.html#debian-ubuntu)
	update-alternatives --set libblas.so.3 /usr/lib/openblas-base/libblas.so.3

# Install pip
RUN curl -O https://bootstrap.pypa.io/get-pip.py && \
	python get-pip.py && \
	rm get-pip.py

# Add SNI support to Python
RUN pip --no-cache-dir install \
		pyopenssl \
		ndg-httpsclient \
		pyasn1

# Install useful Python packages using apt-get to avoid version incompatibilities with Tensorflow binary
# especially numpy, scipy, skimage and sklearn (see https://github.com/tensorflow/tensorflow/issues/2034)
RUN apt-get update && apt-get install -y \
		# python-numpy \
		python-scipy \
		python-nose \
		python-h5py \
		python-skimage \
		python-matplotlib \
		python-pandas \
		python-sklearn \
		python-sympy \
		&& \
	apt-get clean && \
	apt-get autoremove && \
	rm -rf /var/lib/apt/lists/*

# Install other useful Python packages using pip
RUN pip --no-cache-dir install --upgrade ipython && \
	pip --no-cache-dir install \
		Cython \
		easydict \
		ipykernel \
		jupyter \
		path.py \
		Pillow \
		protobuf \
		pygments \
		PyYAML \
		six \
		sphinx \
		wheel \
		zmq \
		&& \
	python -m ipykernel.kernelspec

# Install dependencies for Caffe
RUN apt-get update && apt-get install -y \
		#libboost-all-dev \
		#libgflags-dev \
		#libgoogle-glog-dev \
		#libhdf5-serial-dev \
		#libleveldb-dev \
		#liblmdb-dev \
		libopencv-dev \
		#libprotobuf-dev \
		#libsnappy-dev \
		#protobuf-compiler \
		&& \
	apt-get clean && \
	apt-get autoremove && \
	rm -rf /var/lib/apt/lists/*

# Build OpenCV
RUN git clone https://github.com/opencv/opencv.git /root/opencv
RUN mkdir /root/opencv/build
RUN cd /root/opencv/build/ && cmake -D CMAKE_BUILD_TYPE=RELEASE -D CMAKE_INSTALL_PREFIX=/usr/local -D WITH_TBB=ON -D WITH_V4L=ON -D WITH_QT=ON -D WITH_OPENGL=ON -D WITH_CUBLAS=ON -DCUDA_NVCC_FLAGS="-D_FORCE_INLINES" ..
RUN cd /root/opencv/build/ && make -j $(($(nproc) + 1))

# Install OpenCV
RUN cd /root/opencv/build/ && make install
RUN echo "/usr/local/lib" >> /etc/ld.so.conf.d/opencv.conf && ldconfig






# Install Caffe
# Set up Caffe environment variables
ENV CAFFE_ROOT=/root/faster_rcnn/caffe-fast-rcnn
ENV PYCAFFE_ROOT=$CAFFE_ROOT/python
ENV PYTHONPATH=$PYCAFFE_ROOT:$PYTHONPATH \
	PATH=$CAFFE_ROOT/build/tools:$PYCAFFE_ROOT:$PATH

RUN echo "$CAFFE_ROOT/build/lib" >> /etc/ld.so.conf.d/caffe.conf && ldconfig





# Build Cython modules
RUN cd /root/faster_rcnn/lib/ && make

# Download pre-computed Faster R-CNN detectors
RUN cd /root/faster_rcnn/ && ./data/scripts/fetch_faster_rcnn_models.sh

# Set up notebook config
COPY jupyter_notebook_config.py /root/.jupyter/

# Jupyter has issues with being run directly: https://github.com/ipython/ipython/issues/7062
COPY run_jupyter.sh /root/