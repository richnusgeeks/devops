#! /usr/bin/env bash
############################################################################
# File name : instl_remote_control.sh
# Purpose   : Install Python pieces required for Fabric and REST based
#             remote validation/monitoring tool(s).
# Usages    : ./instl_remote_control.sh <-i|--install|-r|--clean|-d|--dump>
#             (make it executable using chmod +x)
# Start date : 02/07/2014
# End date   : 02/xx/2014
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
RM=rm
TR=$(which tr)
MKDIR=$(which mkdir)
TAR=$(which tar)
CAT=$(which cat)
SED=$(which sed)
AWK=$(which awk)
TEE=$(which tee)
YUM=$(which yum)
RPM=$(which rpm)
DATE=$(which date)
ECHO=$(which echo)
WGET=$(which wget)
CHMOD=$(which chmod)
CHKCNFG=$(which chkconfig)
TAR=$(which tar)
BSNME=$(which basename)
SEQ=$(which seq)
TEE=$(which tee)
MKDR=$(which mkdir)
GREP=$(which grep)
NTST=$(which netstat)
CURL=$(which curl)
SRVC=$(which service)
SLEEP=$(which sleep)
PYTHON=$(which python)
SWTCH="$1"
NUMARG=$#
PRGNME=$("$ECHO" $("$BSNME" "$0") | "$SED" -n 's/\.sh//p')
REM=false
DUMP=false
INSTL=false
SLPFLSYS=5
IPTBLS='iptables'
SYSDEP="gcc \
        make \
        python-devel \
        python-psycopg2 \
        dos2unix"
PYTHONCMPS="Flask \
            pymongo \
            requests \
            redis \
            elasticsearch \
            colorama \
            fabric \
            Celery \
            Flower \
            pysphere \
            jenkinsapi"
# <end of global section>


# <start of helper section>
exitOnErr() {

    local date=$($DATE)
    "$ECHO" " Error: <$date> $1, exiting ..."
    exit 1

}

prntUsage() {

    "$ECHO" "Usages: $PRGNME <-i|--install|-r|--clean|-d|--dump>"
    "$ECHO" "        -i|--install Install RemoteControl components,"
    "$ECHO" "        -r|--clean   Cleanup RemoteControl components,"
    "$ECHO" "        -d|--dump    Dump various RemoteControl related info,"
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
    elif [ "$SWTCH" = "-d" ] || [ "$SWTCH" = "--dump" ]
    then
        DUMP=true
    elif [ "$SWTCH" = "-r" ] || [ "$SWTCH" = "--clean" ]
    then
        REM=true
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

    if $INSTL
    then
        "$SRVC" "$IPTBLS" stop
        "$SRVC" "$IPTBLS" status
        "$CHKCNFG" "$IPTBLS" off
    fi

    "$CHKCNFG" --list "$IPTBLS"

}

instlDeps() {

    for i in $SYSDEP
    do
        if ! "$YUM" -y install "$i"
        then
            exitOnErr "$YUM -y install $i failed"
        fi
    done 

}

removeDeps() {

    for i in $SYSDEP
    do
        if ! "$YUM" -y remove "$i"
        then
            exitOnErr "$YUM -y remove $i failed"
        fi
    done 

}

testPyMdls() {

    local module=''

    for mdl in $PYTHONCMPS
    do
        module=$($ECHO $mdl | $TR [:upper:] [:lower:] | "$SED" 's/python-//')        

        if ! eval "$PYTHON" -c "'import $module'"
        then
            "$ECHO" " Warning: Python module $mdl loading failed, is that installed?"
        fi 
    done

    if ! "$PYTHON" -c 'import psycopg2'
    then
        "$ECHO" " Warning: Python module psycopg2 loading failed, is that installed?"
    fi

}

instlPycmps() {

    # XXX: Way to fix pip module load error http://stackoverflow.com/questions/7446187/no-module-named-pkg-resources.
    "$CURL" https://bitbucket.org/pypa/setuptools/raw/bootstrap/ez_setup.py | "$PYTHON"

    if ! "$YUM" -y install python-pip
    then
        exitOnErr "$YUM -y install python-pip"
    fi

    for dep in $PYTHONCMPS
    do
        if ! pip install -U "$dep"
        then
            exitOnErr "pip install -U $dep failed"
        fi
done 

}

removePycmps() {

    # XXX: Way to fix pip module load error http://stackoverflow.com/questions/7446187/no-module-named-pkg-resources.
    "$CURL" https://bitbucket.org/pypa/setuptools/raw/bootstrap/ez_setup.py | "$PYTHON"

    for dep in $PYTHONCMPS
    do
        if ! pip uninstall -y "$dep"
        then
            exitOnErr "pip uninstall $dep failed"
        fi
done

    "$YUM" -y remove python-pip

}

dumpRmtCtrl() {

    testPyMdls

}

clnupRmtCtrl() {

    removePycmps
 
}

main() {

    preChecks

    if $INSTL
    then
        instlDeps
        instlPycmps
        dumpRmtCtrl
    fi

    if $DUMP
    then
        dumpRmtCtrl
    fi

    if $REM
    then
        removeDeps
        removePycmps
        dumpRmtCtrl
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

