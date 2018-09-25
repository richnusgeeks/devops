#! /bin/bash

OPTN=${1}
NUMOPTNMX=2
CMPSFLDIR='.'
CMPSEFILE='confluent_stack.yml'

printUsage() {

  echo " Usage: $(basename $0) < up|ps|logs|down|test >"
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
   [[ "${OPTN}" != "test" ]]
then
  printUsage
else
  if [[ "${OPTN}" = "up" ]]
  then
    docker-compose -f "${CMPSFLDIR}/${CMPSEFILE}" "${OPTN}" -d
  elif [[ "${OPTN}" = "test" ]]
  then
    ./validate.sh
  else
    docker-compose -f "${CMPSFLDIR}/${CMPSEFILE}" "${OPTN}"
  fi
fi
