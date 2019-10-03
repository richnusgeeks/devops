#! /bin/bash
set -uo pipefail

DCKRFL="${DOCKER_FILE:-Dockerfile}"
DCKRIMG="${DOCKER_IMAGE:-none}"
CSTCNFG="${CST_CONFIG:-config.yaml}"
LBLVNDR="${LABEL_VENDOR:-richnusgeeks}"
SCHMVER='2.0.0'
RQRDCMNDS="awk
           cat
           container-structure-test
           echo
           grep
           sed
           tee
           xargs"

exitOnErr() {

  echo " <$(date)> Error: ${1}, exiting ..."
  exit 1

}

preReq() {

  for c in ${RQRDCMNDS}
  do
    if ! command -v "${c}" > /dev/null 2>&1
    then
      exitOnErr "required command ${c} not found, exiting ..."
    fi
  done

}

crteCstCnfg() {

  if [[ ! -f "${DCKRFL}" ]]
  then
    exitOnErr "required ${DCKRFL} not found"
  fi

  local cmd=$(grep CMD "${DCKRFL}"|sed 's/^ *CMD *//')

  local wrkdir=$(grep WORKDIR "${DCKRFL}"|sed 's/^ *WORKDIR *//')

  local expsdprts=$(grep EXPOSE "${DCKRFL}"|xargs|sed 's/^ *EXPOSE *//g'|sed -e 's/ \{1,\}/,/2g' -e 's/,/","/g' -e 's/^ */["/' -e 's/$/"]/')
  if [[ "${expsdprts}" = '[""]' ]]
  then
    expsdprts='["-1"]'
  fi
  
  local entrypoint=$(grep ENTRYPOINT "${DCKRFL}"|sed 's/^ *ENTRYPOINT *//')

  cat <<EOF | tee "${CSTCNFG}"
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
    - key: 'com.richnusgeeks.vendor'
      value: '${LBLVNDR}'

  cmd: ${cmd}
  exposedPorts: ${expsdprts}
  entrypoint: ${entrypoint}
  workdir: ${wrkdir}
EOF

}

runCntnrStst() {

  container-structure-test test --image "${DCKRIMG}" \
                                     --config "${CSTCNFG}"
  rm -f "${CSTCNFG}"

}

main() {

  preReq
  crteCstCnfg
  runCntnrStst  

}

main 2>&1
