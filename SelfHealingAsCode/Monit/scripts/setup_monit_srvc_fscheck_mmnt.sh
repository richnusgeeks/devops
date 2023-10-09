#! /bin/bash
set -uo pipefail

DSPCWMARK="${DSPCE_WMARK:-90}"
INDEWMARK="${INODE_WMARK:-90}"
MONITSDIR='/opt/monit/monit.d'
RQRDCMNDS="echo
          tee"

preReq() {

  for c in ${RQRDCMNDS}
  do
    if ! command -v "${c}" > /dev/null 2>&1
    then
      echo " Error: required command ${c} not found, exiting ..."
      exit 1
    fi
  done

}

cnfgrMonitFSCheck() {

  mkdir "${MONITSDIR}"
  tee "${MONITSDIR}/spaceinode" <<EOF
check filesystem rootfs with path /
  if space usage > ${DSPCWMARK}% then alert
  if inode usage > ${INDEWMARK}% then alert
EOF

}

main() {

  preReq
  cnfgrMonitFSCheck

}

main 2>&1
