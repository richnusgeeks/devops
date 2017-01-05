#! /bin/bash
set -u

RM=$(which rm)
PS=$(which ps)
AWK=$(which awk)
SED=$(which sed)
TEE=$(which tee)
ECHO=$(which echo)
DATE=$(which date)
GREP=$(which grep)
PSTE=$(which paste)
CLMN=$(which column)
BSNME=$(which basename)
HSTNME=$(which hostname)
SCRPTNME=$(basename "$0"|sed 's/\.sh//')
CPULMT=$(which cpulimit)
FRSHCLM=$(which freshclam)
CLMSCAN=$(which clamscan)
CPUPER=20
BNRYS="cpulimit \
       freshclam \
       clamscan"
SMRYFL="summary_$($HSTNME)"
SKPLST="/opt/${SCRPTNME}.skip" 

exitOnErr() {

  local date=$($DATE)
  echo " Error: <$date> $1, exiting ..."
  exit 1

}

preChecks() {

  for b in $BNRYS
  do
    if ! which "$b" >/dev/null 2>&1
    then
      exitOnErr "required command $b not found"
    fi
  done    

}

rfrshClamDB() {

  while true
  do
    if ! "$PS" aux|"$GREP" freshclam|"$GREP" -v grep > /dev/null 2>&1
    then
      break
    else
      sleep 5
    fi
  done

  if ! "$CPULMT" -i -l "$CPUPER" "$FRSHCLM"
  then
    exitOnErr "$CPULMT -i -l $CPUPER freshclam failed"
  fi

}

virusScan() {

  if ! "$RM" -fv /opt/scan_*.log /opt/summary_*.log /opt/summary_*.csv
  then
    exitOnErr "$RM -fv /opt/scan_*.log /opt/summary_*.log /opt/summary_*.csv failed"
  fi

  while true
  do
    if ! "$PS" aux|"$GREP" clamscan|"$GREP" -v grep > /dev/null 2>&1
    then
      break
    else
      sleep 5
    fi
  done

  local excld=''
  if [ -f "${SKPLST}" ]
  then
    while read e
    do
      if "$ECHO" "$e"|"$GREP" -E '^ *#' > /dev/null 2>&1
      then
        continue
      else
        excld+="--exclude=$("$ECHO" "$e"|"$SED" 's/^ \{1,\}//'|"$SED" 's/ \{1,\}$//') "
      fi
    done < "${SKPLST}"
  fi

  if ! eval nohup sudo -b "$CPULMT" -i -l "$CPUPER" \
    "$CLMSCAN" --max-filesize=5m --quiet -r / --exclude-dir=/dev --exclude-dir=/sys --exclude-dir=/proc \
    --scan-pe=no --scan-ole2=no --scan-pdf=no --scan-swf=no --scan-html=no --scan-xmldocs=no --scan-hwp3=no \
    "$excld" -l scan_$(/bin/hostname).log >/dev/null 2>&1
  then
    exitOnErr "launching cpulimit'd clamscan job failed"
  fi

  while true
  do
    if ! "$PS" aux|"$GREP" clamscan|"$GREP" -v grep > /dev/null 2>&1
    then
      if ! "$SED" -n '/SCAN SUMMARY/,/^ *$/p' /opt/scan_*.log | \
        "$SED" "s/\-\{1,\} SCAN SUMMARY -\{1,\}/Host: $($HSTNME)/" | \
        "$GREP" -v '^ *Total errors' > /opt/"${SMRYFL}.log"
      then
        exitOnErr "pipeline to create scan summary log failed"
      else
        echo >> "/opt/${SMRYFL}.log"
      fi
      break
    else
      sleep 5
    fi
  done

}

rows2Columns() {
# http://unix.stackexchange.com/questions/79642/transposing-rows-and-columns
  if ! "$AWK" -F":" -v n=9 \
    'BEGIN { x=1; c=0;} 
    ++c <= n && x == 1 {print $1; buf = buf $2 "\n";
    if(c == n) {x = 2; printf buf} next;}
    !/./{c=0;next}
    c <=n {printf "%s\n", $2}' /opt/"${SMRYFL}.log" | \
    "$PSTE" - - - - - - - - - | \
    "$CLMN" -t -s "$(printf "\t")" | \
    sed 's/ \{2,\}/,/g' > /opt/"${SMRYFL}.csv"
  then
    exitOnErr "pipeline to create scan summary csv failed"
  fi

}

infectedFiles() {

  infls=$("$GREP" FOUND /opt/scan_$(/bin/hostname).log)

  if [ ! -z "$infls" ]
  then
    "$ECHO" "$infls" | sudo "$TEE" /opt/infected_files_$(date +%s).log
  fi

}

main() {

  preChecks
  rfrshClamDB
  virusScan
  rows2Columns
  infectedFiles

}

main 2>&1|"$TEE" -a "/var/log/${SCRPTNME}.log"
