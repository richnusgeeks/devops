#! /bin/bash
set -uo pipefail

MONITVER='5.33.0'
KAFKAVER='3.4.0'
KFKSCVER='2.13'
DSPCWMARK="${DSPCE_WMARK:-90}"
INDEWMARK="${INODE_WMARK:-90}"
MONITBDIR='/opt/monit/bin'
MONITCDIR='/opt/monit/conf'
MONITSDIR='/opt/monit/monit.d'
MONITVFLE='/lib/systemd/system/monit.service'
RQRDCMNDS="apt-get
          chmod
          cp
          echo
          mkdir
          rm
          systemctl
          usermod
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

setupDckrCmps() {

  if ! wget -q "https://get.docker.com" -O /tmp/get-docker.sh
  then
    echo "wget https://get.docker.com -O /tmp/get-docker.sh failed, exiting ..."
    exit 1
  fi

  if ! sh /tmp/get-docker.sh
  then
    echo "sh /tmp/get-docker.sh failed, exiting ..."
    exit 1
  else
    rm -f /tmp/get-docker.sh
    if ! usermod -aG docker "$(whoami)"
    then
	    echo "usermod -aG docker $(whoami) failed, exiting ..."
      exit 1
    fi
  fi

}

setupKafkaWebUI() {

  mkdir -p /opt/docker/compose
  tee /opt/docker/compose/kafkawebui.yml <<EOF
version: "2.4"
services:
  kafkawebui:
    image: docker.redpanda.com/vectorized/console:latest
    container_name: kafkawebui
    hostname: kafkawebui
    mem_limit: 512m
    network_mode: host
    restart: unless-stopped
    environment:
      - KAFKA_BROKERS=localhost:9092
EOF

  tee "${MONITSDIR}/kfkwebui" <<EOF
check program kfkwebui with path "/usr/bin/docker compose -f /opt/docker/compose/kafkawebui.yml up -d"
  if status != 0 then unmonitor
EOF

}

setupZkprKfk() {

  if ! DEBIAN_FRONTEND=noninteractive apt-get install -y -qq --no-install-recommends openjdk-8-jre-headless >/dev/null
  then
    echo "apt-get install -y --no-install-recommends openjdk-8-jre-headless failed, exiting ..."
    exit 1
  fi

  if ! wget -q "https://dlcdn.apache.org/kafka/${KAFKAVER}/kafka_${KFKSCVER}-${KAFKAVER}.tgz" -O /tmp/kafka.tgz
  then
    echo "wget https://dlcdn.apache.org/kafka/${KAFKAVER}/kafka_${KFKSCVER}-${KAFKAVER}.tgz failed, exiting ..."
    exit 1
  fi

  if ! tar -C /tmp -zxf /tmp/kafka.tgz
  then
    echo "tar -C /tmp -zxf /tmp/kafka.tgz failed, exiting ..."
    exit 1
  else
    if ! mv "/tmp/kafka_${KFKSCVER}-${KAFKAVER}" /opt/kafka
    then
      echo "mv /tmp/kafka_${KFKSCVER}-${KAFKAVER} /opt/kafka failed, exiting ..."
      exit 1
    else
      rm -f /tmp/kafka.tgz
    fi
  fi

}

cnfgrMonitKafkaCheck() {

  tee "${MONITSDIR}/zkprkfk" <<EOF
check process zookeeper matching zookeeper
  start program = "/opt/kafka/bin/zookeeper-server-start.sh -daemon /opt/kafka/config/zookeeper.properties" with timeout 60 seconds
  stop program = "/opt/kafka/bin/zookeeper-server-stop.sh /opt/kafka/config/zookeeper.properties" with timeout 60 seconds
  if failed port 2181 for 6 cycles then restart

check process kafka matching kafkaServer
  depends on zookeeper
  start program = "/opt/kafka/bin/kafka-server-start.sh -daemon /opt/kafka/config/server.properties" with timeout 60 seconds
  stop program = "/opt/kafka/bin/kafka-server-stop.sh /opt/kafka/config/server.properties" with timeout 60 seconds
  if failed port 9092 for 6 cycles then restart
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

  setupDckrCmps
  setupKafkaWebUI
  setupZkprKfk
  cnfgrMonitKafkaCheck

}

main 2>&1
