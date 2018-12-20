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

exitOnErr() {
  local date=$($DATE)
  echo " Error: <$date> $1, exiting ..."
  exit 1
}

if [[ "${MMONIT_ENABLED}" = 'true' ]]
then
  cat<<EOF | tee "${MNTECDIR}/mmonit"
check process mmonit with pidfile "${MMNTDIR}/logs/mmonit.pid"
  start program = "${MMNTDIR}/bin/mmonit"
  stop program = "${MMNTDIR}/bin/mmonit stop"
EOF
fi

if [[ ! -z "${MMONIT_ADDR}" ]]
then
  IP=$(echo "${MMONIT_ADDR}"|awk -F":" '{print $1}')
  PORT=$(echo "${MMONIT_ADDR}"|awk -F":" '{print $2}')

  if [[ -z "${IP}" ]] || [[ -z "${PORT}" ]]
  then
    exitOnErr "empty MMonit IP or PORT (required format <IP>:<PORT>)"
  else
    if ! sed -i -e "/MMONITIP/s/^ *#//" \
                -e "s/MMONITIP/${IP}/" \
                -e "s/MMONITPORT/${PORT}/" \
                   "${MNTCDIR}/${MNTCNFG}"
    then
      exitOnErr "MMonit ip/port substitution failed"
    fi
  fi
fi

pushd "${MNTDIR}"
"${MNTBDIR}/${MNTBNRY}" -c "${MNTCDIR}/${MNTCNFG}"
sleep 5
tail -f "${MNTLOG}"
