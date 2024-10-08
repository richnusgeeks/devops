#! /bin/bash

OPTN=${1}
NUMOPTNMX=2
TRACE="${TRACE_FLAG:-0}"

printUsage() {

  cat <<EOF
 Usage: $(basename "${0}") <create|show|test|delete>
EOF
  exit 0

}

parseArgs() {

  if [[ ${TRACE} -eq 1 ]]
  then
    set -x
  fi

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
  elif [[ "${OPTN}" = "test" ]]
  then
    echo
    ftlshw=$(bootloose show -c /tmp/bootloose.yaml|grep '^cluster\-')
    for h in $(echo "${ftlshw}" | grep -v NAME | awk -F '  +' '{print $2}')
    do
      if ! ssh -oStrictHostKeychecking=no -oUserKnownHostsFile=/dev/null \
	       -oGlobalKnownHostsFile=/dev/null -i cluster-key \
	       "root@${h}" true 2>/dev/null
      then
        echo " SSH PING reply from ${h}: NOPONG"
      else
        echo " SSH PING reply from ${h}: PONG"
      fi
    done
    echo
  elif [[ "${OPTN}" = "delete" ]]
  then
    bootloose delete -c /tmp/bootloose.yaml
  fi

}

main 2>&1
