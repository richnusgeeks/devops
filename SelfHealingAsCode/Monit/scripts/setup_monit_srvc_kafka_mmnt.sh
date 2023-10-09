#! /bin/bash
set -uo pipefail

KAFKAVER='3.4.0'
KFKSCVER='2.13'
MONITSDIR='/opt/monit/monit.d'
RQRDCMNDS="apt-get
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

main() {

  preReq

  setupDckrCmps
  setupKafkaWebUI
  setupZkprKfk
  cnfgrMonitKafkaCheck

}

main 2>&1
