#! /bin/bash

OPTN=${1}
SRVC=${2}
SHELL=${3}
NUMOPTNMX=4
CMPSFLDIR='.'
CMPSEFILE='rmq_stack.yml'
RQRDCMNDS="curl
           docker
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

}

printUsage() {

  echo " Usage: $(basename $0) < up|buildup|ps|exec <name> <cmnd>|test|logs|down|cleandown >"
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
     [[ "${OPTN}" != "exec" ]] &&
     [[ "${OPTN}" != "test" ]]

  then
    printUsage
  fi

}

testRMQ() {

  true  

}

main() {

  parseArgs

  preReq

  if [[ "${OPTN}" = "up" ]] || \
     [[ "${OPTN}" = "buildup" ]]
  then
    local RMQERC=$(docker run -it --rm consul sh -c 'date +%s|sha1sum|sed "s/ -//"')
    terraform init
    terraform apply -auto-approve
    export RMQERC=${RMQERC}
    docker-compose -f "${CMPSFLDIR}/${CMPSEFILE}" pull
  elif [[ "${OPTN}" = "down" ]] || \
       [[ "${OPTN}" = "cleandown" ]]
  then
    unset RMQERC
    terraform init
    terraform destroy -auto-approve
  fi

  if [[ "${OPTN}" = "up" ]]
  then
    docker-compose -f "${CMPSFLDIR}/${CMPSEFILE}" "${OPTN}" -d
    sleep 10
    testRMQ
  elif [[ "${OPTN}" = "buildup" ]]
  then
    docker-compose -f "${CMPSFLDIR}/${CMPSEFILE}" up --build -d
    sleep 10
    testRMQ
  elif [[ "${OPTN}" = "cleandown" ]]
  then
    docker-compose -f "${CMPSFLDIR}/${CMPSEFILE}" down -v
  elif [[ "${OPTN}" = "exec" ]]
  then
    exec docker-compose -f "${CMPSFLDIR}/${CMPSEFILE}" exec "${SRVC}" "${SHELL}"
  elif [[ "${OPTN}" = "test" ]]
  then
    testRMQ
  else
    docker-compose -f "${CMPSFLDIR}/${CMPSEFILE}" "${OPTN}"
  fi

}

main 2>&1
