#! /bin/bash
set -uo pipefail

TRACE="${TRACE_FLAG:-0}"
DEBUG="${DEBUG_FLAG:-0}"
DCKRFL="${DOCKER_FILE:-Dockerfile}"
DCKRIMG="${DOCKER_IMAGE:-none}"
CSTRPRT="\n=== CSTestRun: Dockerfile:${DCKRFL} , Image:${DCKRIMG} ==="
CSTCNFG='config.yaml'
CSTSLKURL="${SLACK_URL:-none}"
LBLVNDRK="${LABEL_VENDORK:-com.richnusgeeks.vendor}"
LBLVNDRV="${LABEL_VENDORV:-richnusgeeks}"
LBLCTGRK="${LABEL_CATEGORYK:-com.richnusgeeks.category}"
LBLCTGRV="${LABEL_CATEGORYV:-none}"
TINIVER="${TINI_VERSION:-0.18.0}"
SCHMVER='2.0.0'
RQRDCMNDS="awk
           cat
           container-structure-test
	   curl
           date
           docker
           echo
           grep
           sed
           tee
           xargs"
ONBLDCMDF=false
ONBLDWRKF=false
ONBLDEXPF=false
ONBLDENTF=false
RETSTATUS=0

exitOnErr() {

  echo " <$(date)> Error: ${1}, exiting ..."
  exit 1

}

prntMsg() {

  local msg=$1
  local clr=$2

  if [[ "${clr}" = "red" ]]
  then
    echo -e "\033[31;49;10m${msg}\033[m"
  elif [[ "${clr}" = "green" ]]
  then
    echo -e "\033[32;49;10m${msg}\033[m"
  elif [[ "${clr}" = "yellow" ]]
  then
    echo -e "\033[33;49;10m${msg}\033[m"
  elif [[ "${clr}" = "blue" ]]
  then
    echo -e "\033[34;49;10m${msg}\033[m"
  fi

}

preReq() {

  if [[ ${TRACE} -eq 1 ]]
  then
    set -x
  fi

  for c in ${RQRDCMNDS}
  do
    if ! command -v "${c}" > /dev/null 2>&1
    then
      exitOnErr "required command ${c} not found, exiting ..."
    fi
  done

  if [[ ${DEBUG} -ne 0 ]] && [[ ${DEBUG} -ne 1 ]]
  then
    exitOnErr 'DEBUG_FLAG should be either 0 or 1'
  fi

  if [[ ! -f "${DCKRFL}" ]]
  then
    exitOnErr "required ${DCKRFL} not found"
  fi

}

testADD() {

  echo
  echo '=== RUN: Dockerfile Instruction Test: ADD not used'
  local addindckrfle=$(grep -E '^ *(ONBUILD)? *ADD' "${DCKRFL}")
  if [[ ! -z "${addindckrfle}" ]]
  then
    prntMsg '--- FAIL' red
    prntMsg "Error: ${addindckrfle}" yellow
    RETSTATUS=1
  else
    prntMsg '--- PASS' green
  fi

  echo
  echo '=== RUN: Dockerimage Instruction Test: ADD not used'
  local addinhist=$(docker history --format "{{ .CreatedBy }}" --no-trunc "${DCKRIMG}"|sed '$d'|grep ADD)
  if [[ ! -z "${addinhist}" ]]
  then
    prntMsg '--- FAIL' red
    prntMsg "Error: ${addinhist}" yellow
    RETSTATUS=1
  else
    prntMsg '--- PASS' green
  fi

}

testONBUILD() {

  local onbldcmd=$(grep -E '^ *ONBUILD +CMD' "${DCKRFL}"|tail -1)
  if [[ ! -z "${onbldcmd}" ]]
  then
    ONBLDCMDF=true
    echo
    echo '=== RUN: Dockerfile Instruction Test: ONBUILD CMD array form'
    if ! echo ${onbldcmd} | grep '[][]' > /dev/null 2>&1
    then
      prntMsg '--- FAIL' red
      prntMsg "Error: ${onbldcmd}" yellow
      RETSTATUS=1
    else
      prntMsg '--- PASS' green
    fi
  fi

  local onbldexpsdprts=$(grep -E '^ *ONBUILD +EXPOSE' "${DCKRFL}"|tail -1)
  if [[ ! -z "${onbldexpsdprts}" ]]
  then
    ONBLDEXPF=true
    echo
    echo '=== RUN: Dockerfile Instruction Test: ONBUILD EXPOSE presence'
    prntMsg '--- PASS' green
  fi

  local onbldentrypoint=$(grep -E '^ *ONBUILD +ENTRYPOINT' "${DCKRFL}"|tail -1)
  if [[ ! -z "${onbldentrypoint}" ]]
  then
    ONBLDENTF=true
    echo
    echo '=== RUN: Dockerfile Instruction Test: ONBUILD ENTRYPOINT array form tini'
    if ! echo ${onbldentrypoint} | grep '\["/sbin/tini", *"--"\]' > /dev/null 2>&1
    then
      prntMsg '--- FAIL' red
      prntMsg "Error: ${onbldentrypoint}" yellow
      RETSTATUS=1
    else
      prntMsg '--- PASS' green
    fi
  fi

}

crteCstCnfg() {

  local cmd=$(grep '^ *CMD' "${DCKRFL}"|sed 's/^ *CMD *//')
  if ! echo ${cmd} | grep '[][]' > /dev/null 2>&1
  then
    if [[ ! -z "${cmd}" ]]
    then
      cmd=\[\'${cmd}\'\]
    else
      cmd=\[\'/dev/null\'\]
    fi
  else
    cmd=${cmd}
  fi

  local wrkdir=$(grep '^ *WORKDIR' "${DCKRFL}"|tail -1|sed 's/^ *WORKDIR *//')
  if [[ -z "${wrkdir}" ]]
  then
    wrkdir='/dev/null'
  fi

  local expsdprts=$(grep '^ *EXPOSE' "${DCKRFL}"|sed 's/^ *EXPOSE *//g'|xargs|sed -e 's/ \{1,\}/,/g' -e 's/,/","/g' -e 's/^ */["/' -e 's/$/"]/')
  if [[ "${expsdprts}" = '[""]' ]]
  then
    expsdprts='["-1"]'
  fi
  
#  local entrypoint=$(grep '^ *ENTRYPOINT' "${DCKRFL}"|sed 's/^ *ENTRYPOINT *//')
#  if [[ -z "${entrypoint}" ]]
#  then
    entrypoint='["/sbin/tini","--"]'
#  fi

  local category=$(grep "${LBLCTGRK}" "${DCKRFL}"|grep -v '^ *#'|awk -F"=" '{print $NF}'|sed -e 's/"//g' -e "s/'//")
  if [[ ! -z "${category}" ]]
  then
    if [[ "${category}" = 'base' ]] || [[ "${category}" = 'utility' ]] || [[ "${category}" = 'service' ]]
    then
      LBLCTGRV="${category}"
    fi
  fi

  cat <<EOF > "/tmp/${CSTCNFG}"
schemaVersion: ${SCHMVER}

commandTests:
  - name: "dump tini version"
    command: "/sbin/tini"
    args: ["--version"]

fileExistenceTests:
  - name: "tini existence"
    path: "/sbin/tini"
    shouldExist: true

metadataTest:
  labels:
    - key: '${LBLVNDRK}'
      value: '${LBLVNDRV}'
    - key: '${LBLCTGRK}'
      value: '${LBLCTGRV}'

  cmd: ${cmd}
  exposedPorts: ${expsdprts}
  entrypoint: ${entrypoint}
  workdir: ${wrkdir}
EOF

  if [[ "${category}" = 'base' ]]
  then
    if ${ONBLDCMDF}
    then
      sed -i '/^ *cmd/d' "/tmp/${CSTCNFG}"
    fi

    if ${ONBLDWRKF}
    then
      sed -i '/^ *workdir/d' "/tmp/${CSTCNFG}"
    fi

    if ${ONBLDEXPF}
    then
      sed -i '/^ *exposedPorts/d' "/tmp/${CSTCNFG}"
    fi

    if ${ONBLDENTF}
    then
      sed -i '/^ *entrypoint/d' "/tmp/${CSTCNFG}"
    fi
  fi

  if [[ "${category}" = 'base' ]] || [[ "${category}" = 'utility' ]]
  then
    if ! sed -i '/^ *exposedPorts/d' "/tmp/${CSTCNFG}"
    then
      exitOnErr "sed -i '/^ *exposedPorts/d' /tmp/${CSTCNFG}"
    fi
  fi

  if [[ ${DEBUG} -eq 1 ]]
  then
    echo
    cat "/tmp/${CSTCNFG}"
  fi

}

runCntnrStst() {

  echo -e "${CSTRPRT}"
  testADD
  testONBUILD
  crteCstCnfg

  local cstrun=$(container-structure-test test --image "${DCKRIMG}" --config "/tmp/${CSTCNFG}" 2>&1)
  if echo "${cstrun}" | grep FAIL > /dev/null 2>&1
  then
    RETSTATUS=1
  fi
  echo "${cstrun}"

  if [[ "${CSTSLKURL}" != "none" ]]
  then
    local icon_emoji=':white_check_mark:'
    if [[ ${RETSTATUS} -eq 1 ]]
    then
      icon_emoji=':x:'
    fi

    cstrprt="$(echo "${cstrprt}\n\n"|sed 's/\[[0-9;]\{1,\}m//g')"

    if ! curl -sS -X POST -H 'Content-type: application/json' \
	      --data "{\"text\":\"$cstrprt\",\"icon_emoji\":\"$icon_emoji\"}" \
	   "${CSTSLKURL}"
    then
      RETSTATUS=1
    fi
  fi

  exit ${RETSTATUS}

}

main() {

  preReq
  runCntnrStst

}

main 2>&1
