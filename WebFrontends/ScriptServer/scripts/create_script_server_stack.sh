#! /bin/bash

OPTN=${1}
SRVC=${2}
SHELL=${3}
NUMOPTNMX=4
CMPSFLDIR='.'
CMPSEFILE='scriptserver.yml'
RQRDCMNDS="docker
           docker-compose"

preReq() {

  for c in ${RQRDCMNDS}
  do
    if ! command -v "${c}" > /dev/null 2>&1
    then
      echo " Error: required command ${c} not found, exiting ..."
      exit -1
    fi
  done

  export COMPOSE_IGNORE_ORPHANS=1

}

printUsage() {

  cat <<EOF
 Usage: $(basename "${0}")
   < up      - bring up script-server stack |
     buildup - like up but builds the necessary container image(s) first |
     ps      - list script-server container(s) |
     logs    - view script-server container(s) output |
     down    - bring down script-server stack |
     exec    - execute a command in a script-server container >
EOF
  exit 0

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
     [[ "${OPTN}" != "exec" ]]
  then
    printUsage
  fi

}

main() {

  parseArgs

  preReq

  if [[ "${OPTN}" = "up" ]]
  then
    docker-compose -f "${CMPSFLDIR}/${CMPSEFILE}" "${OPTN}" -d
  elif [[ "${OPTN}" = "buildup" ]]
  then
    docker-compose -f "${CMPSFLDIR}/${CMPSEFILE}" up --build -d
  elif [[ "${OPTN}" = "cleandown" ]]
  then
    docker-compose -f "${CMPSFLDIR}/${CMPSEFILE}" down -v
    docker image prune -f
  elif [[ "${OPTN}" = "exec" ]]
  then
    exec docker-compose -f "${CMPSFLDIR}/${CMPSEFILE}" exec "${SRVC}" "${SHELL}"
  else
    docker-compose -f "${CMPSFLDIR}/${CMPSEFILE}" "${OPTN}"
  fi

}

main 2>&1
