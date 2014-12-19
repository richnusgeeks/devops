#! /usr/bin/env bash
############################################################################
# File name : instl_cnfgr_gluster_client.sh
# Purpose   : Install and configure GlusterFS client on RHEL/CentOS 6.x (x>=4)
#             for a cluster configuration.
# Usages    : ./instl_cnfgr_gluster_client.sh <-i|--install|-c|--config|
#                                              -d|--dump|-e|--recnfg|
#                                              -r|--clean|-a|--all>
#             (make it executable using chmod +x)
# Start date : 10/29/2013
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
BSNME=$(which basename)
MKDR=$(which mkdir)
GREP=$(which grep)
SRVC=$(which service)
CURL=$(which curl)
SLEEP=$(which sleep)
MOUNT=$(which mount)
UMOUNT=$(which umount)
MKE2FS=$(which mke2fs)
CHMOD=$(which chmod)
MDPRB=$(which modprobe)
LSMOD=$(which lsmod)
GFSCLI='gluster'
SWTCH="$1"
NUMARG=$#
PRGNME=$("$ECHO" $("$BSNME" "$0") | "$SED" -n 's/\.sh//p')
INSTL=false
CNFGR=false
DUMP=false
ALL=false
CLEAN=false
RECNFG=false
SLPSRVR=10
SLPFLSYS=5
IPTBLS='iptables'
GFSREPO='http://download.gluster.org/pub/gluster/glusterfs/LATEST/EPEL.repo/glusterfs-epel.repo'
YUMREPO='/etc/yum.repos.d'
FSTAB='/etc/fstab'
MDPRBCNF='/etc/sysconfig/modules/fuse.modules'
GFSVOL='testvol'
GFSDATA="/var/lib/$GFSMNGMT"
GFSMNTDIR="/mnt/glusterfs/$GFSVOL"
RECNFGCNF='glusterfs.conf'
GFSCLNTLOG='/var/log/gluster.log'
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
    "$ECHO" "        -i|--install Install GlusterFS Client,"
    "$ECHO" "        -c|--config  Configure GlusterFS Client post install,"
    "$ECHO" "        -d|--dump    Dump various GlusterFS Client related info,"
    "$ECHO" "        -r|--clean   Remove GlusterFS Client from node,"
    "$ECHO" "        -e|--recnfg  Reconfigure GlusterFS Client cluster,"
    "$ECHO" "        -a|--all     Install+Configure+Dump GlusterFS Client,"
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
 
    local fsepkg=$("$RPM" -qa '*fuse*')
    if [ -z "$fsepkg" ]
    then
        if ! "$YUM" -y install fuse{,-libs}
        then
            exitOnErr "$YUM -y install fuse{,-libs} failed"
        fi
    fi

    local gfspkg=$("$RPM" -qa '*glusterfs*')
    if [ -z "$gfspkg" ]
    then
        if [ ! -e "$GFSREPO" ]
        then
            if ! "$WGET" -P "$YUMREPO" "$GFSREPO"
            then
                exitOnErr "$WGET -P $YUMREPO $GFSREPO failed"
            else
                if ! "$YUM" -y install glusterfs{,-fuse}
                then
                    exitOnErr "$YUM -y install glusterfs{,-fuse} failed"
                fi
            fi
        fi
    fi

    "$SLEEP" "$SLPFLSYS"

}

ldmdlFUSE() {

    if ! "$MDPRB" fuse
    then
        exitOnErr "$MDPRB fuse failed"
    fi

    if [ ! -f "$MDPRBCNF" ]
    then
        > "$MDPRBCNF"
        "$ECHO" '#! /bin/sh' >> "$MDPRBCNF"
        "$ECHO" 'exec /sbin/modprobe fuse' >> "$MDPRBCNF"
    # TODO: Fill for case when file exists but not the entry(ies).
    # else
    fi

    if ! "$CHMOD" +x "$MDPRBCNF"
    then
        exitOnErr "$CHMOD +x $MDPRBCNF failed"
    fi

}

cnfgrGFS() {

    ldmdlFUSE
    "$MKDR" -p "$GFSMNTDIR"

}

cleanGFS() {

    local gfsrepo=$("$BSNME" "$GFSREPO")
    local gfspkg=$("$RPM" -qa '*glusterfs*')
    if [ ! -z "$gfspkg" ]
    then
        if ! "$YUM" -y remove glusterfs{,-fuse,-libs}
        then
            exitOnErr "$YUM -y remove glusterfs{,-fuse,-cli,-libs} failed"
        else
            "$SLEEP" "$SLPFLSYS"
        fi 
    fi

    eval "$RM" -fv "$YUMREPO/$gfsrepo*"
    
    if "$UMOUNT" "$GFSMNTDIR"
    then
        "$SLEEP" "$SLPFLSYS"
        "$RM" -rfv "$GFSMNTDIR"
    fi

    "$RM" -fv "$MDPRBCNF"
    "$RM" -rfv "$GFSMNTDIR"
    "$SED" -i '/glusterfs/d' "$FSTAB"
    "$MOUNT" -a

}

dumpGFS() {

    "$RPM" -qa "*glusterfs*"
    "$LSMOD" | "$GREP" fuse 

    "$GREP" glusterfs "$FSTAB"
    "$DF" -kh

    "$CAT" "$MDPRBCNF"
    ls -lhrRt "$GFSMNTDIR"
    
}

recnfgGFS() {

    if [ ! -f "/tmp/$RECNFGCNF" ]
    then
        exitOnErr "Required /tmp/$RECNFGCNF not found"
    fi

    local ndsips=$("$SED" -n 's/^ *NODESIPS *= *//p' "/tmp/$RECNFGCNF")
    if [ ! -z "$ndsips" ]
    then

        for i in $ndsips
        do
            if ! "$GREP" -E "^ *$i:/$GFSVOL $GFSMNTDIR glusterfs defaults,_netdev,log-level=WARNING,log-file=$GFSCLNTLOG 0 0" "$FSTAB"
            then
                "$ECHO" "$i:/$GFSVOL $GFSMNTDIR glusterfs defaults,_netdev,log-level=WARNING,log-file=$GFSCLNTLOG 0 0" >> "$FSTAB"
            fi

            break
        done

        "$MOUNT" -a

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
        dumpGFS
    fi

    if $CLEAN
    then
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

