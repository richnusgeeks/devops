#! /usr/bin/env bash
############################################################################
# File name : rdsscan.sh
# Purpose   : RDS internal acceptance testing.
# Usages    : ./rdsscan.sh [-c|--config <config file path>]
#             (make it executable using chmod +x).
# Start date : 08/28/2017
# End date   : 08/28/2017
# Author : Ankur Kumar <richnusgeeks@gmail.com>
# Download link : http://www.richnusgeeks.com
# License : richnusgeeks
# Version : 0.0.1
# Modification history :
# Notes : TODO - 1. Eliminate hard coded stuff,
#                2. Break code in more subroutines,
############################################################################
# <start of global section>
IP=$(which ip)
SS=$(which ss)
PS=$(which ps)
WC=$(which wc)
AWK=$(which awk)
SED=$(which sed)
TEE=$(which tee)
RPM=$(which rpm)
ECHO=$(which echo)
GREP=$(which grep)
SUDO=$(which sudo)
BSNME=$(which basename)
SWTCH="$1"
NUMARG=$#
RDSROLE=false
FAILFLAG=false
CLROPTN=no
RDSCNFG='/etc/redis/redis.conf'
RDSBDIR='/usr/local/bin'
RDSPCKG='redis-server'
RDSPRT='6379'
let ETHI=$("${IP}" address|"${GREP}" eth[0-9]:|"${WC}" -l)-1
ETHIP=$("${IP}" address show dev "eth${ETHI}"|"${GREP}" inet|"${AWK}" '{print $2}'|"${AWK}" -F"/" '{print $1}')
PRGNME=$("$ECHO" $("$BSNME" "$0") | "$SED" -n 's/\.sh//p')
# <end of global section>

# <start of helper section>
prntErrWarnInfo() {

  local msg="$1"
  local msgtype="$2"
  local extrsme="$3"
  local color="$4"

  if [ -z "$msg" ]; then
    printf "\n %s\n" "ERROR: No message provided"
    return
  fi

  if [ -z "$msgtype" ]; then
    msgtype='err'
  fi

  if [ -z "$extrsme" ]; then
    extrsme='exit'
  fi

  case "$msgtype" in
    info) msg="$msg" ;;
    warn) msg="$msg" ;;
    err)  msg="$msg" ;;
    *)
      printf "\n %s\n" "ERROR: Message type should be info/warn/err"
      return
      ;;
  esac

  if [ ! -z "$color" ]
  then
    if [ "$color" != yes ] && [ "$color" != no ]
    then
      printf "\n %s\n" "ERROR: Color option should be yes/no"
      return
    fi

    case "$msgtype" in
      err) msg="\033[31;40;1m$msg\033[m" ;;
      info) msg="\033[32;40;1m$msg\033[m" ;;
      warn) msg="\033[33;40;1m$msg\033[m" ;;
    esac
  fi

  "$ECHO" -e " $msg"
  if [ "$extrsme" = "exit" ]; then
    printf " %s" "exiting ..."
    exit 1
  fi

}

getValFrmCnfg() {

  local section="$1"
  local field="$2"
  local cnfgfl="$3"

  if [ $# -ne 3 ]
  then
    prntErrWarnInfo "Not proper number of arguments passed" err exit yes
  fi

  if [ -z "$section" ]
  then
    prntErrWarnInfo "No section name provided" err exit yes
  fi

  if [ -z "$field" ]
  then
    prntErrWarnInfo "No field name provided" err exit yes
  fi

  if [ -z "$cnfgfl" ]
  then
    prntErrWarnInfo "No config file name provided" err exit yes
  fi

  if [ ! -f "$cnfgfl" ]
  then
    prntErrWarnInfo "No file $cnfgfl found" err exit yes
  fi

  local val=$("$SED" -n "/^ *$section/,/$ *^/p" $cnfgfl | "$GREP" "^ *$field" | "$SED" "s/^ *$field *= *//" | "$SED" 's/ \{1,\}$//')
  printf "%s" "$val"

}

preChecks() {

  if [ "${EUID}" -ne 0 ]
  then
    prntErrWarnInfo "This script needs superuser rights"
  fi

}

prntUsage() {

  "${ECHO}" "Usage: ${PRGNME} [-c|--config <config file path>]"
  exit 0

}

parseArgs() {

  if [ ${NUMARG} -gt 2 ]
  then
      prntUsage
  fi

  if [ ${NUMARG} -eq 2 ]
  then

    if [ "${SWTCH}" = '-c' ] || [ "${SWTCH}" = '--config' ]
    then
      if [ ! -f "${2}" ]
      then
        prntErrWarnInfo "${2} not found"
      fi
    else
      prntUsage
    fi

  fi

}

isRDSRole() {

  if [[ -x "${RDSBDIR}/${RDSPCKG}" ]] && [[ -f "${RDSCNFG}" ]]
  then
    RDSROLE=true
  fi

}

whichRoles() {

  isRDSRole

}

dumpRDS() {

  if ${RDSROLE}
  then
    if "${PS}" aux | "${GREP}" redis-server | "${GREP}" -v grep > /dev/null 2>&1
    then
      prntErrWarnInfo 'redis-server process is running [OK]' 'info' 'resume'

      if "${SS}" -ltn | "${GREP}" "${ETHIP}:${RDSPRT}" > /dev/null 2>&1
      then
        prntErrWarnInfo "redis-server listening on ${RDSPRT} [OK]" 'info' 'resume'
      else
        prntErrWarnInfo "redis-server not listening on ${ESTPRT} [FAIL]" 'err' 'resume'
        FAILFLAG=true
      fi

    else
      prntErrWarnInfo 'redis-server process not running [FAIL]' 'err' 'resume' 
      FAILFLAG=true
    fi
  fi

}

dumpRoles() {

  dumpRDS

}

main() {

  preChecks
  parseArgs
  whichRoles
  dumpRoles

}
# <end of helper section>


# <start of test section>

# <end of test section>


# <start of init section>

# <end of init section>


# <start of cleanup section>

# <end of cleanup section>


# <start of main section>
#set -u
main 2>&1
if ${FAILFLAG}
then
  exit 2
fi
# <end of main section>
