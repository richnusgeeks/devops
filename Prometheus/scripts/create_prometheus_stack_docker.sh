#! /bin/bash

OPTN=${1}
SRVC=${2}
SHELL=${3}
NUMOPTNMX=4
CMPSFLDIR='.'
CMPSEFILE="$(ls *.yml|xargs|sed "s/ / -f ${CMPSFLDIR}\//g")"
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

  export COMPOSE_IGNORE_ORPHANS=True

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
    terraform init
    terraform apply -auto-approve

    if [[ "${OPTN}" = "up" ]]
    then
      eval docker-compose -f "${CMPSEFILE}" "${OPTN}" -d
    else
      eval docker-compose -f "${CMPSEFILE}" up --build -d
    fi
  elif [[ "${OPTN}" = "cleandown" ]] || [[ "${OPTN}" = "down" ]]
  then
    terraform init
    terraform destroy -auto-approve

    if [[ "${OPTN}" = "down" ]]
    then
      eval docker-compose -f "${CMPSEFILE}" "${OPTN}"
    else
      eval docker-compose -f "${CMPSEFILE}" down -v
    fi
  elif [[ "${OPTN}" = "exec" ]]
  then
    exec docker-compose -f "${CMPSEFILE}" exec "${SRVC}" "${SHELL}"
  else
    eval docker-compose -f "${CMPSEFILE}" "${OPTN}"
  fi

}

main 2>&1
