#! /bin/bash

OPTN=${1}
NUMOPTNMX=2
CMPSFLDIR='.'
CMPSEFILE='consul_stack.yml'

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
  if [[ "${OPTN}" = "up" ]] || \
     [[ "${OPTN}" = "buildup" ]]
  then
    terraform init
    terraform apply -auto-approve
  elif [[ "${OPTN}" = "down" ]] || \
       [[ "${OPTN}" = "cleandown" ]]
  then
    terraform init
    terraform destroy -auto-approve
  fi

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
