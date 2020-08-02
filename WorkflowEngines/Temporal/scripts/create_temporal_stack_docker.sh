#! /bin/bash

OPTN=${1}
SRVC=${2}
CMND=${3}
NUMOPTNMX=4
CMPSFLDIR='.'
CMPSEFILE='temporal_stack.yml'
RQRDCMNDS="docker
           docker-compose"
TMPRLFPRT=7233
TMPRLNWNM='temporal-demo'
TMPRLACPI='tlacptst:0.27.0'

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

testTmprlStck() {

  docker run --rm --network \
    "$(docker network ls|grep ${TMPRLNWNM}|awk '{print $1}')" \
    "${TMPRLACPI}" dockerize -wait-retry-interval 2s -timeout 30s -wait \
    "tcp://$(docker ps -f name=temporalfe* -q|xargs -I % docker inspect --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' %|xargs|sed 's/ /,/g'):${TMPRLFPRT}"

  echo
  docker-compose -f "${CMPSFLDIR}/${CMPSEFILE}" exec temporal-cli \
   tctl --ad temporalfe:${TMPRLFPRT} n l
  echo
  docker-compose -f "${CMPSFLDIR}/${CMPSEFILE}" exec temporal-cli \
   tctl --ad temporalfe:${TMPRLFPRT} adm cl d
  echo

}

main() {

  parseArgs

  preReq

  if [[ "${OPTN}" = "up" ]]
  then
    docker-compose -f "${CMPSFLDIR}/${CMPSEFILE}" "${OPTN}" -d
    testTmprlStck
  elif [[ "${OPTN}" = "test" ]]
  then
    testTmprlStck
  elif [[ "${OPTN}" = "buildup" ]]
  then
    docker-compose -f "${CMPSFLDIR}/${CMPSEFILE}" up --build -d
    testTmprlStck
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
