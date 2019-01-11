#! /bin/bash

OPTN=${1}
NUMOPTNMX=2
CMPSFLDIR='.'
CMPSEFILE='chef_tstsrvrs_stack.yml'
rqrdcmnds="terraform
           docker-compose"

preReq() {

  for c in ${rqrdcmnds}
  do
    if ! command -v "${c}" > /dev/null 2>&1
    then
      echo " Error: required command ${c} not found, exiting ..."
      exit -1
    fi
  done

}

printUsage() {

  echo " Usage: $(basename $0) < up|buildup|ps|logs|down|cleandown|chefrun >"
  exit 0

}

chefRun() {

  local TSTSRVRS=$(docker ps -f name=tstsrvr* -q|xargs -I % docker inspect --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' %|xargs|sed 's/ /,/g')

  docker exec -it chefwrkstn chef-run --user root -i /etc/ssl/certs/test_servers_pkey ${TSTSRVRS} package curl action=install

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
     [[ "${OPTN}" != "chefrun" ]]
  then
    printUsage
  fi

}

main() {

  parseArgs

  preReq

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
    sleep 10
    chefRun
  elif [[ "${OPTN}" = "buildup" ]]
  then
    docker-compose -f "${CMPSFLDIR}/${CMPSEFILE}" up --build -d
  elif [[ "${OPTN}" = "cleandown" ]]
  then
    docker-compose -f "${CMPSFLDIR}/${CMPSEFILE}" down -v
  elif [[ "${OPTN}" = "chefrun" ]]
  then
    chefRun
  else
    docker-compose -f "${CMPSFLDIR}/${CMPSEFILE}" "${OPTN}"
  fi

}

main 2>&1
