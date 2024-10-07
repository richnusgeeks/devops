#! /bin/bash

OPTN=${1}
NUMOPTNMX=2

printUsage() {

  cat <<EOF
 Usage: $(basename "${0}") <create|show|delete>
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
     [[ "${OPTN}" != "show"   ]] && \
     [[ "${OPTN}" != "delete" ]]
  then
    printUsage
  fi
}

main() {

  parseArgs
  rndrftlscnfg

  if [[ "${OPTN}" = "create" ]]
  then
    bootloose create -c /tmp/bootloose.yaml
    while true
    do
      sleep 10
    done
  elif [[ "${OPTN}" = "start" ]]
  then
    bootloose start -c /tmp/bootloose.yaml
  elif [[ "${OPTN}" = "stop" ]]
  then
    bootloose stop -c /tmp/bootloose.yaml
  elif [[ "${OPTN}" = "show" ]]
  then
    bootloose show -c /tmp/bootloose.yaml
  elif [[ "${OPTN}" = "delete" ]]
  then
    bootloose delete -c /tmp/bootloose.yaml
  fi

}

main 2>&1
