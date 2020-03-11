#! /bin/bash
set -uo pipefail

RM='rm'
AWK=$(command -v awk)
CAT=$(command -v cat)
SED=$(command -v sed)
CURL=$(command -v curl)
GREP=$(command -v grep)
ECHO=$(command -v echo)
DATE=$(command -v date)
CHMOD=$(command -v chmod)
SWTCH="${1}"
NUMARG=${#}
INSTL=false
RMVE=false
DUMP=false
UNAME=$(command -v uname)
PRGNME=$("${ECHO}" "${0##*/}" | "${SED}" -n 's/\.sh//p')
TLSLOC='/usr/local/bin'
BSEURL='https://github.com'
TLSLST="goss
        dgoss"

exitOnErr() {

  local date
  date=$("${DATE}")
  "${ECHO}" " Error: <${date}> $1, exiting ..."
  exit 1

}

preCheck() {

  if [[ "${EUID}" -ne 0 ]]
  then
    exitOnErr "This action needs superuser rights"
  fi

}

prntUsage() {

  "${CAT}" << EOF >&2
 Usage: ${PRGNME}.sh <-i|--install|-r|--remove|-d|--dump>
                   -i|--install Install GOSS tools,
                   -r|--remove  Remove GOSS tools,
                   -d|--dump    Dump various GOSS tools related info,
EOF
    exit 0

}

parseArgs() {

  if [ $NUMARG -ne 1 ]
  then
    prntUsage
  fi

  if [ "$SWTCH" = "-i" ] || [ "$SWTCH" = "--install" ]
  then
    INSTL=true
  elif [ "$SWTCH" = "-r" ] ||  [ "$SWTCH" = "--remove" ]
  then
    RMVE=true
  elif [ "$SWTCH" = "-d" ] ||  [ "$SWTCH" = "--dump" ]
  then
    DUMP=true
  else
    prntUsage
  fi

  if "${UNAME}" -v | "${GREP}" -i darwin > /dev/null 2>&1
  then
    OS='darwin'
  else
    OS='linux'
  fi

}

instlSSTls() {

  local LTSTVERG
  LTSTVERG=$("${CURL}" -sSLk https://github.com/aelsabbahy/goss/releases/latest|"${GREP}" releases/download|"${GREP}" "${OS}-amd64"|"${AWK}" -F'"' '{print $2}')

  if [[ -n "${LTSTVERG}" ]]
  then
    local LTSTVERDG
    LTSTVERDG="$("${ECHO}" "${LTSTVERG}"|"${SED}" "s/goss-${OS}-amd64/dgoss/")"
    
    if ! "${CURL}" -sSLk "${BSEURL}/${LTSTVERG}" -o "${TLSLOC}/goss"
    then
      exitOnErr "${CURL} -sSLk ${BSEURL}/${LTSTVERG} -o ${TLSLOC}/goss"
    fi

    if ! "${CURL}" -sSLk "${BSEURL}/${LTSTVERDG}" -o "${TLSLOC}/dgoss"
    then
      exitOnErr "${CURL} -sSLk ${BSEURL}/${LTSTVERDG} -o ${TLSLOC}/dgoss"
    fi

    for t in ${TLSLST}
    do
      "${CHMOD}" +x "${TLSLOC}/${t}"
    done   
  fi

}

rmveSSTls() {

  for t in ${TLSLST}
  do
    "${RM}" -fv "${TLSLOC}/${t}"
  done   

}

dumpSSTls() {

  for t in ${TLSLST}
  do
    "${TLSLOC}/${t}" -v
  done   

}

main() {

  parseArgs

  if $INSTL
  then
    preCheck    
    instlSSTls
    dumpSSTls
  fi

  if $RMVE
  then
    preCheck    
    rmveSSTls
    dumpSSTls
  fi

  if $DUMP
  then
    dumpSSTls
  fi

}

set -u
main 2>&1
