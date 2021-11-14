#! /bin/bash

OPTN=${1}
OPTNTST=${2}
NUMOPTNMX=3
DLYTOMSTL=5
CMPSFLDIR='.'
ANSBLEDIR='../../Common/ansible'
ANSBLEHIN='hosts'
MRVMCTRKY='cluster-key'
FTLSCFGINFL='footloose.cfg'
FTLSCFGOUFL='footloose.yaml'
ASBLCMTEST='ansible_test.yml'
ASBLCMCSRV='ansible_cnslsrvr.yml'
ASBLCMCLNT='ansible_cnslclnt.yml'
ASBLCMCTPL='ansible_cnsltmplt.yml'
ASBLCMHSUI='ansible_hashiui.yml'
ASBLCMCESM='ansible_cnslesm.yml'
ASBLCMDGOS='ansible_goss.yml'
ASBLCMDCKR='ansible_docker.yml'
ASBLCMDCAS='ansible_cassandra.yml'
ASBLCMDELS='ansible_elasticsearch.yml'
ASBLCMDKAF='ansible_kafka.yml'
ASBLCMDSPR='ansible_spark.yml'
ASBLCMDMTR='ansible_monitoror.yml'
ASBLCMPVGL='ansible_vigil.yml'
DCKRCMPMTR='monitoror.yml'
SRVCNFGMTR='../configs/monitoror/config.json'
SRVCNFGVGL='../configs/vigil/config.cfg'
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
    exit 1
  fi

  for c in ${RQRDCMNDS}
  do
    if ! command -v "${c}" > /dev/null 2>&1
    then
      echo " Error: required command ${c} not found, exiting ..."
      exit 1
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
 Usage: $(basename "${0}")
   < lint   - run static analysis on Dockerfiles and Shellscripts |
     create - create microvm stack |
     start - start microvm stack |
     stop - stop microvm stack |
     show - dump info about the created microvm stack |
     test - run specified ansible role to configure the stack,
            valid roles are (ping is default if nothing mentioned):
            [[ping]|goss|consulserver|consulclient|
             consulesm|hashiui|consultemplate|docker|
             cassandra|elasticsearch|kafka|spark|
             monitoror|vigil] |
     delete - delete everything created >
EOF
  exit 0

}

parseArgs() {

  if [[ $# -gt ${NUMOPTNMX} ]]
  then
    printUsage
  fi

  if [[ "${OPTN}" != "lint" ]] && \
     [[ "${OPTN}" != "create" ]] && \
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

preLint() {

  find . -maxdepth 1 -name 'Dockerfile*' -exec cat {} \; | \
    docker run --rm -i hadolint/hadolint 2>&1
  echo
  docker run --rm -v "${PWD}:/mnt" koalaman/shellcheck -- *.sh 2>&1

}

renderFTLSCnfg() {

  if [[ ! -f "${FTLSCFGINFL}" ]]
  then
    echo " Error: required ${FTLSCFGINFL} not found, exiting ..."
    exit 1
  fi

  tee "${FTLSCFGOUFL}" <<EOF
cluster:
  name: cluster
  privateKey: cluster-key
machines:
EOF

  while read -r Name Count Image Kernel Cpu Memory Disk Networks Ports
  do
    if echo "${Name}"|grep '^ *#' > /dev/null 2>&1 || echo "${Name}"|grep '^ *$' > /dev/null
    then
      continue
    fi
    tee -a "${FTLSCFGOUFL}" <<EOF
- count: ${Count}
  spec:
    image: ${Image}
    name: ${Name}%d
    hostname: ${Name}%d
    backend: ignite
    ignite:
      cpus: ${Cpu}
      memory: ${Memory}
      diskSize: ${Disk}
      kernel: "${Kernel}"
EOF
    tee -a "${FTLSCFGOUFL}" <<EOF
    portMappings:
EOF
    for p in ${Ports//,/ }
    do
      if echo "${p}" | grep ':' > /dev/null 2>&1
      then
        hstprt="$(echo "${p}" | awk -F':' '{print $1}')"
        ctrprt="$(echo "${p}" | awk -F':' '{print $2}')"
        tee -a "${FTLSCFGOUFL}" <<EOF
    - containerPort: ${ctrprt}
      hostPort: ${hstprt}
EOF
      else
        tee -a "${FTLSCFGOUFL}" <<EOF
    - containerPort: ${p}
EOF
      fi
      done
  done < "${FTLSCFGINFL}"

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

  local vmign
  local vmign=$(ignite vm|grep -v VM)
  for m in $(echo "${vmign}" | awk '{print $NF}' | sed -e 's/cluster\-//' -e 's/[0-9]\{1,\}//' | sort -u)
  do
    echo -e "[${m}]\n$(echo "${vmign}" | grep "${m}" \
       | awk '{print $(NF-1)}')\n"
  done | tee ${ANSBLEDIR}/${ANSBLEHIN}

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

  if [[ -n "${1}" ]] && \
     [[ "${1}" != "ping" ]] && \
     [[ "${1}" != "consulserver" ]] && \
     [[ "${1}" != "consulclient" ]] && \
     [[ "${1}" != "consultemplate" ]] && \
     [[ "${1}" != "consulesm" ]] && \
     [[ "${1}" != "hashiui" ]] && \
     [[ "${1}" != "goss" ]] && \
     [[ "${1}" != "docker" ]] && \
     [[ "${1}" != "cassandra" ]] && \
     [[ "${1}" != "elasticsearch" ]] && \
     [[ "${1}" != "kafka" ]] && \
     [[ "${1}" != "monitoror" ]] && \
     [[ "${1}" != "vigil" ]] && \
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

  elif [[ "${1}" = "consulserver" ]]
  then
    if ! docker-compose -f "${CMPSFLDIR}/${ASBLCMCSRV}" up --build
    then
      exitOnErr "docker-compose -f ${CMPSFLDIR}/${ASBLCMCSRV} up --build failed"
    fi

  elif [[ "${1}" = "consulclient" ]]
  then
    if ! docker-compose -f "${CMPSFLDIR}/${ASBLCMCLNT}" up --build
    then
      exitOnErr "docker-compose -f ${CMPSFLDIR}/${ASBLCMCLNT} up --build failed"
    fi

  elif [[ "${1}" = "consulesm" ]]
  then
    if ! docker-compose -f "${CMPSFLDIR}/${ASBLCMCESM}" up --build
    then
      exitOnErr "docker-compose -f ${CMPSFLDIR}/${ASBLCMCESM} up --build failed"
    fi

  elif [[ "${1}" = "hashiui" ]]
  then
    if ! docker-compose -f "${CMPSFLDIR}/${ASBLCMHSUI}" up --build
    then
      exitOnErr "docker-compose -f ${CMPSFLDIR}/${ASBLCMHSUI} up --build failed"
    fi

  elif [[ "${1}" = "consultemplate" ]]
  then
    if ! docker-compose -f "${CMPSFLDIR}/${ASBLCMCTPL}" up --build
    then
      exitOnErr "docker-compose -f ${CMPSFLDIR}/${ASBLCMCTPL} up --build failed"
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

  elif [[ "${1}" = "vigil" ]]
  then
    renderVGLCnfg
    if ! docker-compose -f "${CMPSFLDIR}/${ASBLCMPVGL}" up --build
    then
      exitOnErr "docker-compose -f ${CMPSFLDIR}/${ASBLCMPVGL} up --build failed"
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

  if [[ "${OPTN}" = "lint" ]]
  then
    preLint
  elif [[ "${OPTN}" = "create" ]]
  then
    renderFTLSCnfg
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
    showMRVMStack
    rm -f "${CMPSFLDIR}/${MRVMCTRKY}" "${CMPSFLDIR}/${MRVMCTRKY}.pub" \
          "${ANSBLEDIR}/${MRVMCTRKY}" "${ANSBLEDIR}/${ANSBLEHIN}" \
          "${FTLSCFGOUFL}"
  elif [[ "${OPTN}" = "test" ]]
  then
    showAndTest "${OPTNTST}"
  elif [[ "${OPTN}" = "show" ]]
  then
    showMRVMStack
  fi

}

main 2>&1
