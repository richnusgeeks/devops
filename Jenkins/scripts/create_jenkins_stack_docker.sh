#! /bin/bash

OPTN=${1}
NUMOPTNMX=2
CMPSFLDIR='.'
CMPSEFILE='jenkins_stack.yml'

printUsage() {

  echo " Usage: $(basename $0) < up|buildup|ps|logs|down|cleandown >"
  exit 0

}

if [[ $# -gt ${NUMOPTNMX} ]]
then
  printUsage
fi

if [[ "${OPTN}" != "up" ]] && \
   [[ "${OPTN}" != "ps" ]] && \
   [[ "${OPTN}" != "logs" ]] && \
   [[ "${OPTN}" != "down" ]] && \
   [[ "${OPTN}" != "cleandown" ]] && \
   [[ "${OPTN}" != "buildup" ]]
then
  printUsage
else
  if [[ "${OPTN}" = "up" ]]
  then
    docker-compose -f "${CMPSFLDIR}/${CMPSEFILE}" "${OPTN}" -d
  elif [[ "${OPTN}" = "buildup" ]]
  then
    docker-compose -f "${CMPSFLDIR}/${CMPSEFILE}" up --build -d
  elif [[ "${OPTN}" = "cleandown" ]]
  then
    docker-compose -f "${CMPSFLDIR}/${CMPSEFILE}" down -v
  else
    docker-compose -f "${CMPSFLDIR}/${CMPSEFILE}" "${OPTN}"
  fi
fi
