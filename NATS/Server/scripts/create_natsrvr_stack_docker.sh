#! /bin/bash

OPTN=${1}
SRVC=${2}
SHELL=${3}
NUMOPTNMX=4
CMPSFLDIR='.'
CMPSEFILE='natsrvr_stack.yml'
CMPSOFILE='natsrvr_stack.yml.override'
RQRDCMNDS="awk
           cat
           docker
           docker-compose
           echo"

preReq() {

  for c in ${RQRDCMNDS}
  do
    if ! command -v "${c}" > /dev/null 2>&1
    then
      echo " Error: required command ${c} not found, exiting ..."
      exit -1
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

#  if [[ "${OPTN}" = "up" ]] || \
#     [[ "${OPTN}" = "buildup" ]]
#  then
#    terraform init
#    terraform apply -auto-approve
#  elif [[ "${OPTN}" = "down" ]] || \
#       [[ "${OPTN}" = "cleandown" ]]
#  then
#    terraform init
#    terraform destroy -auto-approve
#  fi

  if [[ "${OPTN}" = "up" ]]
  then
    docker-compose -f "${CMPSFLDIR}/${CMPSEFILE}"  \
                   -f "${CMPSFLDIR}/${CMPSOFILE}" "${OPTN}" -d
  elif [[ "${OPTN}" = "buildup" ]]
  then
    docker-compose -f "${CMPSFLDIR}/${CMPSEFILE}" \
                   -f "${CMPSFLDIR}/${CMPSOFILE}" up --build -d
  elif [[ "${OPTN}" = "cleandown" ]]
  then
    docker-compose -f "${CMPSFLDIR}/${CMPSEFILE}" \
                   -f "${CMPSFLDIR}/${CMPSOFILE}" down -v
  elif [[ "${OPTN}" = "exec" ]]
  then
    exec docker-compose -f "${CMPSFLDIR}/${CMPSEFILE}" \
                        -f "${CMPSFLDIR}/${CMPSOFILE}" exec "${SRVC}" "${SHELL}"
  else
    docker-compose -f "${CMPSFLDIR}/${CMPSEFILE}" \
                   -f "${CMPSFLDIR}/${CMPSOFILE}" "${OPTN}"
  fi

}

main 2>&1
