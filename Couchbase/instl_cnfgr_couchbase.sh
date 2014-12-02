#! /usr/bin/env bash
############################################################################
# File name : instl_cnfgr_couchbase.sh
# Purpose   : Install and configure Couchbase Server on CentOS 6.x (x>=3) for
#             an HA cluster.
# Usages    : ./instl_cnfgr_couchbase.sh <-i|--install|-c|--config|
#                                             -d|--dump|-r|--nodes|-a|--all
#                                             -n|--clean>
#             (make it executable using chmod +x)
# Start date : 08/28/2013
# End date   : 08/28/2013
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
NDS=false
SLPFLSYS=5
SLPSRVR=25
RAMQUOTA='0.75'
DOSHARE=0.02
DOBCKT='bucket1'
NGRLSHARE=0.05
NGRLBCKT='bucket2'
NGRLPSWRD='password2'
EBSSHARE=0.02
EBSBCKT='bucket3'
EBSPSWRD='password3'
ZIPSHARE=0.90
ZIPBCKT='bucket4'
ZIPPSWRD='password4'
NUMRPLCA=2
MEMINFO='/proc/meminfo'
OSL098e='openssl098e'
CBSSRVR='couchbase-server'
CBSCELNK='http://packages.couchbase.com/releases/2.1.1/couchbase-server-community_x86_64_2.1.1.rpm'
IPTBLS='iptables'
ADMNUSRID='Administrator'
ADMNPSWRD=''
CBSRTPTH='/opt/couchbase'
CBSDATAPTH='/opt/couchbase/var/lib/couchbase/data'
CBSCLI='couchbase-cli'
CLSTRPRT=8091
RBLNCNDSFL='nodes2add.conf'
# <end of global section>


# <start of helper section>
exitOnErr() {

    local date=$($DATE)
    "$ECHO" " Error: <$date> $1, exiting ..."
    exit 1

}

prntUsage() {

    "$ECHO" "Usages: $PRGNME <-i|--install|-c|--config|-d|--dump|-a|--all>"
    "$ECHO" "        -i|--install Install Couchbase,"
    "$ECHO" "        -c|--config  Configure Couchbase post install,"
    "$ECHO" "        -n|--clean   Remove Couchbase from node,"
    "$ECHO" "        -d|--dump    Dump various Couchbase related info,"
    "$ECHO" "        -a|--all     Install+Configure+Dump Couchbase,"
    "$ECHO" "        -r|--nodes   Add nodes and rebalance Couchbase cluster,"
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
    elif [ "$SWTCH" = "-r" ] || [ "$SWTCH" = "--nodes" ]
    then
        NDS=true
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

    local osl098erpm=$("$RPM" -qa "*$OSL098e*")
    if [ -z "$osl098erpm" ]
    then
        "$YUM" install -y "$OSL098e.x86_64"
        if [ $? -ne 0 ]
        then
            exitOnErr "$YUM install -y $OSL098e.x86_64 failed"
        fi 

        "$RPM" -qa "*$OSL098e*" 
    fi

}

instlCBSE() {

    local cbscerpm=$("$BSNME" "$CBSCELNK")

    local cbrpm=$("$RPM" -qa 'couchbase*')
    if [ -z "$cbrpm" ]
    then
        if [ ! -f "$cbscerpm" ]
        then
    
            "$WGET" "$CBSCELNK"
            if [ $? -ne 0 ]
            then
                exitOnErr "$WGET $CBSCELNK failed"
            fi

            if [ -f "$cbscerpm" ]
            then
                "$RPM" -Uvh "$cbscerpm"
                if [ $? -ne 0 ]
                then
                    exitOnErr "$RPM -Uvh $cbscerpm failed"
                fi

            fi
        else
            "$RPM" -Uvh "$cbscerpm"
            if [ $? -ne 0 ]
            then
                exitOnErr "$WGET $CBSCELNK failed"
            fi

        fi
    fi

    "$SLEEP" "$SLPSRVR"

}

cleanCBSE() {

    local cbrpm=$("$RPM" -qa 'couchbase*')
    if [ ! -z "$cbrpm" ]
    then
        "$RPM" -e "$cbrpm"        
    fi

    "$RM" -rfv "$CBSRTPTH"

}

ramQuota() {

    local mem=$("$GREP" -i memtotal "$MEMINFO" | "$AWK" '{print $2}')
    if [ $? -ne 0 ]
    then
        exitOnErr "Total System RAM deduction failed"
    fi

    "$ECHO" $("$PYTHON" -c "print int(($mem*$RAMQUOTA)/1024)")

}

ramDoQuota() {

    local mem=$(ramQuota)
    "$ECHO" $("$PYTHON" -c "print int($mem*$DOSHARE)")

}

ramDbsQuota() {

    local mem=$(ramQuota)
    "$ECHO" $("$PYTHON" -c "print int($mem*$DBSSHARE)")

}

ramNgrlQuota() {

    local mem=$(ramQuota)
    "$ECHO" $("$PYTHON" -c "print int($mem*$NGRLSHARE)")

}

ramZipQuota() {

    local mem=$(ramQuota)
    "$ECHO" $("$PYTHON" -c "print int($mem*$ZIPSHARE)")

}

ramEbsQuota() {

    local mem=$(ramQuota)
    "$ECHO" $("$PYTHON" -c "print int($mem*$EBSSHARE)")

}

dumpCBSE() {

    ls -lhrt $CBSRTPTH/*
    "$CHKCNFG" --list "$CBSSRVR"
    "$RPM" -qa '*couchbase*'
    "$NTST" -nlptu | "$GREP" -E '(4369|8091|8092)'
    "$NTST" -nlptu | "$GREP" '112[0-1][0-9]'
    "$NTST" -nlptu | "$GREP" '211[0-9][0-9]'
    "$CBSRTPTH/bin/$CBSCLI" server-info -c localhost \
                        -u "$ADMNUSRID" \
                        -p "$ADMNPSWRD"
    "$CBSRTPTH/bin/$CBSCLI" bucket-list -c localhost \
                        -u "$ADMNUSRID" \
                        -p "$ADMNPSWRD"

}

cnfgrCBSE() {

    local mem=$(ramQuota)
    local do=$(ramDoQuota)
    #local dbs=$(ramDbsQuota)
    local ngrl=$(ramNgrlQuota)
    local zip=$(ramZipQuota)
    local ebs=$(ramEbsQuota)

    if ! "$CBSRTPTH/bin/$CBSCLI" cluster-init -c 127.0.0.1 \
                        --cluster-init-username="$ADMNUSRID" \
                        --cluster-init-password="$ADMNPSWRD" \
                        --cluster-init-port="$CLSTRPRT" \
                        --cluster-init-ramsize="$mem" -d
    then
        exitOnErr "Cluster initialization failed"
    else
        "$SLEEP" "$SLPFLSYS"    
    fi

    if ! "$CBSRTPTH/bin/$CBSCLI" node-init -c localhost \
                        -u "$ADMNUSRID" \
                        -p "$ADMNPSWRD" \
                        --node-init-data-path="$CBSDATAPTH"
    then
        exitOnErr "Data path initialization failed"
    fi

    if ! "$CBSRTPTH/bin/$CBSCLI" bucket-create -c localhost \
                        -u "$ADMNUSRID" \
                        -p "$ADMNPSWRD" \
                        --bucket="$DOBCKT" \
                        --bucket-type=couchbase \
                        --bucket-ramsize="$do" \
                        --bucket-replica="$NUMRPLCA"
    then
        exitOnErr "bucket1 creation failed"    
    else
        "$SLEEP" "$SLPFLSYS"    
    fi

    if ! "$CBSRTPTH/bin/$CBSCLI" bucket-create -c localhost \
                        -u "$ADMNUSRID" \
                        -p "$ADMNPSWRD" \
                        --bucket="$NGRLBCKT" \
                        --bucket-type=couchbase \
                        --bucket-ramsize="$ngrl" \
                        --bucket-password="$NGRLPSWRD" \
                        --bucket-replica="$NUMRPLCA"
    then
        exitOnErr "bucket2 creation failed"    
    else
        "$SLEEP" "$SLPFLSYS"    
    fi

    if ! "$CBSRTPTH/bin/$CBSCLI" bucket-create -c localhost \
                        -u "$ADMNUSRID" \
                        -p "$ADMNPSWRD" \
                        --bucket="$ZIPBCKT" \
                        --bucket-type=couchbase \
                        --bucket-ramsize="$zip" \
                        --bucket-password="$ZIPPSWRD" \
                        --bucket-replica="$NUMRPLCA"
    then
        exitOnErr "bucket4 creation failed"    
    else
        "$SLEEP" "$SLPFLSYS"    
    fi

    if ! "$CBSRTPTH/bin/$CBSCLI" bucket-create -c localhost \
                        -u "$ADMNUSRID" \
                        -p "$ADMNPSWRD" \
                        --bucket="$EBSBCKT" \
                        --bucket-type=couchbase \
                        --bucket-ramsize="$ebs" \
                        --bucket-password="$EBSPSWRD" \
                        --bucket-replica="$NUMRPLCA"
    then
        exitOnErr "bucket3 creation failed"    
    else
        "$SLEEP" "$SLPFLSYS"    
    fi

}

addNodes() {

    if [ ! -d "$CBSRTPTH/bin" ]
    then
        exitOnErr "Couchbase runtime tree missing"
    fi

    if [ ! -f "$RBLNCNDSFL" ]
    then
        exitOnErr "Cluster nodes file $RBLNCNDSFL to add and rebalance not found"
    fi

    while read tag ip
    do

        if "$ECHO" "$tag" | "$GREP" -E '^ *#' > /dev/null 2>&1
        then
            continue
        fi

        "$CBSRTPTH/bin/$CBSCLI" rebalance -c localhost \
                                          -u "$ADMNUSRID" \
                                          -p "$ADMNPSWRD" \
                                          --server-add="$ip:$CLSTRPRT" \
                                          --server-add-username="$ADMNUSRID" \
                                          --server-add-password="$ADMNPSWRD"
        if [ $? -ne 0 ]
        then
            "$ECHO" "$tag addition to the cluster failed, moving to next node..."
        fi
                                          
    done < "$RBLNCNDSFL"

}

main() {

    preChecks

    if $INSTL
    then
        instlDeps
        instlCBSE
        dumpCBSE
    fi

    if $CNFGR
    then
        cnfgrCBSE
        dumpCBSE
    fi

    if $DUMP
    then
        dumpCBSE
    fi

    if $ALL
    then
        instlDeps
        instlCBSE
        cnfgrCBSE
        dumpCBSE
    fi

    if $NDS
    then
        addNodes
        dumpCBSE
    fi

    if $CLEAN
    then
        cleanCBSE
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

