#! /usr/bin/env bash
############################################################################
# File name : setup_hscptls.sh
# Purpose   : Install and configure the latest Hashicorp tools.
# Usages    : ./instl-cnfgr-tools.sh <-i|--instl|-r|--remove|-d|--dump>
#             (make it executable using chmod +x)
# Start date : 03/21/2017
# End date   : 03/21/2017
# Author : Ankur Kumar
# Download link : 
# License : GNU GPL v2
# Version : 0.0.1
# Modification history :
# Notes :
############################################################################

RM='rm'
TEE=$(which tee)
AWK=$(which awk)
SED=$(which sed)
HEAD=$(which head)
ECHO=$(which echo)
GREP=$(which grep)
DATE=$(which date)
CURL=$(which curl)
UNME=$(which uname)
UNZIP=$(which unzip)
BSNME=$(which basename)
UNZIP=$(which unzip)
PRGNME=$("$ECHO" $("$BSNME" "$0") | "$SED" -n 's/\.sh//p')
SDLY=5
SWTCH="$1"
NUMARG=$#
INSTL=false
RMVE=false
DUMP=false
HCTLSLOC='/usr/local/bin'
CMNTLS="hashi-ui"
CMNTLSURL="https://github.com/jippi"
HCTLSURL='https://releases.hashicorp.com'
HCTLS="serf \
       consul \
       consul-esm \
       consul-replicate \
       consul-template \
       envconsul \
       vault \
       nomad \
       packer \
       terraform"

exitOnErr() {

    local date=$($DATE)
    "$ECHO" " Error: <$date> $1, exiting ..."
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
    "$ECHO" "        -i|--install Install DevOps tools,"
    "$ECHO" "        -r|--remove  Remove DevOps tools,"
    "$ECHO" "        -d|--dump    Dump various DevOps tools related info,"
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

  if "${UNME}" -v | "${GREP}" -i darwin 2>&1 > /dev/null
  then
    OS='darwin'
  else
    OS='linux'
  fi

}

instlHCrpUI() {

  for ct in ${CMNTLS}
  do
    local c=$("${CURL}" -sSLk "${CMNTLSURL}/${ct}/releases/latest"|"${GREP}" -E 'v[0-9.]+'|"${GREP}" master|"${AWK}" -F'"' '{print $2}'|"${AWK}" -F"/" '{print $NF}'|"${SED}" -e 's/...master//' -e 's/v//')

    if [[ ! -z "${c}" ]]
    then
      if ! "${CURL}" -sSLK -o "${HCTLSLOC}/${ct}" "${CMNTLSURL}/${ct}/releases/download/v${c}/${ct}-${OS}-amd64"
      then
        exitOnErr "${CURL} -sSLK -o ${HCTLSLOC}/${ct} ${CMNTLSURL}/${ct}/releases/download/v${c}/${ct}-${OS}-amd64"
      fi
    fi
  done

}

instlDvopsTls() {

  for t in ${HCTLS}
  do
    local v=$("${CURL}" -s ${HCTLSURL}/${t}/|${GREP} '^ *<a'|${GREP} ${t}|${AWK} -F "/" '{print $3}'|${GREP} -Ev '\-(rc|beta)'|${HEAD} -1)

    local c=$("${HCTLSLOC}/${t}" -v|"${GREP}" -E 'v[0-9.]+'|"${AWK}" '{print $2}'|"${SED}" 's/v//')
 
    if [[ "${v}" != "${c}" ]]
    then
      if ! "${CURL}" -sSLk -o /tmp/${t}.zip "${HCTLSURL}/${t}/${v}/${t}_${v}_${OS}_amd64.zip"
      then
        exitOnErr "${CURL} -sSLk -o /tmp/${t}.zip ${HCTLSURL}/${t}/${v}/${t}_${v}_${OS}_amd64.zip"
      else
        if ! "${UNZIP}" -o "/tmp/${t}.zip" -d "${HCTLSLOC}"
        then
          exitOnErr "${UNZIP} -o /tmp/${t}.zip -d ${HCTLSLOC}"
        fi
        "${RM}" -fv "/tmp/${t}.zip"
      fi
    fi
  done

#  instlHCrpUI

}

rmveDvopsTls() {

  for t in ${HCTLS}
  do
    "${RM}" -rfv "${HCTLSLOC}/${t}"
  done

}

dumpDvopsTls() {

  for t in $HCTLS
  do
    ls -lhrt "${HCTLSLOC}/${t}"

    if [[ "${t}" = "consul-esm" ]]
    then
      "${HCTLSLOC}/${t}" -version
    else
      "${HCTLSLOC}/${t}" -v
    fi

  done

}

main() {

  parseArgs

  if $INSTL
  then
    preCheck    
    instlDvopsTls
    dumpDvopsTls
  fi

  if $RMVE
  then
    preCheck    
    rmveDvopsTls
    dumpDvopsTls
  fi

  if $DUMP
  then
    dumpDvopsTls
  fi

}

set -u
main 2>&1|"${TEE}" "${PRGNME}.log"
