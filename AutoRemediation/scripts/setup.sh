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

exitOnErr() {
  local date=$($DATE)
  echo " Error: <$date> $1, exiting ..."
  exit 1
}

if ! command curl -V > /dev/null 2>&1
then
  apt-get update -y
  apt-get install -y curl
fi

if ! curl -sSLk "https://mmonit.com/monit/dist/binary/${MNTVER}/monit-${MNTVER}-linux-x64.tar.gz" \
          -o monit.tar.gz
then
  exitOnErr "monit ${MNTVER} tarball download failed"
fi

tar zxvf monit.tar.gz
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

if ! curl -sSLk "https://mmonit.com/dist/mmonit-${MMNTVER}-linux-x64.tar.gz" \
          -o mmonit.tar.gz
then
  exitOnErr "mmonit ${MMNTVER} tarball download failed"
fi

tar zxvf mmonit.tar.gz 
mv mmonit-* "${MMNTDIR}"
rm -f mmonit.tar.gz
