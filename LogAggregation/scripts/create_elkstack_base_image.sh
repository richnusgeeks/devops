#! /bin/bash
set -u

failed() {
  echo "${1} failed"
  exit -1
}

rm -rf staging
mkdir staging || failed "mkdir staging"

tee staging/Dockerfile <<EOF
FROM alpine:3.6

RUN apk add --no-cache \
  alpine-sdk \
  libffi-dev \
  openssl-dev \
  python \
  python-dev \
  py-pip \
  && pip install virtualenv

RUN virtualenv /elk && \
  /elk/bin/pip install ansible==2.2.1.0 \
    colorama \
    cryptography \
    elasticsearch \
    fabric \
    requests
EOF

tee staging/.dockerignore <<EOF
Dockerfile
EOF

pushd staging || failed "pushd staging"
docker build --rm -t richnusgeeks.com:5001/richnusgeeks/rngelk/elkstack-base . || failed "docker build --rm -t richnusgeeks.com:5001/richnusgeeks/rngelk/elkstack-base ."
docker push richnusgeeks.com:5001/richnusgeeks/rngelk/elkstack-base
popd || failed "popd"

rm -rf staging || failed "rm -rfv staging"
