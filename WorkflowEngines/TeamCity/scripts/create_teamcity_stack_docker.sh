#! /bin/bash

OPTN=${1}
SRVC=${2}
SHELL=${3}
NUMOPTNMX=4
CMPSFLDIR='.'
CMPSEFILE='teamcity_stack.yml'
RQRDCMNDS="basename
           cat
           date
           docker
           docker-compose"

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

}

main() {

  parseArgs

  preReq

  if [[ "${OPTN}" = "up" ]] || [[ "${OPTN}" = "buildup" ]]
  then
    if [[ "${OPTN}" = "up" ]]
    then
      docker-compose -f "${CMPSFLDIR}/${CMPSEFILE}" "${OPTN}" -d
    else
      docker-compose -f "${CMPSFLDIR}/${CMPSEFILE}" up --build -d
    fi
  elif [[ "${OPTN}" = "cleandown" ]] || [[ "${OPTN}" = "down" ]]
  then
    if [[ "${OPTN}" = "down" ]]
    then
      docker-compose -f "${CMPSFLDIR}/${CMPSEFILE}" "${OPTN}"
    else
      docker-compose -f "${CMPSFLDIR}/${CMPSEFILE}" down -v
    fi
  elif [[ "${OPTN}" = "exec" ]]
  then
    exec docker-compose -f "${CMPSFLDIR}/${CMPSEFILE}" exec "${SRVC}" "${SHELL}"
  else
    docker-compose -f "${CMPSFLDIR}/${CMPSEFILE}" "${OPTN}"
  fi

}

main 2>&1
