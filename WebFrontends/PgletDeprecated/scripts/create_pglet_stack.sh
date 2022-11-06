#! /bin/bash

OPTN=${1}
SRVC=${2}
SHELL=${3}
NUMOPTNMX=4
CMPSFLDIR='.'
CMPSEFILE='pglet.yml'
RQRDCMNDS="docker
           docker-compose"

preReq() {

  for c in ${RQRDCMNDS}
  do
    if ! command -v "${c}" > /dev/null 2>&1
    then
      echo " Error: required command ${c} not found, exiting ..."
      exit 1
    fi
  done

  export COMPOSE_IGNORE_ORPHANS=1

}

printUsage() {

  cat <<EOF
 Usage: $(basename "${0}")
   < lint    - run static analysis on Dockerfiles and Shellscripts |
     up      - bring up pglet stack |
     buildup - like up but builds the necessary container image(s) first |
     ps      - list pglet container(s) |
     logs    - view pglet container(s) output |
     down    - bring down pglet stack |
     exec    - execute a command in a pglet container >
EOF
  exit 0

}

parseArgs() {

  if [[ $# -gt ${NUMOPTNMX} ]]
  then
    printUsage
  fi

  if [[ "${OPTN}" != "lint" ]] && \
     [[ "${OPTN}" != "up" ]] && \
     [[ "${OPTN}" != "buildup" ]] && \
     [[ "${OPTN}" != "ps" ]] && \
     [[ "${OPTN}" != "logs" ]] && \
     [[ "${OPTN}" != "down" ]] && \
     [[ "${OPTN}" != "exec" ]]
  then
    printUsage
  fi

}

preLint() {

  find . -maxdepth 1 -name 'Dockerfile*' -exec cat {} \; | \
    docker run --rm -i hadolint/hadolint 2>&1
  echo
  docker run --rm -v "${PWD}:/mnt" koalaman/shellcheck -- *.sh 2>&1

}

main() {

  parseArgs

  preReq

  if [[ "${OPTN}" = "lint" ]]
  then
    preLint
  elif [[ "${OPTN}" = "up" ]]
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
