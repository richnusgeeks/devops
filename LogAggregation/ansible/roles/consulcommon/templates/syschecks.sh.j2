#! /usr/bin/env bash
############################################################################
# File name : syschecks.sh
# Purpose   : SYSTEM cpu/disk/memory/load checks.
# Usages    : ./syschecks.sh <-p|--cpu|-d|--disk|-m|--mem|-l|--load
#                             -w|--warn WARNPER -c|--crit CRITPER>
#             (make it executable using chmod +x).
# Start date : 03/08/2018
# End date   : 03/09/2018
# Author : Ankur Kumar <richnusgeeks@gmail.com>
# Download link : http://www.richnusgeeks.com
# License : richnusgeeks
# Version : 0.0.1
# Modification history :
# Notes : TODO - 1. Eliminate hard coded stuff,
#                2. Break code in more subroutines,
############################################################################

WARN=${3:-80}
ERR=${5:-90}
ARGF=${2}
ARGS=${4}
RETS=0
DSKP="/ \
      /data"
MSGSTR=''
NUMARGS=$#
TYPECHK=${1}
NUMARGSEXCT=5

printUsage() {

  cat <<EOF
 Usage: $(basename $0) <-p|--cpu|-d|--disk|-m|--mem|-l|--load
                        -w|--warn WARNPER -c|--crit CRITPER>"
EOF
  exit 0

}

parseArgs() {

  if [[ ${TYPECHK} != "-p" ]] && [[ ${TYPECHK} != "--cpu" ]]  && \
     [[ ${TYPECHK} != "-d" ]] && [[ ${TYPECHK} != "--disk" ]] && \
     [[ ${TYPECHK} != "-m" ]] && [[ ${TYPECHK} != "--mem" ]]  && \
     [[ ${TYPECHK} != "-l" ]] && [[ ${TYPECHK} != "--load" ]]
  then
    printUsage
  fi

  if [[ ${TYPECHK} != "-l" ]] && [[ ${TYPECHK} != "--load" ]]
  then

    if [[ ${NUMARGS} -ne ${NUMARGSEXCT} ]]
    then
      printUsage
    else
      if [[ "${ARGF}" != "-w" ]]
      then
        printUsage
      else
        if ! echo -n "${WARN}"|grep -E '[1-9]{1}[0-9]?' > /dev/null 2>&1
        then
          printUsage
        fi
      fi
  
      if [[ "${ARGS}" != "-c" ]]
      then
        printUsage
      else
        if ! echo -n "${ERR}"|grep -E '[1-9]{1}[0-9]?' > /dev/null 2>&1
        then
          printUsage
        fi
      fi
  
      if [[ ${ERR} -le ${WARN} ]]
      then
        printUsage
      fi 
  
    fi

  fi

}

cpuUsage() {

  if [[ ${TYPECHK} = "-p" ]] || [[ ${TYPECHK} = "--cpu" ]]
  then

    # Reference: https://stackoverflow.com/questions/9229333/how-to-get-overall-cpu-usage-e-g-57-on-linux
    local cpuper=$(top -b -n2 -p 1|fgrep "Cpu(s)"|tail -1)
    local cpusage=$(echo ${cpuper}|awk -F'id,' -v prefix="$prefix" '{ split($1, vs, ",");v=vs[length(vs)];sub("%", "", v); printf "%s%.1f%%\n", prefix, 100 - v }'|awk -F"." '{print $1}')
  
    if [[ ${cpusage} -gt ${WARN} ]] && [[ ${cpusage} -lt ${ERR} ]]
    then
      RETS=1
    elif [[ ${cpusage} -gt ${ERR} ]]
    then
      RETS=2
    fi
  
    MSGSTR="${cpuper}"
  
  fi

}

diskUsage() {

  if [[ ${TYPECHK} = "-d" ]] || [[ ${TYPECHK} = "--disk" ]]
  then
  
    for p in ${DSKP}
    do
      if [[ -d ${p} ]]
      then
        curp=$(df -kh|grep -Ew ${p}|awk '{print $(NF-1)}'|sed 's/%//')
  
        if [[ ${curp} -gt ${WARN} ]] && [[ ${curp} -lt ${ERR} ]]
        then
          RETS=1
        elif [[ ${curp} -gt ${ERR} ]]
        then
          RETS=2
        fi
      fi
  
      MSGSTR+="$(df -kh|grep -Ew ${p})\n"
    done
  
    MSGSTR="$(df -kh|grep Filesystem)\n${MSGSTR}"

  fi

}

sysLoad() {

  if [[ ${TYPECHK} = "-l" ]] || [[ ${TYPECHK} = "--load" ]]
  then
  
    local loadavg=$(sudo monit status $(hostname)|grep load|sed 's/^ \{1,\}//')
    local loadavg1=$(echo ${loadavg}|sed 's/^ *load average *//'|awk '{print $1}'|sed 's/[][]//g'|awk -F"." '{print $1}')
    local loadavg5=$(echo ${loadavg}|sed 's/^ *load average *//'|awk '{print $2}'|sed 's/[][]//g'|awk -F"." '{print $1}')
    local loadavg10=$(echo ${loadavg}|sed 's/^ *load average *//'|awk '{print $3}'|sed 's/[][]//g'|awk -F"." '{print $1}')
    let local np=$(nproc)+$(($(nproc)/2))
  
    if [[ ${loadavg5} -gt ${np} ]]
    then
      RETS=1
    fi
  
    if [[ ${loadavg10} -gt ${np} ]]
    then
      RETS=2
    fi
  
    MSGSTR="${loadavg}"

  fi

}

memUsage() {

  if [[ ${TYPECHK} = "-m" ]] || [[ ${TYPECHK} = "--mem" ]]
  then
  
    local memusg=$(sudo monit status $(hostname)|grep -E 'memory'|sed 's/^ \{1,\}//')
    local curmem=$(echo "${memusg}"| \
                   awk '{print $NF}'| \
                   sed -e 's/\[//' -e 's/\]//' -e 's/%//'| \
                   awk -F "." '{print $1}')
  
    if [[ ${curmem} -gt ${WARN} ]] && [[ ${curmem} -lt ${ERR} ]]
    then
      RETS=1
    elif [[ ${curmem} -gt ${ERR} ]]
    then
      RETS=2
    fi
  
    MSGSTR="${memusg}\n\n$(free -h)"

  fi

}

main() {

  parseArgs
  cpuUsage
  diskUsage
  sysLoad
  memUsage
  echo -ne "${MSGSTR}"
  exit ${RETS}

}

main
