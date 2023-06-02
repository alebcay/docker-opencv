# Stage 1: Build environment
FROM trzeci/emscripten:version as builder

# Set specific versions if necessary
ARG OPENCV_VERSION=4.5.3

ENV \
    CCACHE_SIZE=50G \
    CCACHE_DIR=/srv/ccache \
    USE_CCACHE=1 \
    CCACHE_COMPRESS=1 \
    PATH=$PATH:/usr/local/bin/

# Update package sources and install dependencies
RUN sed -i 's/main$/main contrib non-free/' /etc/apt/sources.list \
    && export DEBIAN_FRONTEND=noninteractive \
    && apt-get update -y \
    && apt-get install -y --no-install-recommends \
        build-essential \
        cmake \
        default-jdk \
        git \
        libgtk2.0-dev \
        pkg-config \
        libatlas-base-dev \
        libavcodec-dev \
        libavformat-dev \
        libavresample-dev \
        libceres-dev \
        libdc1394-22-dev \
        libeigen3-dev \
        libgflags-dev \
        libgoogle-glog-dev \
        libhdf5-dev \
        libjpeg-dev \
        liblapack-dev \
        liblapacke-dev \
        libogre-1.9-dev \
        libopenblas-dev \
        libpng-dev \
        libswscale-dev \
        libtbb2 \
        libtbb-dev \
        libtiff-dev \
        openjdk-8-jdk-headless \
        python3-dev \
        python3-numpy \
        rsync \
        wget \
    && rm -rf /var/lib/apt/lists/*

# Stage 2: Final runtime environment
FROM builder as final

ARG hostuid=1000
ARG hostgid=1000

RUN groupadd --gid $hostgid --force builder \
    && useradd --gid $hostgid --uid $hostuid --non-unique builder \
    && rsync -a /etc/skel/ /home/builder
