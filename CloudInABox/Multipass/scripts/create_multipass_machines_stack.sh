#! /bin/bash

OPTN=${1}
OPTNTST=${2}
NUMOPTNMX=3
DLYTOMSTL=5
INSTCFDIR='.'
INSTCFILE='instances.list'
declare -A instancesDict
RQRDCMNDS="awk
           cat
           date
           grep
           multipass"

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

  cat <<EOF
 Usage: $(basename $0) < create|start|stop|show|
                         test [ping|goss|docker|cassandra|elasticsearch|
                               kafka|spark|monitoror]
                        |delete|cleandelete >"
EOF
  exit 0

}

parseArgs() {

  if [[ $# -gt ${NUMOPTNMX} ]]
  then
    printUsage
  fi

  if [[ "${OPTN}" != "create" ]] && \
     [[ "${OPTN}" != "start" ]] && \
     [[ "${OPTN}" != "stop" ]] && \
     [[ "${OPTN}" != "show" ]] && \
     [[ "${OPTN}" != "test" ]] && \
     [[ "${OPTN}" != "delete" ]]

  then
    printUsage
  fi

  if [[ "${OPTN}" = "create" ]]
  then
    if [[ ! -f "${INSTCFDIR}/${INSTCFILE}" ]]
    then
      echo " Error: instances listing file ${INSTCFDIR}/${INSTCFILE} not found, exiting ..."
      exit -1
    fi
  fi

}

showMLPSStack() {

  if ! multipass ls
  then
    exitOnErr "multipass ls failed"
  fi

}

startMLPSStack() {

  if ! multipass start --all
  then
    exitOnErr "multipass start --all failed"
  fi

}

stopMLPSStack() {

  if ! multipass stop --all
  then
    exitOnErr "multipass stop --all failed"
  fi

}

deleteMLPSStack() {

  if ! multipass delete --all -p
  then
    exitOnErr "multipass delete --all -p failed"
  fi

}

setupStack() {

  if [[ "${1}" = "goss" ]] || \
     [[ "${1}" = "docker" ]]
  then
    for i in $(showMLPSStack | grep -v Name | awk '{print $3}')
    do
      if ! multipass transfer 
    done
  else
    for i in $(showMLPSStack | grep -v Name | grep "${1}" | awk '{print $3}')
    do

    done
  fi

}

testMLPSRun() {

  if [[ ! -z "${1}" ]] && \
     [[ "${1}" != "ping" ]] && \
     [[ "${1}" != "goss" ]] && \
     [[ "${1}" != "docker" ]] && \
     [[ "${1}" != "cassandra" ]] && \
     [[ "${1}" != "elasticsearch" ]] && \
     [[ "${1}" != "kafka" ]] && \
     [[ "${1}" != "monitoror" ]] && \
     [[ "${1}" != "spark" ]]

  then
    printUsage
  fi

  if [[ -z "${1}" ]] || [[ "${1}" = "ping" ]]
  then
    pingNodes
  elif [[ "${1}" = "goss" ]]          || \
       [[ "${1}" = "docker" ]]        || \
       [[ "${1}" = "cassandra" ]]     || \
       [[ "${1}" = "elasticsearch" ]] || \
       [[ "${1}" = "kafka" ]]         || \
       [[ "${1}" = "monitoror" ]]     || \
       [[ "${1}" = "spark" ]]
  then
    setupStack "${1}"
  fi

}

showAndTest() {

  showMLPStack
  sleep "${DLYTOMSTL}"
  echo
  testMLPSRun "${1}"

}

main() {

  parseArgs

  preReq

  if [[ "${OPTN}" = "create" ]]
  then
    showAndTest "${OPTNTST}"
  elif [[ "${OPTN}" = "start" ]]
  then
    startMLPStack
    showAndTest "${OPTNTST}"
  elif [[ "${OPTN}" = "stop" ]]
  then
    stopMLPStack
    showMLPStack
  elif [[ "${OPTN}" = "delete" ]]
  then
    deleteMLPStack
    showMLPStack
  elif [[ "${OPTN}" = "test" ]]
  then
    showAndTest "${OPTNTST}"
  elif [[ "${OPTN}" = "show" ]]
  then
    showMLPStack
  fi

}

main 2>&1
