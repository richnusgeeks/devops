#! /bin/bash

MNTVER='5.27.0'
MNTLOG='/var/log/monit.log'
MNTDIR='/opt/monit'
MNTBDIR="${MNTDIR}/bin"
MNTCDIR="${MNTDIR}/conf"
MNTBNRY='monit'
MNTCNFG='monitrc'
MMNTVER='3.7.3'
MMNTDIR='/opt/mmonit'
MNTECDIR="${MNTDIR}/monit.d"
MNTDCRIT=90
KFKVER='2.13'
KFKDIR='/opt/kafka'
KFKSVER='2.6.0'
JREVERU='openjdk-8-jre-headless'
CMNPCKGS="curl
          daemonize"

exitOnErr() {
  local date=$($DATE)
  echo " Error: <$date> $1, exiting ..."
  exit 1
}

setupPreReq() {

  apt-get update -y
  apt-get install -y --no-install-recommends ${CMNPCKGS} "${JREVERU}"

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
  set daemon 10
  set log /var/log/monit.log

  set mail-format { from: monit@richnusgeeks.demo }

  set httpd port 2812 and
    use address 0.0.0.0
    allow localhost
    allow 0.0.0.0/0
    allow admin:monit
    allow guest:guest readonly

  include "${MNTECDIR}/*"
EOF
  chmod 0600 "${MNTCDIR}/${MNTCNFG}" "${MNTCRTDIR}/${MNTCRTFL}"

  cat << EOF | tee "${MNTECDIR}/spaceinode"
  check filesystem rootfs with path /
    if space usage > ${MNTDCRIT}% then alert
    if inode usage > ${MNTDCRIT}% then alert
EOF

  "${MNTBDIR}/${MNTBNRY}" -c "${MNTCDIR}/${MNTCNFG}"

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

  "${MNTBDIR}/${MNTBNRY}" -c "${MNTCDIR}/${MNTCNFG}" reload

}

main() {

  setupPreReq
  setupMonit
  setupKafka

}

main 2>&1
