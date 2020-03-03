#! /bin/bash
set -uo pipefail

LOGF="$(basename "${0}"|sed 's/\.sh//').log"

TRACE="${TRACE_FLAG:-0}"
DEBUG="${DEBUG_FLAG:-0}"
DCKRFL="${DOCKER_FILE:-Dockerfile}"
CSTCNFG='config.yaml'
CSTPRTFIX="${CST_PORT_FIX:-0}"
CSTSLKURL="${SLACK_URL:-none}"
LBLVNDRK="${LABEL_VENDORK:-com.richnusgeeks.vendor}"
LBLVNDRV="${LABEL_VENDORV:-richnusgeeks}"
LBLCTGRK="${LABEL_CATEGORYK:-com.richnusgeeks.category}"
LBLCTGRV="${LABEL_CATEGORYV:-none}"
TINIVER="${TINI_VERSION:-0.18.0}"
SCHMVER='2.0.0'
RQRDCMNDS="curl
           date
           echo
           grep
           sed
           tee"
RETSTATUS=0

exitOnErr() {

  echo " <$(date)> Error: ${1}, exiting ..."
  exit 1

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

fixADD() {

  if ! sed -i '/^ *ADD/s/ADD/COPY/' "${DCKRFL}"
  then
    echo " Error: sed -i '/^ *ADD/s/ADD/COPY/' ${DCKRFL} failed ..."
  fi	  

}

fixLABEL() {

  if ! grep -E "^ *LABEL \"${LBLCTGRK}\"=\"(base|utility|service)\"" "${DCKRFL}" > /dev/null 2>&1
  then
    if ! sed -i "/^ *FROM/ a\\
LABEL \"${LBLCTGRK}\"=\"${LBLCTGRV}\"
" "${DCKRFL}"
    then
      echo " Error: append LABEL \"${LBLCTGRK}\"=\"${LBLCTGRV}\" ${DCKRFL} failed ..."
    fi
  fi

  if ! grep -E "^ *LABEL \"${LBLVNDRK}\"=\"${LBLVNDRV}\"" "${DCKRFL}" > /dev/null 2>&1
  then
    if ! sed -i "/^ *FROM/ a\\
LABEL \"${LBLVNDRK}\"=\"${LBLVNDRV}\"
" "${DCKRFL}"
    then
      echo " Error: append LABEL \"${LBLVNDRK}\"=\"${LBLVNDRV}\" ${DCKRFL} failed ..."
    fi
  fi

}

fixENTRYPOINT() {

  if ! grep '^ *ENTRYPOINT \["/sbin/tini", *"--"\]' "${DCKRFL}" > /dev/null 2>&1
  then
    if ! sed -i '$ a\
ENTRYPOINT ["/sbin/tini","--"]' "${DCKRFL}"
    then
      echo ' Error: append ENTRYPOINT ["/sbin/tini","--"] failed ...'
    fi
  fi

}

fixWORKDIR() {

  if ! grep '^ *WORKDIR' "${DCKRFL}" > /dev/null 2>&1
  then
    if ! sed -i '$ a\
WORKDIR /
' "${DCKRFL}"
    then
      echo ' Error: append WORKDIR / failed ...'
    fi
  fi    

}

fixCMD() {

  local cmd=$(grep '^ *CMD' "${DCKRFL}"|tail -1|sed 's/^ *CMD *//')
  if ! echo ${cmd} | grep '[][]' > /dev/null 2>&1
  then
    if [[ ! -z "${cmd}" ]]
    then
      cmd=\[\'${cmd}\'\]

      if sed -i '/^ *CMD/d' "${DCKRFL}"
      then
        if ! sed -i "$ a\\
CMD ${cmd}" "${DCKRFL}"
        then
          echo " Error: append CMD ${cmd} failed ..."
        else
          sed -i -e "/^ *CMD/s/'/\"/g" \
                 -e "/^ *CMD/s/ /\",\"/2" "${DCKRFL}"
        fi
      fi
    fi
  fi

}

main() {

  fixADD
  fixLABEL
  fixWORKDIR
  fixENTRYPOINT
  fixCMD

}

main 2>&1 | tee "${LOGF}"
