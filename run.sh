#!/usr/bin/env bash

set -euo pipefail

cd $(dirname $0)

OUT=$(pwd)/out
CONTAINER_HOME=/home/builder
CONTAINER=opencv-build
REPOSITORY=alebcay/opencv-build
TAG=1.0
FORCE_BUILD=0
ENVIRONMENT=

export OPENCV_BUILD_CONTRIB=0
export OPENCV_BUILD_TARGET_ANDROID=0
export OPENCV_BUILD_TARGET_CPP_SHARED=0
export OPENCV_BUILD_TARGET_CPP_STATIC=0
export OPENCV_BUILD_TARGET_JAVA=0
export OPENCV_BUILD_TARGET_JS=0
export OPENCV_VERSION=0

while getopts crvt:-: arg; do
  case $arg in
    c ) OPENCV_BUILD_CONTRIB=1 ;;
    r ) FORCE_BUILD=1 ;;
    t ) case $OPTARG in
            android ) OPENCV_BUILD_TARGET_ANDROID=1 ;;
            cpp-shared ) OPENCV_BUILD_TARGET_CPP_SHARED=1 ;;
            cpp-static ) OPENCV_BUILD_TARGET_CPP_STATIC=1 ;;
            java ) OPENCV_BUILD_TARGET_JAVA=1 ;;
            js ) OPENCV_BUILD_TARGET_JS=1 ;;
            * ) echo "no such target $OPTARG known" >&2; exit 2;;
        esac ;;
    v ) OPENCV_VERSION="$OPTARG" ;;
    - ) LONG_OPTARG="${OPTARG#*=}"
        case $OPTARG in
            with-contrib )  OPENCV_BUILD_CONTRIB=1 ;;
            rebuild      )  FORCE_BUILD=1 ;;
            target=?*    )  case $LONG_OPTARG in
                                android ) OPENCV_BUILD_TARGET_ANDROID=1 ;;
                                cpp-shared ) OPENCV_BUILD_TARGET_CPP_SHARED=1 ;;
                                cpp-static ) OPENCV_BUILD_TARGET_CPP_STATIC=1 ;;
                                java ) OPENCV_BUILD_TARGET_JAVA=1 ;;
                                js ) OPENCV_BUILD_TARGET_JS=1 ;;
                                * ) echo "no such target $LONG_OPTARG known" >&2; exit 2;;
                            esac ;;
            target*      )  echo "No arg for --$OPTARG option" >&2; exit 2 ;;
            version=?*   )  OPENCV_VERSION="$LONG_OPTARG" ;;
            version*     )  echo "No arg for --$OPTARG option" >&2; exit 2 ;;
            rebuild* | with-contrib* )
                            echo "No arg allowed for --$OPTARG option" >&2; exit 2 ;;
            ''           )  break ;; # "--" terminates argument processing
            *            )  echo "Illegal option --$OPTARG" >&2; exit 2 ;;
        esac ;;
    \? ) exit 2 ;;  # getopts already reported the illegal option
  esac
done
shift $((OPTIND-1)) # remove parsed options and args from $@ list

# Create shared folders
# Although Docker would create non-existing directories on the fly,
# we need to have them owned by the user (and not root), to be able
# to write in them, which is a necessity for startup.sh
mkdir -p $OUT

command -v docker >/dev/null \
    || { echo "command 'docker' not found."; exit 1; }

# Build image if needed
if [[ $FORCE_BUILD = 1 ]] || ! docker inspect $REPOSITORY:$TAG &>/dev/null; then

    docker build \
        --pull \
        -t $REPOSITORY:$TAG \
        --build-arg hostuid=$(id -u) \
        --build-arg hostgid=$(id -g) \
        .

    # After successful build, delete existing containers
    if docker inspect $CONTAINER &>/dev/null; then
        docker rm $CONTAINER >/dev/null
    fi
fi

# With the given name $CONTAINER, reconnect to running container, start
# an existing/stopped container or run a new one if one does not exist.
IS_RUNNING=$(docker inspect -f '{{.State.Running}}' $CONTAINER 2>/dev/null) || true
if [[ $IS_RUNNING == "true" ]]; then
    docker attach $CONTAINER
elif [[ $IS_RUNNING == "false" ]]; then
    docker start -i $CONTAINER
else
    docker run \
        -e OPENCV_VERSION \
        -e OPENCV_BUILD_CONTRIB \
        -e OPENCV_BUILD_TARGETS \
        -e OPENCV_BUILD_TARGET_ANDROID \
        -e OPENCV_BUILD_TARGET_CPP_SHARED \
        -e OPENCV_BUILD_TARGET_CPP_STATIC \
        -e OPENCV_BUILD_TARGET_JAVA \
        -e OPENCV_BUILD_TARGET_JS \
        -e LANG=C.UTF-8 \
        -h docker-opencv \
        -v $OUT:$CONTAINER_HOME/out \
        -i -t $ENVIRONMENT --name $CONTAINER $REPOSITORY:$TAG
fi

exit $?
