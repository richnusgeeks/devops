#! /bin/bash

OPTN=${1}
SRVC=${2}
SHELL=${3}
NUMOPTNMX=4
CMPSFLDIR='.'
CMPSEFILE='hzcast_stack.yml'
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

testHZcast() {

  local HZMC=$(docker ps -f name=hzcastmc -q|xargs -I % docker inspect --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' %|xargs)
  #local HZSRVRS=$(docker ps -f name=hzcast[0-9] -q|xargs -I % docker inspect --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' %|xargs)
  local HZSRVRS=$(docker ps -f name=hzcast[0-9]|grep -iv name|awk '{print $NF}'|xargs)

  echo
  for s in ${HZSRVRS}
  do
    echo "HZcast server: ${s} healthcheck =>"
    docker exec -it hzcastmc sh -c "curl http://${s}:5701/hazelcast/health"
    echo
  done

}

main() {

  parseArgs

  preReq

  if [[ "${OPTN}" = "up" ]]
  then
    docker-compose -f "${CMPSFLDIR}/${CMPSEFILE}" "${OPTN}" -d
    sleep 10
    testHZcast
  elif [[ "${OPTN}" = "buildup" ]]
  then
    docker-compose -f "${CMPSFLDIR}/${CMPSEFILE}" up --build -d
    sleep 10
    testHZcast
  elif [[ "${OPTN}" = "cleandown" ]]
  then
    docker-compose -f "${CMPSFLDIR}/${CMPSEFILE}" down -v
  elif [[ "${OPTN}" = "exec" ]]
  then
    exec docker-compose -f "${CMPSFLDIR}/${CMPSEFILE}" exec "${SRVC}" "${SHELL}"
  elif [[ "${OPTN}" = "test" ]]
  then
    testHZcast
  else
    docker-compose -f "${CMPSFLDIR}/${CMPSEFILE}" "${OPTN}"
  fi

}

main 2>&1
