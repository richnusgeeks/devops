#! /bin/bash
set -uo pipefail

MONITVER='5.34.4'
MONITBDIR='/opt/monit/bin'
MONITCDIR='/opt/monit/conf'
MONITSDIR='/opt/monit/monit.d'
MONITVFLE='/lib/systemd/system/monit.service'
MMONITVER='4.3.4'
MMONITLDIR='/opt/mmonit'
MMONITBDIR='/opt/mmonit/bin'
MMONITCDIR='/opt/mmonit/conf'
MMONITVFLE='/lib/systemd/system/mmonit.service'
RQRDCMNDS="chmod
          cp
          echo
          mv
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

  if ! wget -q "https://mmonit.com/monit/dist/binary/${MONITVER}/monit-${MONITVER}-linux-x64.tar.gz" -O /tmp/monit.tgz
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
set daemon 10
set log /var/log/monit.log

set eventqueue basedir /var/monit/ slots 1000
set mmonit http://monit:monit@localhost:8080/collector

set mail-format { from: monit@richnusgeeks.demo }

set httpd port 2812 and
  allow localhost
  allow monit:monit

include /opt/monit/monit.d/*
EOF

  if ! chmod 0600 "${MONITCDIR}/monitrc"
  then
    echo "chmod 0600 ${MONITCDIR}/monitrc failed, exiting ..."
    exit 1
  else
    mkdir "${MONITSDIR}"
  fi

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

cnfgrMMonitCheck() {

  tee "${MONITSDIR}/mmonit" <<EOF
check process mmnt matching mmoni
  start program = "/usr/bin/systemctl start mmonit" with timeout 20 seconds
  stop program = "/usr/bin/systemctl stop mmonit" with timeout 20 seconds
  if failed port 8080 for 2 cycles then restart
EOF

}

instlMMonit() {

  if ! wget "https://mmonit.com/dist/mmonit-${MMONITVER}-linux-x64.tar.gz" -O /tmp/mmonit.tgz
  then
    echo "wget https://mmonit.com/dist/mmonit-${MMONITVER}-linux-x64.tar.gz -O /tmp/monit.tgz failed, exiting ..."
    exit 1
  fi

  if ! tar -C /tmp -zxf /tmp/mmonit.tgz
  then
    echo "tar -C /tmp -zxf /tmp/mmonit.tgz failed, exiting ..."
    exit 1
  else
    if ! mv "/tmp/mmonit-${MMONITVER}" "${MMONITLDIR}"
    then
      echo "mv /tmp/monit-${MMONITVER} ${MMONITLDIR} failed, exiting ..."
      exit 1
    else
      rm -rf /tmp/mmonit.tgz
    fi
  fi

}

setupMMonitSrvc() {

  tee "${MMONITVFLE}" <<'EOF'
[Unit]
Description=System for automatic management and pro-active monitoring of Information Technology Systems.
After=network.target
Documentation=https://mmonit.com/documentation/mmonit_manual.pdf

[Service]
Type=simple
KillMode=process
ExecStart=/opt/mmonit/bin/mmonit -i -c /opt/mmonit/conf/server.xml start
ExecStop=/opt/mmonit/bin/mmonit -i -c /opt/mmonit/conf/server.xml stop
Restart=on-abnormal
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

  if ! systemctl enable mmonit
  then
    echo ' systemctl enable monit failed, exiting ...'
    exit 1
  fi

}


main() {

  preReq
  instlMonit
  cnfgrMonit
  setupMonitSrvc
  cnfgrMMonitCheck
  instlMMonit
  setupMMonitSrvc

}

main 2>&1
