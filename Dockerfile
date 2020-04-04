# Build environment for OpenCV

FROM trzeci/emscripten:latest
MAINTAINER Caleb Xu <calebcenter@live.com>

ENV \
	CCACHE_SIZE=50G \
    CCACHE_DIR=/srv/ccache \
    USE_CCACHE=1 \
    CCACHE_COMPRESS=1 \
    PATH=$PATH:/usr/local/bin/

RUN sed -i 's/main$/main contrib non-free/' /etc/apt/sources.list \
	&& export DEBIAN_FRONTEND=noninteractive \
	&& apt-get update -y \
	&& apt-get clean -y \
	&& apt-get install -y locales \
	&& locale-gen --purge en_US.UTF-8 \
	&& echo -e 'LANG="en_US.UTF-8"\nLANGUAGE="en_US:en"\n' > /etc/default/locale \
	&& apt-get update -y \
	&& apt-get upgrade -y \
	&& apt-get install -y \
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

ARG hostuid=1000
ARG hostgid=1000

RUN groupadd --gid $hostgid --force builder \
 	&& useradd --gid $hostgid --uid $hostuid --non-unique builder \
 	&& rsync -a /etc/skel/ /home/builder/ \
 	&& chown -R builder:builder /home/builder \
 	&& mkdir /home/builder/out \
 	&& chown -R builder:builder /home/builder/out

VOLUME /home/builder/out

USER builder
WORKDIR /home/builder

ADD builder/build.sh /home/builder/build.sh
CMD /home/builder/build.sh
