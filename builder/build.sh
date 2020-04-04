#!/bin/bash

set -euo pipefail

export USER="$(whoami)"
export JAVA_HOME="/usr/lib/jvm/java-8-openjdk-amd64"

OPENCV_BUILD_THREADS="$(nproc)"
OPENCV_BUILD_CONTRIB_ARGS=

echo "Build Android SDK: $OPENCV_BUILD_TARGET_ANDROID"
echo "Build CPP (Shared): $OPENCV_BUILD_TARGET_CPP_SHARED"
echo "Build CPP (Static): $OPENCV_BUILD_TARGET_CPP_STATIC"
echo "Build JS: $OPENCV_BUILD_TARGET_JS"
echo "Build Java: $OPENCV_BUILD_TARGET_JAVA"

wget -q --show-progress --progress=bar:force -O opencv.tar.gz "https://github.com/opencv/opencv/archive/$OPENCV_VERSION.tar.gz"
mkdir -p opencv
tar xf opencv.tar.gz -C opencv --strip-components 1
rm opencv.tar.gz

if [ "$OPENCV_BUILD_CONTRIB" -eq "1" ]; then
    wget -q --show-progress --progress=bar:force -O contrib.tar.gz "https://github.com/opencv/opencv_contrib/archive/$OPENCV_VERSION.tar.gz"
    mkdir -p contrib
    tar xf contrib.tar.gz -C contrib --strip-components 1
    rm contrib.tar.gz
    OPENCV_BUILD_CONTRIB_ARGS="-DOPENCV_EXTRA_MODULES_PATH=../contrib/modules"
fi

if [ "$OPENCV_BUILD_TARGET_CPP_SHARED" -eq "1" ]; then
	mkdir build
	cd build
	cmake $OPENCV_BUILD_CONTRIB_ARGS -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=../out/cpp-shared ../opencv
	make install -j$OPENCV_BUILD_THREADS
fi

if [ "$OPENCV_BUILD_TARGET_CPP_STATIC" -eq "1" ]; then
	mkdir build
	cd build
	cmake $OPENCV_BUILD_CONTRIB_ARGS -DBUILD_SHARED_LIBS=OFF -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=../out/cpp-static ../opencv
	make install -j$OPENCV_BUILD_THREADS
fi
