#! /bin/sh
############################################################################
# File name : docker_machine_aws.sh
# Purpose   : Create a docker host on AWS.
# Usages    : ./docker_machine_aws.sh <-c|--create|-r|--remove
#                                                 |-d|--dump>
#             (make it executable using chmod +x)
# Start date : 11/13/2015
# End date   : 11/xx/2015
# Author : Ankur Kumar
# Download link :
# License :
# Version : 0.0.1
# Modification history :
# Notes :
############################################################################

TEE=$(which tee)
AWK=$(which awk)
SED=$(which sed)
SEQ=$(which seq)
DATE=$(which date)
ECHO=$(which echo)
GREP=$(which grep)
CURL=$(which curl)
DCKR=$(which docker)
UNME=$(which uname)
XARGS=$(which xargs)
BSNME=$(which basename)
SCRPT=$("$ECHO" $("$BSNME" "$0") | "$SED" -n 's/\.sh//p')
VMNME='dckrtstaws'
VPCID='vpc-'
BOTOPRFL="$HOME/.aws/credentials"
BOTOSCTN='playground'
AWSAKID='<AccessKeyId>'
AWSSAKY='<SecretAccessKeyId>'
SLEEP=$(which sleep)
SWTCH="$1"
NUMARG=$#
DCKRMCHN=$(which docker-machine)
SLPCLSTR=20
OSX=false
LNX=false
REM=false
CRTE=false
DUMP=false

exitOnErr() {

    local date=$($DATE)
    "$ECHO" " Error: <$date> $1, exiting ..."
    exit 1

}

prntUsage() {

  "$ECHO" " Usages: $SCRPT <-c|--create|-r|--remove|-d|--dump>"
  exit 0

}

parseArgs() {

    if [ $NUMARG -ne 1 ]
    then
        prntUsage
    fi

    if [ "$SWTCH" = "-c" ] || [ "$SWTCH" = "--create" ]
    then
        CRTE=true
    elif [ "$SWTCH" = "-d" ] || [ "$SWTCH" = "--dump" ]
    then
        DUMP=true
    elif [ "$SWTCH" = "-r" ] || [ "$SWTCH" = "--remove" ]
    then
        REM=true
    else
        prntUsage
    fi

}

preChecks() {

  parseArgs

  if "$UNME" -v | "$GREP" -i darwin 2>&1 > /dev/null
  then
    if [ -z $DCKRMCHN ]
    then
      exitOnErr "docker-machine is required on Mac OS X"
    else
      if [ ! -f "$BOTOPRFL" ]
      then
        exitOnErr "$BOTOPRFL is required"
      else
        AWSAKID=$("$SED" -n "/\[$BOTOSCTN\]/,/^ *$/p" "$BOTOPRFL"|"$GREP" aws_access_key_id|"$AWK" -F"=" '{print $2}'|"$SED" 's/^ *//'|"$SED" 's/ *$//')
        AWSSAKY=$("$SED" -n "/\[$BOTOSCTN\]/,/^ *$/p" "$BOTOPRFL"|"$GREP" aws_secret_access_key|"$AWK" -F"=" '{print $2}'|"$SED" 's/^ *//'|"$SED" 's/ *$//')
        if [ -z "$AWSAKID" ] || [ -z "$AWSSAKY" ]
        then
          exitOnErr "Either aws_access_key_id or aws_secret_access_key is empty"
        fi  
      fi
    fi
  fi

}

crteDckrHst() {

  if ! "$DCKRMCHN" -D create \
       --driver amazonec2 \
       --amazonec2-access-key "$AWSAKID" \
       --amazonec2-secret-key "$AWSSAKY" \
       --amazonec2-instance-type "t2.medium" \
       --amazonec2-vpc-id "$VPCID" \
       --amazonec2-zone b \
       "$VMNME"
  then
    exitOnErr "$VMNME creation failed"
  fi

}

delDckrHst() {

  if ! "$DCKRMCHN" rm -f "$VMNME"
  then
    exitOnErr "$VMNME removal failed"
  fi

}

dumpDckrHst() {

  eval "$($DCKRMCHN env $VMNME)"
  "$DCKRMCHN" ls
  "$DCKRMCHN" ssh "$VMNME" 'df -kh; grep -i memtotal /proc/meminfo; nproc'

}

main() {

  preChecks

  if $CRTE
  then
    crteDckrHst
    dumpDckrHst
  fi

  if $REM
  then
    delDckrHst
  fi

  if $DUMP
  then
    dumpDckrHst
  fi

}

set -u
main 2>&1 | "$TEE" "$SCRPT.log"
