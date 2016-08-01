#! /bin/bash
set -u

PWD=$(pwd)
JAVA=$(which java)
LG4V='1.2.17'
LG4JR="log4j-${LG4V}.jar"
CLSNME='TstLg4jELK'

if [[ ! -e "${LG4JR}" ]]; then
  echo " Error: ${LG4JR} missing ..."
  exit -1
fi

if [[ ! -e "${CLSNME}.class" ]]; then
  echo " Error: ${CLSNME}.class missing ..."
  exit -1
fi

export CLASSPATH=.:"${PWD}/${LG4JR}"
"$JAVA" "${CLSNME}"
