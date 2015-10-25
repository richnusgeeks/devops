#! /bin/sh
############################################################################
# File name : bringup_elasticsearch_cluster.sh
# Purpose   : Create a multinode Elasticsearch cluster with docker
#             containers.
# Usages    : ./bringup_elasticsearch_cluster.sh <-c|--create|-r|--remove
#                                                 |-d|--dump>
#             (make it executable using chmod +x)
# Start date : 10/15/2015
# End date   : 10/xx/2015
# Author : Ankur Kumar <richnusgeeks@gmail.com>
# Download link : https://github.com/richnusgeeks/devops
# License : RichNusGeeks
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
VMNME='default'
SLEEP=$(which sleep)
SWTCH="$1"
NUMARG=$#
NUMCLNT=1
NUMMSTR=2
NUMDATA=5
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
    if [ -z $DCKR ] || [ -z $DCKRMCHN ]
    then
      exitOnErr "both docker and docker-machine required on Mac OS X"
    else
      OSX=true
    fi
  else
    if [ -z "$DCKR" ]
    then
      exitOnErr "docker required on GNU/Linux"
    else
      LNX=true 
    fi
  fi

}

initEnv() {

  if $OSX
  then
    if ! eval "$("$DCKRMCHN" env "$VMNME")"
    then
      exitOnErr "setup of env. for docker cli to connect to the docker daemon failed"
    else
      hstvm=$("$DCKRMCHN" ip "$VMNME")
      if [ $? -ne 0 ]
      then
        exitOnErr "getting IP of docker hostvm failed"
      fi 
    fi
  fi

}

crteELSMstr() {

  for i in $(seq $NUMMSTR)
  do
    if ! "$DCKR" run -d --name="ELS_MSTR$i" elasticsearch elasticsearch \
         -Des.node.name="ELS_MSTR$i" \
         -Des.node.master=true \
         -Des.node.data=false \
         -Des.http.enabled=false
    then
      exitOnErr "$DCKR run -d --name=ELS_MSTR$i elasticsearch failed"
    fi
  done

}

crteELSClnt() {

  for i in $(seq $NUMCLNT)
  do
    if ! "$DCKR" run -d -p 9200:9200 --name="ELS_CLNT$i" --link ELS_MSTR1 elasticsearch elasticsearch \
         -Des.node.name="ELS_CLNT$i" \
         -Des.node.master=false \
         -Des.node.data=false \
         -Des.http.enabled=true
    then
      exitOnErr "$DCKR run -d --name=ELS_CLNT$i elasticsearch failed"
    fi
  done

}

crteELSData() {
  
  for i in $(seq $NUMDATA)
  do
    if ! "$DCKR" run -d --name="ELS_DATA$i" --link ELS_MSTR1 elasticsearch elasticsearch \
         -Des.node.name="ELS_DATA$i" \
         -Des.node.master=false \
         -Des.node.data=true \
         -Des.http.enabled=false
    then
      exitOnErr "$DCKR run -d --name=ELS_DATA$i --link ELS_MSTR1 elasticsearch failed"
    fi
  done

  "$SLEEP" "$SLPCLSTR"

}

dumpELSClstr() {

  "$DCKR" ps | grep elasticsearch
  "$ECHO"
  
  if $OSX
  then
    "$CURL" "$hstvm:9200/_cluster/health?pretty=true?wait_for_status=yellow?timeout=50s"
  else
    "$CURL" "localhost:9200/_cluster/health?pretty=true?wait_for_status=yellow?timeout=50s"
  fi
  "$ECHO"

}

clnupELSClstr() {

  for c in $($DCKR ps -a | grep -iv containers | grep elasticsearch | $AWK '{print $1}' | $XARGS)
  do
    "$DCKR" rm -f "$c"
    #then
    #  exitOnErr "$DCKR rm -f $c failed"
    #fi
  done

}

main() {

  preChecks
  initEnv

  if $CRTE
  then
    crteELSMstr
    crteELSClnt
    crteELSData
    dumpELSClstr
  fi

  if $REM
  then
    clnupELSClstr
  fi

  if $DUMP
  then
    dumpELSClstr
  fi

}

set -u
main 2>&1 | "$TEE" "$SCRPT.log"
