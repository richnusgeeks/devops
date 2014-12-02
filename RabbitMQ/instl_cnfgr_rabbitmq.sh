#! /usr/bin/env bash
############################################################################
# File name : instl_cnfgr_rabbitmq.sh
# Purpose   : Install and configure RabbitMQ node on SWLab CentOS 6.x (x>=4)
#             for an HA cluster.
# Usages    : ./instl_cnfgr_rabbitmq.sh <-i|--install|-c|--config|-d|--dump
#                                        |-j|--join|-e|--leave|-s|--start|-t
#                                        |--stop|-r|--delete|-a|--all>
#             (make it executable using chmod +x)
# Start date : 06/07/2013
# End date   : 06/xx/2013
# Author : Ankur Kumar <richnusgeeks@gmail.com>
# Download link : www.richnusgeeks.me
# License : RichNusGeeks
# Version : 0.0.1
# Modification history :  1. Addition of more stuff in the cleanup routine,
# Notes : 
############################################################################
# <start of include section>

# <end of include section>


# <start of global section>
unalias rm
RM=$(which rm)
WC=$(which wc)
MV=$(which mv)
CP=$(which cp)
CAT=$(which cat)
SED=$(which sed)
AWK=$(which awk)
TEE=$(which tee)
YUM=$(which yum)
RPM=$(which rpm)
DATE=$(which date)
ECHO=$(which echo)
WGET=$(which wget)
CHKCNFG=$(which chkconfig)
TAR=$(which tar)
BSNME=$(which basename)
SEQ=$(which seq)
TEE=$(which tee)
MKDR=$(which mkdir)
GREP=$(which grep)
NTST=$(which netstat)
SRVC=$(which service)
CURL=$(which curl)
PIDOF=$(which pidof)
SLEEP=$(which sleep)
INTCTL=$(which initctl)
PYTHON=$(which python)
KILL=$(which kill)
CHMOD=$(which chmod)
CHOWN=$(which chown)
SWTCH="$1"
NUMARG=$#
PRGNME=$("$ECHO" $("$BSNME" "$0") | "$SED" -n 's/\.sh//p')
INSTL=false
CNFGR=false
DUMP=false
ALL=false
JOIN=false
START=false
STOP=false
REM=false
LEAVE=false
SLPPRD=25
IPTBLS='iptables'
RBTMQSRVR='rabbitmq-server'
RBTMQLNK='http://www.rabbitmq.com/releases/rabbitmq-server/v3.0.2/rabbitmq-server-3.0.2-1.noarch.rpm'
EPELRPM='http://download.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm'
RBTMQCTL='/usr/sbin/rabbitmqctl'
RBTMQPLGN='/usr/sbin/rabbitmq-plugins'
RBTMQCKEPTH='/var/lib/rabbitmq'
RBTMQCKE='.erlang.cookie'
CLSTRCKE="/home/ec2-user/$RBTMQCKE"
CLSTRNDFL='node2join.conf'
ERLRT='epmd'
ERLRTDIR='/usr/lib64/erlang'
RMQCNFDIR='/etc/rabbitmq'
RMQDTADIR='/var/lib/rabbitmq'
# <end of global section>


# <start of helper section>
exitOnErr() {

    local date=$($DATE)
    "$ECHO" " Error: <$date> $1, exiting ..."
    exit 1

}

prntUsage() {

    "$ECHO" "Usages: $PRGNME <-i|--install|-c|--config|-d|--dump"
    "$ECHO" "                |-j|--join|-s|--start|-t|--stop|-a|--all>"
    "$ECHO" "        -i|--install Install RabbitMQ,"
    "$ECHO" "        -c|--cnfgr   Configure RabbitMQ post install,"
    "$ECHO" "        -d|--dump    Dump various RabbitMQ related info,"
    "$ECHO" "        -j|--join    Join RabbitMQ node(s) for HA cluster,"
    "$ECHO" "        -e|--leave   Leave RabbitMQ cluster,"
    "$ECHO" "        -s|--start   Start RabbitMQ server,"
    "$ECHO" "        -t|--stop    Stop RabbitMQ server,"
    "$ECHO" "        -r|--delete  Remove RabbitMQ RPM,"
    "$ECHO" "        -a|--all     Install+Configure+Start+Dump RabbitMQ,"
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
    elif [ "$SWTCH" = "-c" ] ||  [ "$SWTCH" = "--cnfgr" ]
    then
        CNFGR=true
    elif [ "$SWTCH" = "-d" ] || [ "$SWTCH" = "--dump" ]
    then
        DUMP=true
    elif [ "$SWTCH" = "-a" ] || [ "$SWTCH" = "--all" ]
    then
        ALL=true
    elif [ "$SWTCH" = "-j" ] || [ "$SWTCH" = "--join" ]
    then
        JOIN=true
    elif [ "$SWTCH" = "-s" ] || [ "$SWTCH" = "--start" ]
    then
        START=true
    elif [ "$SWTCH" = "-t" ] || [ "$SWTCH" = "--stop" ]
    then
        STOP=true
    elif [ "$SWTCH" = "-r" ] || [ "$SWTCH" = "--delete" ]
    then
        REM=true
    elif [ "$SWTCH" = "-e" ] || [ "$SWTCH" = "--leave" ]
    then
        LEAVE=true
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

    "$CURL" www.richnusgeeks.me > /dev/null 2>&1
    if [ $? -ne 0 ]
    then
        exitOnErr "Check your internet/dns settings"
    fi

    "$SRVC" "$IPTBLS" stop
    "$SRVC" "$IPTBLS" status

    "$CHKCNFG" "$IPTBLS" off
    "$CHKCNFG" --list "$IPTBLS"

}

instlDeps() {

    "$RPM" -Uvh "$EPELRPM"
    #if [ $? -ne 0 ]
    #then
    #    exitOnErr "$RPM -Uvh $EPELRPM failed"
    #fi

    "$YUM" -y install erlang
    if [ $? -ne 0 ]
    then
        exitOnErr "$YUM install erlang failed"
    fi

    "$YUM" -y install dos2unix
    if [ $? -ne 0 ]
    then
        exitOnErr "$YUM install dos2unix failed"
    fi

}

instlRBTMQ() {

    local rbtmqrpm=$("$BSNME" "$RBTMQLNK")

    local rmrpm=$("$RPM" -qa '*rabbitmq*')
    if [ -z "$rmrpm" ]
    then
        if [ ! -f "$rbtmqrpm" ]
        then
    
            "$WGET" "$RBTMQLNK"
            if [ $? -ne 0 ]
            then
                exitOnErr "$WGET $RBTMQLNK failed"
            fi

            if [ -f "$rbtmqrpm" ]
            then
                "$RPM" -Uvh "$rbtmqrpm"
                if [ $? -ne 0 ]
                then
                    exitOnErr "$RPM -Uvh $rbtmqrpm failed"
                fi

            fi
        else
            "$RPM" -Uvh "$rbtmqrpm"
            if [ $? -ne 0 ]
            then
                exitOnErr "$RPM -Uvh $rbtmqrpm failed"
            fi

        fi
    fi


}

dumpRBTMQ() {

    
    "$RPM" -qa '*rabbit*'
    "$CHKCNFG" --list "$RBTMQSRVR"
    "$NTST" -nlptu | "$GREP" beam
    "$NTST" -nlptu | "$GREP" epmd
    "$SRVC" "$RBTMQSRVR" status
    "$RBTMQCTL" report

}

cnfgrRBTMQ() {

    "$RBTMQPLGN" enable rabbitmq_management
    if [ $? -ne 0 ]
    then
        exitOnErr "$RBTMQPLGN enable rabbitmq_management failed"
    fi

    "$SLEEP" "$SLPPRD"
}

startRBTMQ() {

    "$SRVC" "$RBTMQSRVR" start
    if [ $? -ne 0 ]
    then
        exitOnErr "$SRVC $RBTMQSRVR start failed"
    fi

    "$CHKCNFG" "$RBTMQSRVR" on 
    if [ $? -ne 0 ]
    then
        exitOnErr "$CHKCNFG $RBTMQSRVR on failed"
    fi

    "$SLEEP" "$SLPPRD"

}

startRBTMQApp() {

    "$RBTMQCTL" start_app
    if [ $? -ne 0 ]
    then
        exitOnErr "$RBTMQCTL start_app"
    fi

    "$SLEEP" "$SLPPRD"

}

stopRBTMQ() {

    "$SRVC" "$RBTMQSRVR" stop
    if [ $? -ne 0 ]
    then
        exitOnErr "$SRVC $RBTMQSRVR stop failed"
    fi

    "$CHKCNFG" "$RBTMQSRVR" off
    if [ $? -ne 0 ]
    then
        exitOnErr "$CHKCNFG $RBTMQSRVR off failed"
    fi


    "$SLEEP" "$SLPPRD"

}

stopRBTMQApp() {

    "$RBTMQCTL" stop_app
    if [ $? -ne 0 ]
    then
        exitOnErr "$RBTMQCTL stop_app"
    fi

    "$SLEEP" "$SLPPRD"

}

clnupRBTMQ() {

    local rbtmqpkg=$("$BSNME" "$RBTMQLNK" | "$SED" -ne 's/\.rpm//p')
    if [ ! -z "$rbtmqpkg" ]
    then
     
        if ! "$RPM" -e "$rbtmqpkg"
        then
            exitOnErr "$RPM -e $rbtmqpkg failed"
        fi 

    fi

    local erlpkgs=$("$RPM" -qa 'erlang*')
    if [ ! -z "$erlpkgs" ]
    then
        "$YUM" remove -y $erlpkgs
    fi

    "$RM" -rf "$ERLRTDIR"
    "$KILL" -SIGKILL $("$PIDOF" "$ERLRT")
    
    "$RM" -rf "$RMQCNFDIR"
    "$RM" -rf "$RMQDTADIR"

}

joinMQClstr() {

    if [ ! -f "$RBTMQCKEPTH/$RBTMQCKE" ]
    then
        exitOnErr "RabbitMQ local cookie $RBTMQCKEPTH/$RBTMQCKE missing"
    fi

    if [ ! -f "$CLSTRNDFL" ]
    then
        exitOnErr "Cluster node to join file $CLSTRNDFL not found"
    else
        dos2unix "$CLSTRNDFL"
    fi

    if [ ! -f "$CLSTRCKE" ]
    then
        exitOnErr "Cluster cookie $CLSTRCKE not found"
    else
        dos2unix "$CLSTRCKE"
    fi

    while read tag host
    do

        if "$ECHO" "$tag" | "$GREP" -E '^ *#' > /dev/null 2>&1
        then
            continue
        fi

        if "$ECHO" "$tag" | "$GREP" -E '^$' > /dev/null 2>&1
        then
            continue
        fi

        stopRBTMQApp

        "$MV" -f "$CLSTRCKE" "$RBTMQCKEPTH/$RBTMQCKE"
        if [ $? -ne 0 ]
        then
            "$ECHO" "Making $CLSTRCKE the node $RBTMQCKEPTH/$RBTMQCKE failed ..."
        fi
   
        "$SLEEP" "$SLPPRD"
 
        "$CHMOD" 400 "$RBTMQCKEPTH/$RBTMQCKE"    
        if [ $? -ne 0 ]
        then
            "$ECHO" "$CHMOD 400 $RBTMQCKEPTH/$RBTMQCKE failed"
        fi

        "$SLEEP" "$SLPPRD"

        "$CHOWN" rabbitmq:rabbitmq "$RBTMQCKEPTH/$RBTMQCKE"    
        if [ $? -ne 0 ]
        then
            "$ECHO" "$CHOWN rabbitmq:rabbitmq $RBTMQCKEPTH/$RBTMQCKE failed"
        fi

        "$SLEEP" "$SLPPRD"

        "$RBTMQCTL" join_cluster "$host" 
        if [ $? -ne 0 ]
        then
            "$ECHO" "Cluster formation with $tag : $host failed"
        fi

        "$SLEEP" "$SLPPRD"

        startRBTMQApp
                                          
    done < "$CLSTRNDFL"

}

leaveMQClstr() {

    stopRBTMQApp

    "$RBTMQCTL" reset
    if [ $? -ne 0 ]
    then
       "$ECHO" "Leaving cluster failed"
    fi

    startRBTMQApp

}

main() {

    preChecks

    if $INSTL
    then
        instlDeps
        instlRBTMQ
        dumpRBTMQ
    fi

    if $CNFGR
    then
        cnfgrRBTMQ
        dumpRBTMQ
    fi

    if $DUMP
    then
        dumpRBTMQ
    fi

    if $ALL
    then
        instlDeps
        instlRBTMQ
        cnfgrRBTMQ
        startRBTMQ
        dumpRBTMQ
    fi

    if $JOIN
    then
        joinMQClstr
        dumpRBTMQ
    fi

    if $START
    then
        startRBTMQ
        dumpRBTMQ
    fi

    if $STOP
    then
        stopRBTMQ
        dumpRBTMQ
    fi

    if $REM
    then
        stopRBTMQ
        clnupRBTMQ
        dumpRBTMQ
    fi

    if $LEAVE
    then
        leaveMQClstr
        dumpRBTMQ
    fi

}
# <end of helper section>


# <start of init section>
# init() {

    
#}
# <end of init section>


# <start of test section>
# testCBSCE() {


#}
# <end of test section>


# <start of cleanup section>
# cleanup() {




#}
# <end of cleanup section>


# <start of main section>
set -ux
main 2>&1 | "$TEE" "$PRGNME.log"
# <end of main section>

