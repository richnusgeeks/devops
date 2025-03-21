#! /bin/bash
set -uo pipefail

MONITVER='5.34.4'
DSPCWMARK="${DSPCE_WMARK:-90}"
INDEWMARK="${INODE_WMARK:-90}"
MONITBDIR='/opt/monit/bin'
MONITCDIR='/opt/monit/conf'
MONITSDIR='/opt/monit/monit.d'
MONITVFLE='/lib/systemd/system/monit.service'
RQRDCMNDS="chmod
          cp
          echo
          rm
          systemctl
          tar
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

instlMonit() {

  if ! wget "https://mmonit.com/monit/dist/binary/${MONITVER}/monit-${MONITVER}-linux-x64.tar.gz" -O /tmp/monit.tgz
  then
    echo "wget https://mmonit.com/monit/dist/binary/${MONITVER}/monit-${MONITVER}-linux-x64.tar.gz -O /tmp/monit.tgz failed, exiting ..."
    exit 1
  fi

  if ! tar -C /tmp -zxf /tmp/monit.tgz
  then
    echo "tar -C /tmp -zxf /tmp/monit.tgz failed, exiting ..."
    exit 1
  else
    mkdir -p "${MONITBDIR}"
    if ! cp "/tmp/monit-${MONITVER}/bin/monit" "${MONITBDIR}/monit"
    then
      echo "cp /tmp/monit-${MONITVER}/bin/monit ${MONITBDIR}/monit failed, exiting ..."
      exit 1
    else
      rm -rf /tmp/monit{.tgz,-"${MONITVER}"}
    fi
  fi

}

cnfgrMonit() {

  mkdir "${MONITCDIR}"
  tee "${MONITCDIR}/monitrc" <<EOF
CHECK SYSTEM monitdemo
set daemon 10
set log /var/log/monit.log

set mail-format { from: monit@richnusgeeks.demo }

set httpd port 2812 and
  use address 0.0.0.0
  allow localhost
  allow 0.0.0.0/0
  allow admin:monit
  allow guest:guest readonly

include /opt/monit/monit.d/*
EOF

  if ! chmod 0600 "${MONITCDIR}/monitrc"
  then
    echo "chmod 0600 ${MONITCDIR}/monitrc failed, exiting ..."
    exit 1
  fi

}

cnfgrMonitFSCheck() {

  mkdir "${MONITSDIR}"
  tee "${MONITSDIR}/spaceinode" <<EOF
check filesystem rootfs with path /
  if space usage > ${DSPCWMARK}% then alert
  if inode usage > ${INDEWMARK}% then alert
EOF

}

setupMonitSrvc() {

  tee "${MONITVFLE}" <<'EOF'
[Unit]
Description=Pro-active monitoring utility for unix systems
After=network.target
Documentation=man:monit(1) https://mmonit.com/wiki/Monit/HowTo

[Service]
Type=simple
KillMode=process
ExecStart=/opt/monit/bin/monit -I -c /opt/monit/conf/monitrc
ExecStop=/opt/monit/bin/monit -c /opt/monit/conf/monitrc quit
ExecReload=/opt/monit/bin/monit -c /opt/monit/conf/monitrc reload
Restart=on-abnormal
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

  if ! systemctl enable monit
  then
    echo ' systemctl enable monit failed, exiting ...'
    exit 1
  fi

}

main() {

  preReq
  instlMonit
  cnfgrMonit
  cnfgrMonitFSCheck
  setupMonitSrvc

}

main 2>&1
