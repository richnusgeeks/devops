#! /usr/bin/env bash
############################################################################
# File name : instl-cnfgr-mmsagent.sh
# Purpose   : Install and configure MMS Agent for mongo monitoring on
#             CenOS 6.x (x>=4)
#             instance.
# Usages    : ./instl-cnfgr-mmsagent.sh <-i|--install|-c|--config|-d|--dump
#                                          |-s|--start|-t|--stop|-a|--all
#                                          |-r|--clean>
#             (make it executable using chmod +x) 
# Start date : 11/03/2013
# End date   : 11/0x/2013
# Author : Ankur Kumar <richnusgeeks@gmail.com>
# Download link : http://www.richnusgeeks.me
# License : RichNusGeeks
# Version : 0.0.1
# Modification history : 1. Changes for CentOS 6.x by Ankur on 
#                           11/16/2013,
# Notes :
############################################################################
# <start of include section>
# <end of include section>


# <start of global section>
unalias rm
RM=$(which rm)
PS=$(which ps)
CAT=$(which cat)
SED=$(which sed)
RPM=$(which rpm)
TEE=$(which tee)
YUM=$(which yum)
TAR=$(which tar)
TEE=$(which tee)
ECHO=$(which echo)
GREP=$(which grep)
NTST=$(which netstat)
DATE=$(which date)
TAIL=$(which tail)
SRVC=$(which service)
SLEEP=$(which sleep)
BSNME=$(which basename)
PYTHON=$(which python)
CHKCNFG=$(which chkconfig)
SWTCH="$1"
NUMARG=$#
PRGNME=$("$ECHO" $("$BSNME" "$0") | "$SED" -n 's/\.sh//p')
STOP=stop
START=start
STATUS=status
IPTBLS='iptables'
SLPSRVR=10
SLPFLSYS=5
MMSTARBALL='mms-monitoring-agent.tar.gz'
AGENTDIR='mms-agent'
MMSAGENT='agent.py'
MMSSRVC='mmsagent'
MMSLOGDIR='/var/log/'
UPSTRTDIR='/etc/init'
MMSLGRTTE="/etc/logrotate.d/$MMSSRVC"
ALL=false
DUMP=false
STOPR=false
STARTR=false
INSTL=false
CLEAN=false
CNFGR=false
RECNFG=false
YUMPCKGS="gcc.x86_64 \
          python-devel \
          python-setuptools"
PIPPCKGS="pymongo"
# <end of global section>


# <start of helper section>
exitOnErr() {

    local date=$($DATE)
    "$ECHO" " Error: <$date> $1, exiting ..."
    exit 1

}

prntUsage() {

    "$ECHO" "Usages: $PRGNME <-i|--install|-c|--config|-d|--dump"
    "$ECHO" "                   |-s|--start|-t|--stop|-a|--all>"
    "$ECHO" "                   |-c|--clean>"
    "$ECHO" "        -i|--install Install MMS Agent,"
    "$ECHO" "        -c|--config  Configure MMS Agent post install,"
    "$ECHO" "        -d|--dump    Dump various MMS Agent related info,"
    "$ECHO" "        -s|--start   Start MMS Agent service,"
    "$ECHO" "        -t|--stop    Stop MMS Agent service,"
    "$ECHO" "        -a|--all     Install+Configure+Start+Dump MMS Agent,"
    "$ECHO" "        -r|--clean   Clean everything MMS Agent,"
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
    elif [ "$SWTCH" = "-c" ] ||  [ "$WTCH" = "--config" ]
    then
        CNFGR=true
    elif [ "$SWTCH" = "-d" ] || [ "$SWTCH" = "--dump" ]
    then
        DUMP=true
    elif [ "$SWTCH" = "-a" ] || [ "$SWTCH" = "--all" ]
    then
        ALL=true
    elif [ "$SWTCH" = "-s" ] || [ "$SWTCH" = "--start" ]
    then
        STARTR=true
    elif [ "$SWTCH" = "-t" ] || [ "$SWTCH" = "--stop" ]
    then
        STOPR=true
    elif [ "$SWTCH" = "-r" ] || [ "$SWTCH" = "--clean" ]
    then
        CLEAN=true
    else
        prntUsage
    fi

}

preChecks() {

    parseArgs

    if [ "$EUID" -ne 0 ]
    then
        exitOnErr "This script needs superuser rights"
    fi

    if $INSTL || $ALL
    then
        if [ ! -e "/tmp/$MMSTARBALL" ]
        then
            exitOnErr "Required /tmp/$MMSTARBALL not found"
        fi

        "$SRVC" "$IPTBLS" stop
        "$SRVC" "$IPTBLS" status

        "$CHKCNFG" "$IPTBLS" off
        "$CHKCNFG" --list "$IPTBLS"
    fi

}

stopMMS() {

    local stts=$("$STATUS" "$MMSSRVC")
    if [ ! -z "$stts" ]
    then
        if "$ECHO" "$stts" 2>&1 | "$GREP" -i 'start/running' > /dev/null 2>&1
        then
            if ! "$STOP" "$MMSSRVC"
            then
                exitOnErr "$STOP $MMSSRVC failed"
            else
                "$SLEEP" "$SLPSRVR"
            fi 
        fi
    fi

}

startMMS() {

    local stts=$("$STATUS" "$MMSSRVC")
    if [ ! -z "$stts" ]
    then
        if "$ECHO" "$stts" 2>&1 | "$GREP" -i 'stop/waiting' > /dev/null 2>&1
        then
            if ! "$START" "$MMSSRVC"
            then
                exitOnErr "$START $MMSSRVC failed"
            else
                "$SLEEP" "$SLPSRVR"
            fi 
        fi
    fi

}

cleanMMS() {

    "$RM" -rfv "/opt/$AGENTDIR"
    "$RM" -fv "$UPSTRTDIR/${MMSSRVC}.conf"
    "$RM" -fv "$MMSLGRTTE"
    
    #for p in $PIPPCKGS
    #do
    #    pip uninstall $p
    #done  

    for y in $YUMPCKGS
    do
        "$YUM" -y remove $y
    done

}

instlDeps() {

    local deprpm=''
    for y in $YUMPCKGS
    do
        deprpm=$("$RPM" -qa "$y")        
        if ! "$YUM" -y install "$y"
        then
            exitOnErr "$YUM -y install $y failed"
        fi
    done

    if ! easy_install pip
    then
        exitOnErr "The easy_install pip failed"
    fi

    for p in $PIPPCKGS
    do
        if ! pip install "$p"
        then
            exitOnErr "$YUM install $p failed"
        fi
    done

}

extrctMMS() {

    if ! "$TAR" -C '/opt' -zxvf "/tmp/$MMSTARBALL"
    then
        exitOnErr "$TAR -C /opt -zxvf /tmp/$MMSTARBALL failed"
    fi

}

instlMMS() {

    instlDeps
    extrctMMS

}

crteUpstrtCnf() {

    if [ ! -d "$UPSTRTDIR" ]
    then
        exitOnErr "$UPSTRTDIR does not exist"
    else
        if [ ! -e "$UPSTRTDIR/${MMSSRVC}.conf" ]
        then
            > "$UPSTRTDIR/${MMSSRVC}.conf"
            "$TEE" "$UPSTRTDIR/${MMSSRVC}.conf" <<EOF

            start on runlevel [35]
            stop on runlevel [!35]
            respawn
            exec $PYTHON /opt/$AGENTDIR/$MMSAGENT > $MMSLOGDIR/${MMSSRVC}.log 2>&1

EOF
        fi
    fi

}

setupMMSLgrttn() {

    if [ ! -f "$MMSLGRTTE" ]
    then
        > "$MMSLGRTTE"
        "$TEE" "$MMSLGRTTE" <<EOF
   
        $MMSLOGDIR/${MMSSRVC}.log {
        weekly
        rotate 5
        copytruncate
        missingok
        notifempty
        }

EOF
    fi

}

dumpInfo() {

    ls -lhrtR /opt/$AGENTDIR
    "$CAT" "$UPSTRTDIR/${MMSSRVC}.conf"
    "$CAT" "$MMSLGRTTE"
    "$PS" aux | "$GREP" -i python | "$GREP" -v grep

    "$TAIL" -n 15 "$MMSLOGDIR/${MMSSRVC}.log"

}

main() {

    preChecks

    if $INSTL
    then
        instlMMS
        dumpInfo
    fi

    if $CNFGR
    then
        crteUpstrtCnf
        setupMMSLgrttn
        dumpInfo
    fi

    if $DUMP
    then
        dumpInfo
    fi

    if $STARTR
    then
        startMMS
        dumpInfo
    fi

    if $STOPR
    then
        stopMMS
        dumpInfo
    fi

    if $ALL
    then
        instlMMS
        crteUpstrtCnf
        setupMMSLgrttn
        startMMS
        dumpInfo
    fi     

    if $CLEAN
    then
        stopMMS
        cleanMMS
        dumpInfo
    fi

}
# <end of helper section>


# <start of test section>

# <end of test section>


# <start of init section>

# <end of init section>


# <start of cleanup section>

# <end of cleanup section>


# <start of main section>
set -ux
main 2>&1 | "$TEE" "$PRGNME.log"
# <end of main section>

