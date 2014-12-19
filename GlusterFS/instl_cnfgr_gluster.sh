#! /usr/bin/env bash
############################################################################
# File name : instl_cnfgr_gluster.sh
# Purpose   : Install and configure GlusterFS on RHEL/CentOS 6.x (x>=4) for
#             a cluster configuration.
# Usages    : ./instl_cnfgr_gluster.sh <-i|--install|-c|--config|-d|--dump
#                                         |-e|--recnfg|-r|--clean
#                                         |-s|--start|-t|--stop|-a|--all>
#             (make it executable using chmod +x)
# Start date : 10/25/2013
# End date   : 10/xx/2013
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
RM=$(which rm)
WC=$(which wc)
MV=$(which mv)
CP=$(which cp)
DF=$(which df)
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
MOUNT=$(which mount)
IFCNFG=$(which ifconfig)
MKE2FS=$(which mke2fs)
CHOWN=$(which chown)
KLALL=$(which killall)
GFSCLI='gluster'
SWTCH="$1"
NUMARG=$#
PRGNME=$("$ECHO" $("$BSNME" "$0") | "$SED" -n 's/\.sh//p')
INSTL=false
CNFGR=false
DUMP=false
ALL=false
START=false
STOP=false
CLEAN=false
RECNFG=false
SLPSRVR=10
SLPFLSYS=5
IPTBLS='iptables'
GFSREPO='http://download.gluster.org/pub/gluster/glusterfs/LATEST/EPEL.repo/glusterfs-epel.repo'
YUMREPO='/etc/yum.repos.d'
FSTAB='/etc/fstab'
GFSMNGMT='glusterd'
GFSSRVR='glusterfsd'
GFSVOL='testvol'
GFSBRICK="/data/glusterfs/$GFSVOL/brick/brick1"
GFSDATA="/var/lib/$GFSMNGMT"
RECNFGCNF='glusterfs.conf'
# <end of global section>


# <start of helper section>
exitOnErr() {

    local date=$($DATE)
    "$ECHO" " Error: <$date> $1, exiting ..."
    exit 1

}

prntUsage() {

    "$ECHO" "Usages: $PRGNME <-i|--install|-c|--config|-d|--dump"
    "$ECHO" "                |-e|--recnfg|-r|--clean|-a|--all>"
    "$ECHO" "        -i|--install Install GlusterFS,"
    "$ECHO" "        -c|--config  Configure GlusterFS post install,"
    "$ECHO" "        -d|--dump    Dump various GlusterFS related info,"
    "$ECHO" "        -s|--start   Start GlusterFS,"
    "$ECHO" "        -t|--stop    Stop GlusterFS,"
    "$ECHO" "        -r|--clean   Remove GlusterFS from node,"
    "$ECHO" "        -e|--recnfg  Reconfigure GlusterFS cluster,"
    "$ECHO" "        -a|--all     Install+Configure+Dump GlusterFS,"
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
    elif [ "$SWTCH" = "-s" ] || [ "$SWTCH" = "--start" ]
    then
        START=true
    elif [ "$SWTCH" = "-t" ] || [ "$SWTCH" = "--stop" ]
    then
        STOP=true
    elif [ "$SWTCH" = "-r" ] || [ "$SWTCH" = "--clean" ]
    then
        CLEAN=true
    elif [ "$SWTCH" = "-e" ] || [ "$SWTCH" = "--recnfg" ]
    then
        RECNFG=true
    else
        prntUsage
    fi

}

preChecks() {

    if [ "$EUID" -ne 0 ]
    then
        exitOnErr "This script needs superuser rights"
    fi

    parseArgs

    if ! "$CURL" www.richnusgeeks.me > /dev/null 2>&1
    then
        exitOnErr "Check your internet/dns settings"
    fi

    "$SRVC" "$IPTBLS" stop
    "$SRVC" "$IPTBLS" status

    "$CHKCNFG" "$IPTBLS" off
    "$CHKCNFG" --list "$IPTBLS"

}

instlGFS() {

    local gfsrepo=$("$BSNME" "$GFSREPO")
    local gfspkg=$("$RPM" -qa '*glusterfs-server*')
    if [ -z "$gfspkg" ]
    then
        if [ ! -e "$GFSREPO" ]
        then
            if ! "$WGET" -P "$YUMREPO" "$GFSREPO"
            then
                exitOnErr "$WGET -P $YUMREPO $GFSREPO failed"
            else
                if ! "$YUM" -y install glusterfs{-fuse,-server}
                then
                    exitOnErr "$YUM -y install glusterfs{-fuse,-server} failed"
                fi
            fi
        fi
    fi

    "$SLEEP" "$SLPFLSYS"

}

cnfgrGFS() {

    # TODO: Refine logic more to check on/off state.
    if "$CHKCNFG" --list | "$GREP" -i "$GFSMNGMT" > /dev/null 2>&1
    then
        if ! "$CHKCNFG" "$GFSMNGMT" on
        then
            exitOnErr "$CHKCNFG $GFSMNGMT on failed" 
        fi
    fi

    "$MKDR" -p "$GFSBRICK"

}

startGFS() {

    if ! "$SRVC" "$GFSMNGMT" status
    then
        if ! "$SRVC" "$GFSMNGMT" start
        then
            exitOnErr "$SRVC $GFSMNGMT start failed"
        else
            "$SLEEP" "$SLPSRVR"
        fi
    fi   

}

stopGFS() {

    if "$SRVC" "$GFSMNGMT" status
    then
        "$SRVC" "$GFSMNGMT" stop
        # XXX: Why service stop returns non-zero status?
        #if ! "$SRVC" "$GFSMNGMT" stop
        #then
        #    exitOnErr "$SRVC $GFSMNGMT stop failed"
        #else
            "$SLEEP" "$SLPSRVR"
        #fi
    fi   

}

cleanGFS() {

    local gfsrepo=$("$BSNME" "$GFSREPO")
    local gfspkg=$("$RPM" -qa '*glusterfs*')
    if [ ! -z "$gfspkg" ]
    then
        if ! "$YUM" -y remove glusterfs{,-fuse,-server,-cli,-libs}
        then
            exitOnErr "$YUM -y remove glusterfs{,-fuse,-server,-cli,-libs} failed"
        else
            "$SLEEP" "$SLPFLSYS"
        fi 
    fi

    "$KLALL" glusterfs
    eval "$RM" -fv "$YUMREPO/$gfsrepo*"
    "$RM" -rfv '/data'
    "$RM" -rfv "$GFSDATA"
    

}

dumpGFS() {

    "$RPM" -qa "*glusterfs*" 
    "$CHKCNFG" --list "$GFSMNGMT"

    "$DF" -kh
    "$NTST" -nlptu | "$GREP" 'gluster'
    
    "$GFSCLI" peer status 
    "$GFSCLI" volume info 

}

recnfgGFS() {

    startGFS

    if [ ! -f "/tmp/$RECNFGCNF" ]
    then
        exitOnErr "Required /tmp/$RECNFGCNF not found"
    fi

    local s=''
    local ndsips=$("$SED" -n 's/^ *NODESIPS *= *//p' "/tmp/$RECNFGCNF")
    if [ ! -z "$ndsips" ]
    then

        for i in $ndsips
        do
            if ! "$GFSCLI" peer probe "$i"
            then
                exitOnErr "$GFSCLI peer $i failed"
            else
                "$SLEEP" "$SLPFLSYS"
            fi        
        
            s+="$i:$GFSBRICK "
        done

        s=$("$ECHO" "$s" | "$SED" 's/ \{1,\}$//')

    fi

    if ! eval "$GFSCLI" volume create "$GFSVOL" replica 2 "$s"
    then
        exitOnErr "$GFSCLI volume create $GFSVOL replica 2 $s failed"
    else
        "$SLEEP" "$SLPFLSYS"
    fi

    if ! "$GFSCLI" volume start "$GFSVOL"
    then
        exitOnErr "$GFSCLI volume start $GFSVOL failed"
    else
        "$SLEEP" "$SLPFLSYS"
    fi

}

main() {

    preChecks

    if $INSTL
    then
        instlGFS
        dumpGFS
    fi

    if $CNFGR
    then
        cnfgrGFS
        dumpGFS
    fi

    if $DUMP
    then
        dumpGFS
    fi

    if $ALL
    then
        instlGFS
        cnfgrGFS
        startGFS
        dumpGFS
    fi

    if $START
    then
        startGFS
    fi

    if $STOP
    then
        stopGFS
    fi

    if $CLEAN
    then
        stopGFS
        cleanGFS
        dumpGFS
    fi

    if $RECNFG
    then
        recnfgGFS
        dumpGFS
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

