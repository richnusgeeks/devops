#! /bin/bash
set -uo pipefail

GOSSVER='0.3.18'
GOSSCDIR='/etc/goss'
GOSSVFLE='/lib/systemd/system/goss.service'
MONITVER=''
RQRDCMNDS="chmod
          echo
          sha256sum
          systemctl
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
  tcp:58080:
    listening: true
    ip:
    - 0.0.0.0
  tcp6:58080:
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
  goss:
    enabled: true
    running: true

process:
  sshd:
    running: true
  containerd:
    running: true
  goss:
    running: true

dns:
  localhost:
    resolvable: true
    addrs:
      consist-of: ["127.0.0.1","::1"]
    timeout: 500 # in milliseconds
EOF

}

setupGosSrvc() {

  tee "${GOSSVFLE}" <<'EOF'
[Unit]
Description=GOSS - Quick and Easy server validation
After=network.target
Documentation=https://github.com/aelsabbahy/goss/blob/master/docs/manual.md

[Service]
ExecStart=/usr/local/bin/goss -g /etc/goss/goss.yaml s -l :58080 -f documentation -e /status
ExecStop=/bin/kill -s QUIT ${MAINPID}
Restart=on-abnormal
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

  if ! systemctl enable goss
  then
    echo ' systemctl enable goss failed, exiting ...'
    exit 1
  fi

}

main() {

  preReq
  instlGoss
  cnfgrGoss
  setupGosSrvc

}

main 2>&1
