#! /usr/bin/env bash
############################################################################
# File name : instl-cnfgr-mongo.sh
# Purpose   : Install and configure MongoDB on CentOS 6.x (x>=3).
# Usages    : ./instl-cnfgr-mongo.sh <-i|--install|-c|--config|-d|--dump|
#                                     -r|--clean|-a|--all>
#             (make it executable using chmod +x)
# Start date : 02/21/2014
# End date   : 02/2x/2014
# Author : Ankur Kumar <richnusgeeks@gmail.com>
# Download link : www.richnusgeeks.me
# License : RichNusGeeks
# Version : 0.0.1
# Modification history :
# Notes : 
############################################################################
# <start of include section>

# <end of include section>


# <start of global section>
unalias rm
RM=$(which rm)
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
SWTCH="$1"
NUMARG=$#
PRGNME=$("$ECHO" $("$BSNME" "$0") | "$SED" -n 's/\.sh//p')
INSTL=false
CNFGR=false
CLEAN=false
DUMP=false
ALL=false
IPTBLS='iptables'
MONGOLNK='http://downloads-distro.mongodb.org/repo/redhat/os/x86_64/RPMS/'
MONGO='mongo-10gen-2.4.6-mongodb_1.x86_64'
MONGOSRVR='mongo-10gen-server-2.4.6-mongodb_1.x86_64'
DBLOC='/var/lib/mongo'
LOGLOC='/var/log/mongo'
SLPFLSYS=5
SLPSRVR=10
MONGOPRT=27017
# <end of global section>


# <start of helper section>
exitOnErr() {

    local date=$($DATE)
    "$ECHO" " Error: <$date> $1, exiting ..."
    exit 1

}

prntUsage() {

    "$ECHO" "Usages: $PRGNME <-i|--install|-c|--config|-d|--dump|-a|--all>"
    "$ECHO" "        -i|--install Install MongoDB,"
    "$ECHO" "        -c|--config  Configure MongoDB post install,"
    "$ECHO" "        -n|--clean   Remove MongoDB from node,"
    "$ECHO" "        -d|--dump    Dump various MongoDB related info,"
    "$ECHO" "        -a|--all     Install+Configure+Dump MongoDB,"
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
    elif [ "$SWTCH" = "-n" ] ||  [ "$SWTCH" = "--clean" ]
    then
        CLEAN=true
    elif [ "$SWTCH" = "-d" ] || [ "$SWTCH" = "--dump" ]
    then
        DUMP=true
    elif [ "$SWTCH" = "-a" ] || [ "$SWTCH" = "--all" ]
    then
        ALL=true
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

    if $INSTL || $ALL
    then
        "$SRVC" "$IPTBLS" stop
        "$SRVC" "$IPTBLS" status

        "$CHKCNFG" "$IPTBLS" off
        "$CHKCNFG" --list "$IPTBLS"
    fi

}

instlDeps() {

    local mongo=$("$RPM" -qa "$MONGO")
    if [ -z "$mongo" ]
    then
        if [ ! -e "${MONGO}.rpm" ]
        then
            if ! "$WGET" "$MONGOLNK/${MONGO}.rpm"
            then
                exitOnErr "$WGET $MONGOLNK/${MONGO}.rpm failed"
            else
                "$SLEEP" "$SLPFLSYS" 
            fi
        else
            if ! "$RPM" -Uvh "${MONGO}.rpm"
            then
                exitOnErr "$RPM" -Uvh "${MONGO}.rpm failed"
            fi
        fi
    fi 

}

instlMongo() {

    local mongosrvr=$("$RPM" -qa "$MONGOSRVR")
    if [ -z "$mongosrvr" ]
    then
        if [ ! -e "${MONGOSRVR}.rpm" ]
        then
            if ! "$WGET" "$MONGOLNK/${MONGOSRVR}.rpm"
            then
                exitOnErr "$WGET $MONGOLNK/${MONGOSRVR}.rpm failed"
            else
                "$SLEEP" "$SLPFLSYS" 
            fi
        else
            if ! "$RPM" -Uvh "${MONGOSRVR}.rpm"
            then
                exitOnErr "$RPM" -Uvh "${MONGOSRVR}.rpm failed"
            fi
        fi
    fi 

}

stopMongo(){

    if "$SRVC" mongod status
    then
        if ! "$SRVC" mongod stop
        then
            exitOnErr "$SRVC mongod stop failed"
        else
            "$SLEEP" "$SLPSRVR"
        fi
    fi

}

startMongo(){

    if ! "$SRVC" mongod status
    then
        if ! "$SRVC" mongod start
        then
            exitOnErr "$SRVC mongod start failed"
        else
            "$SLEEP" "$SLPSRVR"
        fi
    fi

}

cleanMongo() {

    "$RPM" -e "$MONGO" "$MONGOSRVR"        
    "$RM" -rfv "$DBLOC" "$LOGLOC"

}

dumpMongo() {

    "$RPM" -qa 'mongo*'
    "$CHKCNFG" --list mongod

    ls -lhrt "$DBLOC" "$LOGLOC"

    "$NTST" -nlptu | "$GREP" mongod
     mongo --eval 'printjson(rs.status())'

}

cnfgrMongo() {

    true

}

main() {

    preChecks

    if $INSTL
    then
        instlDeps
        instlMongo
        dumpMongo
    fi

    if $CNFGR
    then
        cnfgrMongo
        dumpMongo
    fi

    if $DUMP
    then
        dumpMongo
    fi

    if $ALL
    then
        instlDeps
        instlMongo
        cnfgrMongo
        startMongo
        dumpMongo
    fi

    if $CLEAN
    then
        stopMongo
        cleanMongo
        dumpMongo
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

