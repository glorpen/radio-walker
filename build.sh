#!/bin/bash

set -ex

PROJECT_DIR="$(dirname "$(realpath "${0}")")"

_build() {
  SR_VERSION=1.64.6
  TAG="$(git tag --points-at HEAD)"

  if [ ! -f streamripper.tar.gz ];
  then
    wget https://nav.dl.sourceforge.net/project/streamripper/streamripper%20%28current%29/${SR_VERSION}/streamripper-${SR_VERSION}.tar.gz -O streamripper.tar.gz
  fi

  chmod a+r nginx.conf

  docker build -t "glorpen/radiobuffer:${TAG/v/}" "${PROJECT_DIR}"
}

_clean() {
  rm streamripper.tar.gz
}

case $1 in
build)
  _build;;
clean)
  _clean;;
*)
  echo "Only build and clean commands are supported"
  ;;
esac