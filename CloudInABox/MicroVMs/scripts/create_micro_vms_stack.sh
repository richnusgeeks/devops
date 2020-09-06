#! /bin/bash

OPTN=${1}
OPTNTST=${2}
NUMOPTNMX=3
DLYTOMSTL=5
CMPSFLDIR='.'
ANSBLEDIR='../ansible'
ANSBLEHIN='hosts'
MRVMCTRKY='cluster-key'
ASBLCMTEST='ansible_test.yml'
ASBLCMDGOS='ansible_goss.yml'
ASBLCMDCKR='ansible_docker.yml'
ASBLCMDCAS='ansible_cassandra.yml'
ASBLCMDELS='ansible_elasticsearch.yml'
ASBLCMDKAF='ansible_kafka.yml'
ASBLCMDMTR='ansible_monitoror.yml'
ASBLCMDSPR='ansible_spark.yml'
DCKRCMPMTR='monitoror.yml'
RQRDCMNDS="awk
           cat
           date
           docker-compose
           footloose
           grep
           ignite
	   rm
           tee
           uname"

preReq() {

  if [ "${EUID}" -ne 0 ]
  then
    echo " Error: this script needs superuser rights, exiting ..."
    exit -1
  fi

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

exitOnErr() {

  echo " Error: <$(date)> $1, exiting ..."
  exit 1

}

printUsage() {

  cat <<EOF
 Usage: $(basename $0) < create|start|stop|show|
                         test [ping|goss|docker|cassandra|elasticsearch|
                               kafka|spark|monitoror]
                        |delete >"
EOF
  exit 0

}

parseArgs() {

  if [[ $# -gt ${NUMOPTNMX} ]]
  then
    printUsage
  fi

  if [[ "${OPTN}" != "create" ]] && \
     [[ "${OPTN}" != "buildcreate" ]] && \
     [[ "${OPTN}" != "start" ]] && \
     [[ "${OPTN}" != "stop" ]] && \
     [[ "${OPTN}" != "show" ]] && \
     [[ "${OPTN}" != "test" ]] && \
     [[ "${OPTN}" != "delete" ]]

  then
    printUsage
  fi

}

showMRVMStack() {

  if ! footloose show
  then
    exitOnErr 'footloose show failed'
  else
    echo
    if ! ignite vm
    then
      exitOnErr 'ignite vm failed'
    fi
  fi

}

createASBLInv() {

  ignite ps|grep -v VM|awk -F ' +' '{print $5}'|awk '{print $2}'| \
    tee ${ANSBLEDIR}/${ANSBLEHIN} > /dev/null

}

copyPrivKey() {

  if ! cp "${CMPSFLDIR}/${MRVMCTRKY}" "${ANSBLEDIR}"
  then
    exitOnErr "cp ${CMPSFLDIR}/${MRVMCTRKY} ${ANSBLEDIR} failed"
  else
    if ! chmod '+r' "${ANSBLEDIR}/${MRVMCTRKY}"
    then
      exitOnErr "chmod +r ${ANSBLEDIR}/${MRVMCTRKY} failed"
    fi
  fi

}

testASBLRun() {

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

  createASBLInv
  copyPrivKey

  if [[ -z "${1}" ]] || [[ "${1}" = "ping" ]]
  then
    if ! docker-compose -f "${CMPSFLDIR}/${ASBLCMTEST}" up --build
    then
      exitOnErr "docker-compose -f "${CMPSFLDIR}/${ASBLCMTEST}" up --build failed"
    fi

  elif [[ "${1}" = "goss" ]]
  then
    if ! docker-compose -f "${CMPSFLDIR}/${ASBLCMDGOS}" up --build
    then
      exitOnErr "docker-compose -f "${CMPSFLDIR}/${ASBLCMDGOS}" up --build failed"
    fi

  elif [[ "${1}" = "docker" ]]
  then
    if ! docker-compose -f "${CMPSFLDIR}/${ASBLCMDCKR}" up --build
    then
      exitOnErr "docker-compose -f "${CMPSFLDIR}/${ASBLCMDCKR}" up --build failed"
    fi

  elif [[ "${1}" = "cassandra" ]]
  then
    if ! docker-compose -f "${CMPSFLDIR}/${ASBLCMDCAS}" up --build
    then
      exitOnErr "docker-compose -f "${CMPSFLDIR}/${ASBLCMDCAS}" up --build failed"
    fi
  elif [[ "${1}" = "elasticsearch" ]]
  then
    if ! docker-compose -f "${CMPSFLDIR}/${ASBLCMDELS}" up --build
    then
      exitOnErr "docker-compose -f "${CMPSFLDIR}/${ASBLCMDELS}" up --build failed"
    fi
  elif [[ "${1}" = "kafka" ]]
  then
    if ! docker-compose -f "${CMPSFLDIR}/${ASBLCMDKAF}" up --build
    then
      exitOnErr "docker-compose -f "${CMPSFLDIR}/${ASBLCMDKAF}" up --build failed"
    fi
  elif [[ "${1}" = "monitoror" ]]
  then
    if ! docker-compose -f "${CMPSFLDIR}/${DCKRCMPMTR}" up -d
    then
      exitOnErr "docker-compose -f "${CMPSFLDIR}/${DCKRCMPMTR}" up -d failed"
    fi
  elif [[ "${1}" = "spark" ]]
  then
    if ! docker-compose -f "${CMPSFLDIR}/${ASBLCMDSPR}" up --build
    then
      exitOnErr "docker-compose -f "${CMPSFLDIR}/${ASBLCMDSPR}" up --build failed"
    fi
  fi

}

showAndTest() {

  showMRVMStack
  sleep "${DLYTOMSTL}"
  echo
  testASBLRun "${1}"

}

main() {

  parseArgs

  preReq

  if [[ "${OPTN}" = "create" ]]
  then
    if ! footloose create
    then
      exitOnErr "footloose create failed"
    fi
    showAndTest "${OPTNTST}"
  elif [[ "${OPTN}" = "start" ]]
  then
    if ! footloose start
    then
      exitOnErr "footloose start failed"
    fi
    showAndTest "${OPTNTST}"
  elif [[ "${OPTN}" = "stop" ]]
  then
    if ! footloose stop
    then
      exitOnErr "footloose stop failed"
    fi
    showMRVMStack
  elif [[ "${OPTN}" = "delete" ]]
  then
    if ! footloose delete
    then
      exitOnErr "footloose delete failed"
    fi
    rm -f "${CMPSFLDIR}/${MRVMCTRKY}" "${CMPSFLDIR}/${MRVMCTRKY}.pub" \
	  "${ANSBLEDIR}/${MRVMCTRKY}" "${ANSBLEDIR}/${ANSBLEHIN}"
    showMRVMStack
  elif [[ "${OPTN}" = "test" ]]
  then
    showAndTest "${OPTNTST}"
  elif [[ "${OPTN}" = "show" ]]
  then
    showMRVMStack
  fi

}

main 2>&1
