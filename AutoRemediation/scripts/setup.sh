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
CNSLVER='1.4.0'
CSLCDIR='/etc/consul.d'
CSLDDIR='/var/lib/consul'
CMNPCKGS="unzip
          curl
          daemonize"

exitOnErr() {
  local date=$($DATE)
  echo " Error: <$date> $1, exiting ..."
  exit 1
}

setupPreReq() {

  if ! command -v curl > /dev/null 2>&1
  then
    apt-get update -y
    apt-get install -y --no-install-recommends ${CMNPCKGS} "${JREVERU}"
  else
    local OSVRSNFL='/etc/os-release'
    if [[ ! -f "${OSVRSNFL}" ]]
    then
      OSVER=6
    else
      OSVER=7
    fi

    rpm -ivh https://dl.fedoraproject.org/pub/epel/epel-release-latest-${OSVER}.noarch.rpm
    yum install -y unzip ${CMNPCKGS} "${JREVERR}"
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
  set daemon 10
  set log /var/log/monit.log

  set mail-format { from: monit@richnusgeeks.demo }

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

  cat << EOF | tee "${MNTECDIR}/spaceinode"
  check filesystem rootfs with path /
    if space usage > 80% then alert
    if inode usage > 80% then alert
EOF

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

setupConsul() {

  if ! curl -sSLk "https://releases.hashicorp.com/consul/${CNSLVER}/consul_${CNSLVER}_linux_amd64.zip" -o consul.zip
  then
    exitOnErr "consul ${CNSLVER} archive download failed"
  fi

  unzip consul.zip -d /usr/local/bin
  rm -f consul.zip

  mkdir -p "${CSLCDIR}" "${CSLDDIR}"
  cat << EOF | tee "${CSLCDIR}/server.json"
{
  "server": true,
  "bootstrap": true,
  "data_dir": "${CSLDDIR}",
  "log_level": "DEBUG",
  "client_addr": "0.0.0.0",
  "ui": true,
  "enable_local_script_checks": true
}
EOF

  cat << EOF | tee "${CSLCDIR}/watches.json"
{
  "watches": [
    {
      "type": "checks",
      "state": "warning",
      "args": ["/usr/local/bin/watches_handler.sh","warning"]
    },
    {
      "type": "checks",
      "state": "critical",
      "args": ["/usr/local/bin/watches_handler.sh","critical"]
    }
  ]
}
EOF

  cat << 'EOF' | tee /usr/local/bin/watches_handler.sh
#! /bin/bash

printUsage() {

  echo " Usage: $(basename $0) < warning|critical >"
  exit 0

}

if [[ $# -ne 1 ]]
then
  printUsage
fi

if [[ "${1}" != "warning" ]] && \
   [[ "${1}" != "critical" ]]
then
  printUsage
fi

cat -
echo " $(date) ${1} watch handler triggered ..."
EOF
chmod +x /usr/local/bin/watches_handler.sh

  cat << EOF | tee "${MNTECDIR}/consul"
  check process consulserver with pidfile /var/run/consulserver.pid
    start program = "/usr/sbin/daemonize -a -e /var/log/consulserver -o /var/log/consulserver -p /var/run/consulserver.pid /usr/local/bin/consul agent -config-dir=/etc/consul.d" with timeout 60 seconds
    if failed port 8500 for 6 cycles then restart
EOF

}

main() {

  setupPreReq
  setupMonit
  setupMMonit
  setupKafka
  setupConsul

}

main 2>&1
