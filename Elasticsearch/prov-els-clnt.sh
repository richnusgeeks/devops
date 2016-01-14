#! /usr/bin/env bash
############################################################################
# File name : prov-els-clnt.sh
# Purpose   : Create/Remove a totally isolated ES client
# Usages    : ./prov-els-clnt.sh <-c|--create|-r|--remove|-d|--dump>
#             (make it executable using chmod +x)
# Start date : 11/16/2015
# End date   : 11/xx/2015
# Author : Ankur Kumar
# Download link :
# License :
# Version : 0.0.1
# Modification history :
# Notes :
############################################################################

RM='rm'
TEE=$(which tee)
SED=$(which sed)
ECHO=$(which echo)
GREP=$(which grep)
DATE=$(which date)
CURL=$(which curl)
UNZIP=$(which unzip)
BSNME=$(which basename)
SLEEP=$(which sleep)
HSTNME=$(which hostname)
PRGNME=$("$ECHO" $("$BSNME" "$0") | "$SED" -n 's/\.sh//p')
STRT='start'
STOP='stop'
STTS='status'
SDLY=5
SWTCH="$1"
NUMARG=$#
CRTE=false
RMVE=false
DUMP=false
ESHPSZ='8g'
ELSLOC='/opt'
ELSZIP='/tmp/elasticsearch-1.5.2.zip'
ELSSRVC='elsclnt'
ELSSRVCLOC='/etc/init'
ELSCNFG='elasticsearch.yml'
ELSLGCNFG='logging.yml'
declare -A ELSCNFGFLS
ELSCNFGS="cluster.name \
          node.name \
          node.data \
          node.master \
          http.port \
          http.enabled \
          path.logs \
          discovery.zen.ping.multicast.enabled \
          discovery.zen.ping.unicast.hosts"
ELSCNFGFLS[cluster.name]='<Elasticsearch Cluster Name>'
ELSCNFGFLS[node.name]=$("$HSTNME")-clnt
ELSCNFGFLS[node.data]='false'
ELSCNFGFLS[node.master]='false'
ELSCNFGFLS[http.port]='9200'
ELSCNFGFLS[http.enabled]='true'
ELSCNFGFLS[path.logs]='/raid0/elasticsearch/logs'
ELSCNFGFLS[discovery.zen.ping.multicast.enabled]='false'
ELSCNFGFLS[discovery.zen.ping.unicast.hosts]='["localhost"]'
ELSLGNGFLS='{cluster.name}'

exitOnErr() {

    local date=$($DATE)
    "$ECHO" " Error: <$date> $1, exiting ..."
    exit 1

}

prntUsage() {

    "$ECHO" "Usages: $PRGNME <-c|--create|-r|--remove|-d|--dump>"
    "$ECHO" "        -c|--create  Create Elasticsearch client,"
    "$ECHO" "        -r|--remove  Remove Elasticsearch client,"
    "$ECHO" "        -d|--dump    Dump various Elasticsearch client related info,"
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
  elif [ "$SWTCH" = "-r" ] ||  [ "$SWTCH" = "--remove" ]
  then
    RMVE=true
  elif [ "$SWTCH" = "-d" ] ||  [ "$SWTCH" = "--dump" ]
  then
    DUMP=true
  else
    prntUsage
  fi

}

remELSClnt() {

  if ! "$STOP" "$ELSSRVC"
  then
    exitOnErr "$STOP $ELSSRVC failed"
  else
    "$SLEEP" "$SDLY"
  fi

  "$RM" -rfv "$ELSLOC/$($BSNME $ELSZIP|$SED 's/.zip//')" \
             "$ELSSRVCLOC/${ELSSRVC}.conf" \
             "${ELSCNFGFLS[path.logs]}/${ELSCNFGFLS[node.name]}.log" \
             "/var/log/upstart/elsclnt.log"

}

crteELSCnfg() {

  for k in $ELSCNFGS
  do
    if ! "$SED" -i "/^ *$k/d" "$ELSLOC/$($BSNME $ELSZIP|$SED 's/.zip//')/config/$ELSCNFG"
    then
      exitOnErr "$SED" -i '/^ *$k/d' "$ELSLOC/$($BSNME $ELSZIP|$SED 's/.zip//')/config/$ELSCNFG"
    else
      "$ECHO" "$k: ${ELSCNFGFLS[$k]}" >> "$ELSLOC/$($BSNME $ELSZIP|$SED 's/.zip//')/config/$ELSCNFG"
    fi
  done

  if ! "$SED" -i "/^ *file:.*$ELSLGNGFLS/s/$ELSLGNGFLS/$ELSLGNGFLS-clnt/" "$ELSLOC/$($BSNME $ELSZIP|$SED 's/.zip//')/config/$ELSLGCNFG"
  then
    exitOnErr "$SED -i 's/$ELSLGNGFLS/$ELSLGNGFLS-clnt/' $ELSLOC/$($BSNME $ELSZIP|$SED 's/.zip//')/config/$ELSLGCNFG failed"
  else
    "$SLEEP" "$SDLY"
  fi

  if [ ! -e "$ELSSRVCLOC/${ELSSRVC}.conf" ]
  then
    > "$ELSSRVCLOC/${ELSSRVC}.conf"
      "$TEE" "$ELSSRVCLOC/${ELSSRVC}.conf" <<EOF
    
    start on runlevel [35]
    stop on runlevel [!35]
    respawn
    respawn limit 10 5
    env ES_HEAP_SIZE="$ESHPSZ"
    exec "$ELSLOC/$($BSNME $ELSZIP|$SED 's/.zip//')/bin/elasticsearch"
    
EOF
  fi

}

crteELSClnt() {

  if [ ! -e "$ELSZIP" ]
  then
    exitOnErr "$ELSZIP doesn't exist"
  else
    if ! "$UNZIP" "$ELSZIP" -d "$ELSLOC"
    then
      exitOnErr "$UNZIP $ELSZIP -d $ELSLOC failed"
    fi
  fi
  
  crteELSCnfg

  if ! "$STRT" "$ELSSRVC"
  then
    exitOnErr "$STRT $ELSSRVC failed"
  else
    sleep "$SDLY"
  fi

}

dumpELSClnt() {

  "$STTS" elsclnt

  ls -lhrt "$ELSLOC/$($BSNME $ELSZIP|$SED 's/.zip//')" \
           "$ELSSRVCLOC/${ELSSRVC}.conf" \
           "${ELSCNFGFLS[path.logs]}/${ELSCNFGFLS[node.name]}.log" \
           "/var/log/upstart/elsclnt.log"

  for k in $ELSCNFGS
  do
    "$GREP" "^ *$k" "$ELSLOC/$($BSNME $ELSZIP|$SED 's/.zip//')/config/$ELSCNFG"
  done

  "$GREP" "^ *file:.*${ELSLGNGFLS}-clnt" "$ELSLOC/$($BSNME $ELSZIP|$SED 's/.zip//')/config/$ELSLGCNFG"

  "$CURL" "http://localhost:${ELSCNFGFLS[http.port]}/_cat/nodes?v"

}

main() {

  parseArgs

  if $CRTE
  then
    crteELSClnt
    dumpELSClnt
  fi

  if $RMVE
  then
    remELSClnt
    dumpELSClnt
  fi

  if $DUMP
  then
    dumpELSClnt
  fi

}

set -u
main 2>&1
