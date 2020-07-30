#! /bin/bash

OPTN=${1}
SRVC=${2}
CMND=${3}
NUMOPTNMX=4
CMPSFLDIR='.'
CMPSEFILE='cadence_stack.yml'
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

  echo " Usage: $(basename $0) < up|buildup|ps|exec <name> <cmnd>|logs|down|test|cleandown >"
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
     [[ "${OPTN}" != "test" ]] && \
     [[ "${OPTN}" != "cleandown" ]] && \
     [[ "${OPTN}" != "buildup" ]] && \
     [[ "${OPTN}" != "exec" ]]
  then
    printUsage
  fi

}

testCdnceStck() {

  true

}

main() {

  parseArgs

  preReq

  if [[ "${OPTN}" = "up" ]]
  then
    docker-compose -f "${CMPSFLDIR}/${CMPSEFILE}" "${OPTN}" -d
    testCdnceStck
  elif [[ "${OPTN}" = "test" ]]
  then
    testCdnceStck
  elif [[ "${OPTN}" = "buildup" ]]
  then
    docker-compose -f "${CMPSFLDIR}/${CMPSEFILE}" up --build -d
    testCdnceStck
  elif [[ "${OPTN}" = "cleandown" ]]
  then
    docker-compose -f "${CMPSFLDIR}/${CMPSEFILE}" down -v
  elif [[ "${OPTN}" = "exec" ]]
  then
    docker-compose -f "${CMPSFLDIR}/${CMPSEFILE}" exec "${SRVC}" "${CMND}"
  else
    docker-compose -f "${CMPSFLDIR}/${CMPSEFILE}" "${OPTN}"
  fi

}

main 2>&1
