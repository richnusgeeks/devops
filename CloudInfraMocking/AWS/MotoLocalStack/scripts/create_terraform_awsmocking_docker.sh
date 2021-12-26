#! /bin/bash

OPTN=${1}
SRVC=${2}
CMND=${3}
NUMOPTNMX=4
CMPSFLDIR='.'
CMPSEFILE='terraform_awsmocking.yml'
RQRDCMNDS="awk
           cat
           docker
           docker-compose
           xargs"

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
  export TFRMTAG=1.0.2

}

preLint() {

  < "$(grep Dockerfile "${CMPSEFILE}"|awk '{print $NF}'|xargs)" \
    docker run --rm -i hadolint/hadolint 2>&1
  echo
  docker run --rm -v "${PWD}:/mnt" koalaman/shellcheck -- \
	 "$(basename "${0}")" 2>&1

}

printUsage() {

  echo " Usage: $(basename "${0}") <
                                     lint|up|buildup|ps
                                         |exec <name> <cmnd>
                                         |test <motoserver|localstack>
                                               <awssg|awsasg|awsalb>
                                         |logs|down|cleandown
                                   >"
  exit 0

}

parseArgs() {

  if [[ $# -gt ${NUMOPTNMX} ]]
  then
    printUsage
  fi

  if [[ "${OPTN}" != "lint" ]] && \
     [[ "${OPTN}" != "up" ]] && \
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

testAwsCli() {

  docker-compose -f "${CMPSFLDIR}/${CMPSEFILE}" exec motoserver \
    sh -c 'AWS_ACCESS_KEY_ID=foo AWS_SECRET_ACCESS_KEY=foo aws --endpoint-url=http://localhost:5000 --region=us-east-1 ec2 describe-instances'

}

testTrfrm() {

  docker-compose -f "${CMPSFLDIR}/${CMPSEFILE}" exec terraformws \
    sh -c "trfrmcktst ${SRVC} ${CMND}"

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
    testAwsCli
  elif [[ "${OPTN}" = "test" ]]
  then
    testAwsCli
    testTrfrm
  elif [[ "${OPTN}" = "buildup" ]]
  then
    docker-compose -f "${CMPSFLDIR}/${CMPSEFILE}" up --build -d
    testAwsCli
  elif [[ "${OPTN}" = "cleandown" ]]
  then
    docker-compose -f "${CMPSFLDIR}/${CMPSEFILE}" down -v
    docker system prune -f
  elif [[ "${OPTN}" = "exec" ]]
  then
    docker-compose -f "${CMPSFLDIR}/${CMPSEFILE}" exec "${SRVC}" "${CMND}"
  else
    docker-compose -f "${CMPSFLDIR}/${CMPSEFILE}" "${OPTN}"
  fi

}

main 2>&1
