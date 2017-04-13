#! /usr/bin/env bash

RM='rm'
TEE=$(which tee)
AWK=$(which awk)
SED=$(which sed)
BASH=$(which bash)
HEAD=$(which head)
ECHO=$(which echo)
GREP=$(which grep)
DATE=$(which date)
CURL=$(which curl)
UNME=$(which uname)
UNZIP=$(which unzip)
BSNME=$(which basename)
UNZIP=$(which unzip)
XARGS=$(which xargs)
CHMOD=$(which chmod)
SLEEP=$(which sleep)
PRGNME=$("${BSNME}" "$0"|"${SED}" -n 's/\.sh//p')
SDLY=2
SWTCH="$1"
NUMARG=$#
INSTL=false
RMVE=false
DUMP=false
BSEURL='https://pkg.cfssl.org'
CFSSLOC='/usr/local/bin'

exitOnErr() {

  local date=$(${DATE})
  "${ECHO}" " Error: <$date> $1, exiting ..."
  exit 1

}

preCheck() {

  if [ "${EUID}" -ne 0 ]
  then
    exitOnErr "This action needs superuser rights"
  fi

}

prntUsage() {

    "$ECHO" "Usages: $PRGNME <-i|--install|-r|--remove|-d|--dump>"
    "$ECHO" "        -i|--install Install CFSsl tools,"
    "$ECHO" "        -r|--remove  Configure CFSsl tools,"
    "$ECHO" "        -d|--dump    Dump various CFSsl tools related info,"
    exit 0

}

parseArgs() {

  if [ ${NUMARG} -ne 1 ]
  then
    prntUsage
  fi

  if [ "${SWTCH}" = "-i" ] || [ "${SWTCH}" = "--install" ]
  then
    INSTL=true
  elif [ "${SWTCH}" = "-r" ] ||  [ "${SWTCH}" = "--remove" ]
  then
    RMVE=true
  elif [ "${SWTCH}" = "-d" ] ||  [ "${SWTCH}" = "--dump" ]
  then
    DUMP=true
  else
    prntUsage
  fi

}

instlCFSsl() {

  local OS
  if "${UNME}" -v | "${GREP}" -i darwin 2>&1 > /dev/null
  then
    OS='darwin'
  else
    OS='linux'
  fi
  
  r=$("${CURL}" -sSLk "${BSEURL}"|"${GREP}" '<h2>CFSSL'|"${HEAD}" -1|"${AWK}" '{print $NF}'|"${SED}" 's/<\/h2>//')
  
  if [[ ! -z ${r} ]]
  then
    if ! "${CURL}" -sSLk "${BSEURL}/R${r}/SHA256SUMS"| \
      "${GREP}" "${OS}-amd64"| \
      "${AWK}" '{print $NF}'| \
      "${XARGS}" -I {} "${ECHO}" "${CURL} -sSLk -o ${CFSSLOC}/{} ${BSEURL}/R${r}/{}; ${SLEEP} ${SDLY}; ${CHMOD} +x ${CFSSLOC}/{}"| \
      "${SED}" "s/_${OS}-amd64//"| \
      "${SED}" "s/_${OS}-amd64//2"| \
      "${BASH}"
    then
      exitOnErr "download; dump; make executable"
    fi
  fi

}

dumpCFSsl() {

  local OS
  if "${UNME}" -v | "${GREP}" -i darwin 2>&1 > /dev/null
  then
    OS='darwin'
  else
    OS='linux'
  fi
  
  r=$("${CURL}" -sSLk "${BSEURL}"|"${GREP}" '<h2>CFSSL'|"${HEAD}" -1|"${AWK}" '{print $NF}'|"${SED}" 's/<\/h2>//')

  "${CURL}" -sSLk "${BSEURL}/R${r}/SHA256SUMS"| \
    "${GREP}" "${OS}-amd64"| \
    "${AWK}" '{print $NF}'| \
    "${XARGS}" -I {} "${ECHO}" "ls -lhrt ${CFSSLOC}/{}"| \
    "${SED}" "s/_${OS}-amd64//"| \
    "${BASH}"

}

main() {

  parseArgs

  if $INSTL
  then
    preCheck
    instlCFSsl
    dumpCFSsl
  fi

  if $RMVE
  then
    preCheck
    rmveCFSsl
    dumpCFSsl
  fi

  if $DUMP
  then
    dumpCFSsl
  fi

}

set -u
main 2>&1|"${TEE}" "${PRGNME}.log"
