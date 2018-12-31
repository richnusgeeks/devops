#! /bin/bash

MNTVER='5.25.2'
MNTLOG='/var/log/monit.log'
MNTDIR='/opt/monit'
MNTBDIR="${MNTDIR}/bin"
MNTCDIR="${MNTDIR}/conf"
MNTBNRY='monit'
MNTCNFG='monitrc'
MMNTVER='3.7.2'
MMNTDIR='/opt/mmonit'
MNTECDIR="${MNTDIR}/monit.d"
OSVRSNFL='/etc/os-release'
MNTCRTFL='monit.pem'
MNTCRTDIR='/etc/ssl/certs/'
KFKVER='2.11'
KFKDIR='/opt/kafka'
KFKSVER='2.1.0'
JREVERU='openjdk-8-jre-headless'
JREVERR='java-1.8.0-openjdk-headless'

exitOnErr() {
  local date=$($DATE)
  echo " Error: <$date> $1, exiting ..."
  exit 1
}

setupPreReq() {

  if ! command -v curl > /dev/null 2>&1
  then
    apt-get update -y
    apt-get install -y curl "${JREVERU}"
  else
    yum install -y "${JREVERR}"
  fi

}

setupMonit() {

  if ! curl -sSLk "https://mmonit.com/monit/dist/binary/${MNTVER}/monit-${MNTVER}-linux-x64.tar.gz" \
            -o monit.tar.gz
  then
    exitOnErr "monit ${MNTVER} tarball download failed"
  fi

  tar zxf monit.tar.gz
  mv monit-* "${MNTDIR}"
  mkdir "${MNTECDIR}"
  mv "${MNTCDIR}/${MNTCNFG}" "${MNTCDIR}/${MNTCNFG}.orig"
  rm -f monit.tar.gz

  cat <<EOF | tee "${MNTCDIR}/${MNTCNFG}"
  set daemon  10
  set log /var/log/monit.log

  #set mmonit http://monit:monit@MMONITIP:MMONITPORT/collector with timeout 10 seconds

  set httpd port 2812 and
    with ssl {
      pemfile: /etc/ssl/certs/monit.pem
    }
    use address 0.0.0.0
    allow localhost
    allow 0.0.0.0/0
    allow admin:monit
    allow guest:guest readonly

  include "${MNTECDIR}/*"
EOF
  chmod 0600 "${MNTCDIR}/${MNTCNFG}" "${MNTCRTDIR}/${MNTCRTFL}"

}

setupMMonit() {

  if ! curl -sSLk "https://mmonit.com/dist/mmonit-${MMNTVER}-linux-x64.tar.gz" \
            -o mmonit.tar.gz
  then
    exitOnErr "mmonit ${MMNTVER} tarball download failed"
  fi

  tar zxf mmonit.tar.gz
  mv mmonit-* "${MMNTDIR}"
  rm -f mmonit.tar.gz

}

setupKafka() {

  if ! curl -sSLk "https://www-eu.apache.org/dist/kafka/${KFKSVER}/kafka_${KFKVER}-${KFKSVER}.tgz" -o kafka.tgz
  then
    exitOnErr "kafka ${KFKVER}-${KFKSVER} tarball download failed"
  fi

  tar zxf kafka.tgz
  mv kafka_* "${KFKDIR}"
  rm -f kafka.tgz

  cat << EOF | tee "${MNTECDIR}/zkprkfk"
  check process zookeeper matching zookeeper
    start program = "${KFKDIR}/bin/zookeeper-server-start.sh -daemon ${KFKDIR}/config/zookeeper.properties" with timeout 60 seconds
    if failed port 2181 for 6 cycles then restart

  check process kafka matching kafkaServer
    depends on zookeeper
    start program = "${KFKDIR}/bin/kafka-server-start.sh -daemon ${KFKDIR}/config/server.properties" with timeout 60 seconds
    if failed port 9092 for 6 cycles then restart
EOF

}

main() {

  setupPreReq
  setupMonit
  setupMMonit
  setupKafka

}

main 2>&1
