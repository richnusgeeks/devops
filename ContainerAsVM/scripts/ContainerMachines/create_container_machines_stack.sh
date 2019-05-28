#! /bin/bash

OPTN=${1}
NUMOPTNMX=2
DLYTOMSTL=5
CMPSFLDIR='.'
ANSBLEDIR='../../ansible'
ASBLCMPSRN='ansible_run.yml'
FTLSCMPSCT='footloose_create.yml'
FTLSCMPSDL='footloose_delete.yml'
RQRDCMNDS="awk
           chmod
           cp
           docker
           docker-compose
           grep
           sudo"

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

exitOnErr() {

  echo " Error: <$(date)> $1, exiting ..."
  exit 1

}

printUsage() {

  echo " Usage: $(basename $0) < create|buildcreate|show|test|delete|cleandelete >"
  exit 0

}

parseArgs() {

  if [[ $# -gt ${NUMOPTNMX} ]]
  then
    printUsage
  fi

  if [[ "${OPTN}" != "create" ]] && \
     [[ "${OPTN}" != "buildcreate" ]] && \
     [[ "${OPTN}" != "show" ]] && \
     [[ "${OPTN}" != "test" ]] && \
     [[ "${OPTN}" != "delete" ]] &&
     [[ "${OPTN}" != "cleandelete" ]]

  then
    printUsage
  fi

}

showFTLStack() {

  if ! docker run -it --rm -v /var/run/docker.sock:/var/run/docker.sock \
                           -v $(pwd)/footloose.yaml:/tmp/footloose.yaml \
            footloose show -c /tmp/footloose.yaml
  then
    exitOnErr 'docker run footloose show failed'
  fi

}

createASBLInv() {

  if ! docker run -it --rm -v /var/run/docker.sock:/var/run/docker.sock \
                          -v $(pwd)/footloose.yaml:/tmp/footloose.yaml \
           footloose show -c /tmp/footloose.yaml | \
       grep -v NAME | awk '{print $4}'> "${ANSBLEDIR}/hosts"
  then
    exitOnErr "docker run footloose show > ${ANSBLEDIR}/hosts failed"
  fi

}

copyPrivKey() {

  if ! sudo cp $(docker volume inspect $(docker volume ls|grep -v DRIVER|grep footloose-data|awk '{print $NF}')|grep -i mountpoint|awk -F'"' '{print $(NF-1)}')/cluster-key "${ANSBLEDIR}"
  then
    exitOnErr "cluster-key copy from docker volume to ${ANSBLEDIR} failed"
  else
    if ! sudo chmod +r "${ANSBLEDIR}/cluster-key"
    then
      exitOnErr "chmod +r ${ANSBLEDIR}/cluster-key failed"
    fi
  fi

}

testASBLRun() {

  createASBLInv
  copyPrivKey

  if ! docker run -it --rm --entrypoint=ansible -v "$(pwd)/${ANSBLEDIR}":/etc/ansible ansible all -m ping
  then
    exitOnErr 'docker run ansible ping failed'
  fi

}

showAndTest() {

  showFTLStack
  sleep "${DLYTOMSTL}"
  testASBLRun

}

main() {

  parseArgs

  preReq

  if [[ "${OPTN}" = "create" ]]
  then
    docker-compose -f "${CMPSFLDIR}/${FTLSCMPSCT}" up
    showAndTest
  elif [[ "${OPTN}" = "buildcreate" ]]
  then
    docker-compose -f "${CMPSFLDIR}/${FTLSCMPSCT}" up --build
    showAndTest
  elif [[ "${OPTN}" = "delete" ]]
  then
    docker-compose -f "${CMPSFLDIR}/${FTLSCMPSDL}" up
    docker-compose -f "${CMPSFLDIR}/${FTLSCMPSDL}" down
  elif [[ "${OPTN}" = "cleandelete" ]]
  then
    docker-compose -f "${CMPSFLDIR}/${FTLSCMPSDL}" up
    docker-compose -f "${CMPSFLDIR}/${FTLSCMPSDL}" down -v
  elif [[ "${OPTN}" = "test" ]]
  then
    showAndTest
  elif [[ "${OPTN}" = "show" ]]
  then
    showFTLStack
  fi

}

main 2>&1
