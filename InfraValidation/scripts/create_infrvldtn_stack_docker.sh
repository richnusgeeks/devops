#! /bin/bash

OPTN=${1}
SRVC=${2}
SHELL=${3}
NUMOPTNMX=4
CMPSFLDIR='.'
CMPSEFILE='infrvldtn_stack.yml'
RQRDCMNDS="terraform
           docker
           docker-compose"
SSHPRVKEY='/etc/ssl/certs/test_servers_pkey/test'


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

  echo " Usage: $(basename $0) < up|buildup|ps|exec <name> <cmnd>|logs|down|cleandown|inspecrun >"
  exit 0

}

inspecRun() {

#  local TSTSRVRS=$(docker ps -f name=tstsrvr* -q|xargs -I % docker inspect --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' %|xargs|sed 's/ /,/g')
  local TSTSRVRS=$(docker ps -f name=tstsrvr*|grep -iv name|awk '{print $NF}'|xargs|sed 's/ /,/g')

#  docker exec -it chefwrkstn chef-run --user root -i "${SSHPRVKEY}" \
#    "${TSTSRVRS}" package monit action=install

#  sleep 5

  for s in $(echo ${TSTSRVRS}|sed 's/,/ /g')
  do
    echo
    echo " docker container => ${s}"
    docker exec -it inspecat inspec detect -t "ssh://root@${s}" \
      -i "${SSHPRVKEY}" --chef-license=accept-silent
  done

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
     [[ "${OPTN}" != "inspecrun" ]] &&
     [[ "${OPTN}" != "exec" ]]
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
    inspecRun
  elif [[ "${OPTN}" = "buildup" ]]
  then
    docker-compose -f "${CMPSFLDIR}/${CMPSEFILE}" up --build -d
    sleep 10
    inspecRun
  elif [[ "${OPTN}" = "cleandown" ]]
  then
    docker-compose -f "${CMPSFLDIR}/${CMPSEFILE}" down -v
  elif [[ "${OPTN}" = "inspecrun" ]]
  then
    inspecRun
  elif [[ "${OPTN}" = "exec" ]]
  then
    exec docker-compose -f "${CMPSFLDIR}/${CMPSEFILE}" exec "${SRVC}" "${SHELL}"
  else
    docker-compose -f "${CMPSFLDIR}/${CMPSEFILE}" "${OPTN}"
  fi

}

main 2>&1
