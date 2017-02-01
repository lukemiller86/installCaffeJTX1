#!/bin/sh
export CAFFE_ROOT=$HOME/faster_rcnn/caffe-fast-rcnn
export PYCAFFE_ROOT=$CAFFE_ROOT/python
export PYTHONPATH=$PYCAFFE_ROOT:$PYTHONPATH
export PATH=$CAFFE_ROOT/build/tools:$PYCAFFE_ROOT:$PATH