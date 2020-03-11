#! /bin/bash
set -uo pipefail

OPTN=${1}
SRVC=${2}
SHELL=${3}
NUMOPTNMX=4
DLYTOTINA=20
CMPSFLDIR='.'
SSHKYCTFL='sshkey_create.yml'
SSHKYSDIR='keys/out'
CMPSEFILE='infrvldtn_stack.yml'
RQRDCMNDS="docker
           docker-compose
           mkdir"
SSHPRVKEY='/etc/ssl/certs/test_servers_pkey/test'

exitOnErr() {

  echo " Error: <$(date)> $1, exiting ..."
  exit 1

}

preReq() {

  for c in ${RQRDCMNDS}
  do
    if ! command -v "${c}" > /dev/null 2>&1
    then
      exitOnErr " Error: required command ${c} not found, exiting ..."
    fi
  done

}

printUsage() {

  echo " Usage: $(basename "${0}") < up|buildup|ps|exec <name> <cmnd>|logs|down|cleandown|ctestrun >"
  exit 0

}

crtecpSSHKeys() {

  mkdir -p "${SSHKYSDIR}"

  docker-compose -f "${CMPSFLDIR}/${SSHKYCTFL}" up -d
  sleep "${DLYTOTINA}"
  if ! docker cp "sshkeygen:/tmp/${SSHKYSDIR}/test" "${SSHKYSDIR}"
  then
    exitOnErr "docker cp sshkeygen:/tmp/${SSHKYSDIR}/test ${SSHKYSDIR} failed"
  else
    if ! docker cp "sshkeygen:/tmp/${SSHKYSDIR}/test.pub" "${SSHKYSDIR}"
    then
      exitOnErr "docker cp sshkeygen:/tmp/${SSHKYSDIR}/test.pub ${SSHKYSDIR} failed"
    else
      docker-compose -f "${CMPSFLDIR}/${SSHKYCTFL}" down
    fi
  fi

}

dgossRun() {

  true

}

cstestRun() {

  docker exec -it cstest sh -c 'docker images --format "{{.Repository}}:{{.Tag}}"|sort -u|grep -v "<none>"| \
    xargs -I % sh -c "echo -n Container Structure Test run for: %;container-structure-test test \
      --image % --config /etc/cstest/config.yaml;echo"'

}

inspecRun() {

#  local TSTSRVRS=$(docker ps -f name=tstsrvr* -q|xargs -I % docker inspect --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' %|xargs|sed 's/ /,/g')
  local TSTSRVRS
  TSTSRVRS=$(docker ps -f name=tstsrvr*|grep -iv name|awk '{print $NF}'|sort -u|xargs|sed 's/ /,/g')

#  docker exec -it chefwrkstn chef-run --user root -i "${SSHPRVKEY}" \
#    "${TSTSRVRS}" package monit action=install

#  sleep 5

  for s in ${TSTSRVRS//,/ }
  do
    echo
    echo " docker container => ${s}"
    docker exec -it cwinspeck inspec detect -t "ssh://root@${s}" \
      -i "${SSHPRVKEY}"
  done
  echo

}

testinfraRun() {

  local TSTSRVRS
  TSTSRVRS=$(docker ps -f name=tstsrvr*|grep -iv name|awk '{print "@"$NF}'|xargs|sed -e 's/ /,/g' -e 's/@/root@/g')

  echo
  echo " docker container(s) => ${TSTSRVRS}"
  docker exec -it testinfra py.test -v test_myinfra.py --hosts="${TSTSRVRS}" \
    --ssh-identity-file="${SSHPRVKEY}"
  echo

}

testRun() {

  dgossRun
  cstestRun
  inspecRun
  testinfraRun

}

parseArgs() {

  if [[ $# -gt ${NUMOPTNMX} ]]
  then
    printUsage
  fi

  if [[ "${OPTN}" != "up" ]] && \
     [[ "${OPTN}" != "ps" ]] && \
     [[ "${OPTN}" != "logs" ]] && \
     [[ "${OPTN}" != "down" ]] && \
     [[ "${OPTN}" != "cleandown" ]] && \
     [[ "${OPTN}" != "buildup" ]] &&
     [[ "${OPTN}" != "ctestrun" ]] &&
     [[ "${OPTN}" != "exec" ]]
  then
    printUsage
  fi

}

main() {

  parseArgs

  preReq

  if [[ "${OPTN}" = "up" ]] || [[ "${OPTN}" = "buildup" ]]
  then
    crtecpSSHKeys
    if [[ "${OPTN}" = "up" ]]
    then
      docker-compose -f "${CMPSFLDIR}/${CMPSEFILE}" "${OPTN}" -d
    else
      docker-compose -f "${CMPSFLDIR}/${CMPSEFILE}" up --build -d
    fi
    sleep 10
    testRun
  elif [[ "${OPTN}" = "cleandown" ]] || [[ "${OPTN}" = "down" ]]
  then
    rm -rf "${SSHKYSDIR:?}/*"
    if [[ "${OPTN}" = "down" ]]
    then
      docker-compose -f "${CMPSFLDIR}/${CMPSEFILE}" "${OPTN}"
    else
      docker-compose -f "${CMPSFLDIR}/${CMPSEFILE}" down -v
    fi
  elif [[ "${OPTN}" = "ctestrun" ]]
  then
    testRun
  elif [[ "${OPTN}" = "exec" ]]
  then
    exec docker-compose -f "${CMPSFLDIR}/${CMPSEFILE}" exec "${SRVC}" "${SHELL}"
  else
    docker-compose -f "${CMPSFLDIR}/${CMPSEFILE}" "${OPTN}"
  fi

}

main 2>&1
