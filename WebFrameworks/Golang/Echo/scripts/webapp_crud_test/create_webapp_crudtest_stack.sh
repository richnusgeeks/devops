#! /bin/bash

OPTN=${1}
SRVC=${2}
SHELL=${3}
NUMOPTNMX=4
CMPSFLDIR='.'
CMPSEFILE='webapp_crud_test_stack.yml'
RQRDCMNDS="cat
           docker
           docker-compose
           echo"

preReq() {

  for c in ${RQRDCMNDS}
  do
    if ! command -v "${c}" > /dev/null 2>&1
    then
      echo " Error: required command ${c} not found, exiting ..."
      exit -1
    fi
  done

}

printUsage() {

  cat <<EOF
  Usage: $(basename $0) < up|buildup|ps|exec <name> <cmnd>
                            |logs|down|cleandown >
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
     [[ "${OPTN}" != "cleandown" ]] && \
     [[ "${OPTN}" != "buildup" ]] &&
     [[ "${OPTN}" != "exec" ]]
  then
    printUsage
  fi

  export COMPOSE_IGNORE_ORPHANS=1

}

main() {

  parseArgs

  preReq

  if [[ "${OPTN}" = "up" ]]
  then
    docker-compose -f "${CMPSFLDIR}/${CMPSEFILE}" "${OPTN}" -d
  elif [[ "${OPTN}" = "buildup" ]]
  then
    docker-compose -f "${CMPSFLDIR}/${CMPSEFILE}" up wacrudtest --build -d
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
