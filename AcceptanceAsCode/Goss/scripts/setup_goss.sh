#! /bin/bash
set -uo pipefail

GOSSVER='0.3.18'
GOSSCDIR='/etc/goss'
MONITVER=''
RQRDCMNDS="chmod
          echo
	  sha256sum
	  tee
          wget"

preReq() {

  for c in ${RQRDCMNDS}
  do
    if ! command -v "${c}" > /dev/null 2>&1
    then
      echo " Error: required command ${c} not found, exiting ..."
      exit 1
    fi
  done

}

instlGoss() {

  if ! wget -P /tmp "https://github.com/aelsabbahy/goss/releases/download/v${GOSSVER}/goss-linux-amd64"
  then
    echo "wget -P /tmp https://github.com/aelsabbahy/goss/releases/download/v${GOSSVER}/goss-linux-amd64 failed, exiting ..."
    exit 1
  fi

  if ! wget -P /tmp "https://github.com/aelsabbahy/goss/releases/download/v${GOSSVER}/goss-linux-amd64.sha256"
  then
    echo "wget -P /tmp https://github.com/aelsabbahy/goss/releases/download/v${GOSSVER}/goss-linux-amd64.sha256 failed, continuing ..."
  else
    pushd /tmp
    if ! sha256sum -c goss-linux-amd64.sha256
    then
      echo 'sha256sum -c goss-linux-amd64.sha256 failed, continuing ...'
    fi
    rm goss-linux-amd64.sha256
    popd

  fi

  if chmod +x /tmp/goss-linux-amd64
  then
    mv /tmp/goss-linux-amd64 /usr/local/bin/goss
  else
    echo 'chmod +x /tmp/goss-linux-amd64 failed, exiting ...'
    exit 1
  fi

}

cnfgrGoss() {

  mkdir "${GOSSCDIR}"
  tee "${GOSSCDIR}/goss.yaml" <<EOF
kernel-param:
  kernel.ostype:
    value: Linux

mount:
  /:
    exists: true
    filesystem: overlay
    usage:
      lt: 90

port:
  tcp:22:
    listening: true
    ip:
    - 0.0.0.0
  tcp6:22:
    listening: true
    ip:
    - '::'

user:
  sshd:
    exists: true

package:
  docker-ce:
    installed: true

service:
  sshd:
    enabled: true
    running: true
  docker:
    enabled: true
    running: true

process:
  sshd:
    running: true
  containerd:
    running: true

dns:
  localhost:
    resolvable: true
    addrs:
      consist-of: ["127.0.0.1","::1"]
    timeout: 500 # in milliseconds
EOF

}

main() {

  preReq
  instlGoss
  cnfgrGoss

}

main 2>&1
