#! /usr/bin/env bash
############################################################################
# File name : instl-cnfgr-redis.sh
# Purpose   : Install and configure redis on RHEL/CentOS 6.x (x>=4)
#             instance.
# Usages    : ./instl-cnfgr-redis.sh <-i|--install|-c|--config|-d|--dump
#                                     |-s|--start|-t|--stop|-a|--all
#                                     |-r|--clean|-e|--recnfg>
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
MV=$(which mv)
WC=$(which wc)
RM=$(which rm)
CAT=$(which cat)
SED=$(which sed)
AWK=$(which awk)
TEE=$(which tee)
YUM=$(which yum)
RPM=$(which rpm)
TAR=$(which tar)
TEE=$(which tee)
ECHO=$(which echo)
WGET=$(which wget)
MKDR=$(which mkdir)
GREP=$(which grep)
NTST=$(which netstat)
SRVC=$(which service)
DATE=$(which date)
TAIL=$(which tail)
SLEEP=$(which sleep)
BSNME=$(which basename)
CHKCNFG=$(which chkconfig)
SWTCH="$1"
NUMARG=$#
PRGNME=$("$ECHO" $("$BSNME" "$0") | "$SED" -n 's/\.sh//p')
STOP=stop
START=start
STATUS=status
IPTBLS='iptables'
RDSPRT=6379
SLPSRVR=10
SLPFLSYS=5
RDSRT='redis-2.6.10'
RDSCNF='redis.conf'
SLAVECNF='slave.conf'
RDSBINDIR='/usr/local/bin'
RDSCNFDIR='/etc/redis'
RDSDTADIR='/var/lib/redis'
RDSLOGDIR='/var/log/redis'
UPSTRTDIR='/etc/init'
RDSLGRTTE='/etc/logrotate.d/redis'
BLDESNTLS='Development tools'
LNKRDS="http://redis.googlecode.com/files/$RDSRT.tar.gz"
ALL=false
DUMP=false
STOPR=false
STARTR=false
INSTL=false
CLEAN=false
CNFGR=false
RECNFG=false
RDSBNRS="redis-server \
         redis-cli \
         redis-benchmark \
         redis-check-dump \
         redis-check-aof"
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
    "$ECHO" "        -i|--install Install Redis,"
    "$ECHO" "        -c|--config  Configure Redis post install,"
    "$ECHO" "        -e|--recnfg  Reconfigure Redis as slave,"
    "$ECHO" "        -d|--dump    Dump various Redis related info,"
    "$ECHO" "        -s|--start   Start Redis server,"
    "$ECHO" "        -t|--stop    Stop Redis server,"
    "$ECHO" "        -a|--all     Install+Configure+Start+Dump Redis,"
    "$ECHO" "        -r|--clean   Clean everything Redis,"
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
    elif [ "$SWTCH" = "-c" ] ||  [ "$SWTCH" = "--config" ]
    then
        CNFGR=true
    elif [ "$SWTCH" = "-e" ] ||  [ "$SWTCH" = "--recnfg" ]
    then
        RECNFG=true
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
        "$SRVC" "$IPTBLS" stop
        "$SRVC" "$IPTBLS" status

        "$CHKCNFG" "$IPTBLS" off
        "$CHKCNFG" --list "$IPTBLS"
    fi

}

stopRDR() {

    local stts=$("$STATUS" redis)
    if [ ! -z "$stts" ]
    then
        if "$ECHO" "$stts" 2>&1 | "$GREP" -i 'start/running' > /dev/null 2>&1
        then
            if ! "$STOP" redis
            then
                exitOnErr "$STOP redis failed"
            else
                "$SLEEP" "$SLPSRVR"
            fi 
        fi
    fi

}

startRDR() {

    local stts=$("$STATUS" redis)
    if [ ! -z "$stts" ]
    then
        if "$ECHO" "$stts" 2>&1 | "$GREP" -i 'stop/waiting' > /dev/null 2>&1
        then
            if ! "$START" redis
            then
                exitOnErr "$START redis failed"
            else
                "$SLEEP" "$SLPSRVR"
            fi 
        fi
    fi

}

cleanRedis() {

    "$RM" -rf "$RDSRT"
    "$RM" -rf "$RDSCNFDIR"
    "$RM" -rfv "$RDSLOGDIR"
    "$RM" -rfv "$RDSDTADIR"
    "$RM" -fv "$RDSLGRTTE"
    "$RM" -fv "$UPSTRTDIR/redis.conf"

    for i in $RDSBNRS
    do
        "$RM" -fv "$RDSBINDIR/$i"
    done

    local mkrpm=$("$RPM" -qa 'make*')
    if [ ! -z "$mkrpm" ]
    then
        "$YUM" -y remove 'make.x86_64'
    fi 

    local gccrpm=$("$RPM" -qa 'gcc*')
    if [ ! -z "$gccrpm" ]
    then
        "$YUM" -y remove 'gcc.x86_64'
    fi

}

dwnldExtrctSrc() {

    if [ ! -e "$RDSRT.tar.gz" ]
    then
        if ! "$WGET" "$LNKRDS"
        then
            exitOnErr "$WGET $LNKRDS failed"
        else
            "$SLEEP" "$SLPFLSYS"
        fi
    fi

    if ! "$TAR" zxvf $RDSRT.tar.gz
    then
        exitOnErr "$TAR zxvf $RDSRT.tar.gz failed"
    else
        "$SLEEP" "$SLPFLSYS"
    fi
   
}

instlDeps() {

    local gccrpm=$("$RPM" -qa 'gcc*')
    if [ -z "$gccrpm" ]
    then
        if ! "$YUM" -y install 'gcc.x86_64'
        then
            exitOnErr "$YUM -y install gcc.x86_64 failed"
        fi
    fi

    local mkerpm=$("$RPM" -qa 'make*')
    if [ -z "$mkerpm" ]
    then
        if ! "$YUM" -y install 'make.x86_64'
        then
            exitOnErr "$YUM -y install make.x86_64 failed"
        fi
    fi

}

instlRedis() {

    instlDeps
    dwnldExtrctSrc

    if [ -d "$RDSRT" ]
    then
        pushd "$RDSRT"
        if [ -d 'deps' ]
        then
            # FIXME: This is supposed to be done by redis makefile,
            #        fixed in the later version(s).		
            pushd deps
            if ! make hiredis lua jemalloc linenoise
            then
                popd
                exitOnErr "make hiredis lua jemalloc linenoise failed"
            fi
            # END FIXME

            popd
            if ! make
            then
                popd
                exitOnErr "redis make failed"
            fi

            if ! make install
            then
                popd
                exitOnErr "redis make install failed"
            fi
	    popd
        fi
    else
        exitOnErr "No $RDSRT directory to move"
    fi

}

chkMkDirsCnf() {
    
    if [ ! -d "$RDSCNFDIR" ]
    then
        if ! "$MKDR" -p "$RDSCNFDIR"
        then
            exitOnErr "$MKDR -p $RDSCNFDIR failed"
        else
            "$SLEEP" "$SLPFLSYS"
            if [ ! -f "$RDSRT/$RDSCNF" ]
            then
                exitOnErr "No $RDSRT/$RDSCNF exists"
            else
                if ! /bin/cp "$RDSRT/$RDSCNF" "$RDSCNFDIR"
                then  
                    exitOnErr "cp $RDSRT/$RDSCNF $RDSCNFDIR failed"
                else 
                    "$SLEEP" "$SLPFLSYS"
                fi
            fi 
        fi
    fi

    if ! "$MKDR" -p "$RDSLOGDIR"
    then
        exitOnErr "$MKDR -p $RDSLOGDIR failed"
    else
        "$SLEEP" "$SLPFLSYS"
    fi

    if ! "$MKDR" -p "$RDSDTADIR"
    then
        exitOnErr "$MKDR -p $RDSDTADIR failed"
    else
        "$SLEEP" "$SLPFLSYS"
    fi

}

cnfgrRedis() {

    if [ ! -d "$RDSCNFDIR" ]
    then
        exitOnErr "$RDSCNFDIR does not exist"
    else
        if ! "$SED" -i '/^save/ s/^/#/' "$RDSCNFDIR/$RDSCNF"
        then
            exitOnErr "$RDSCNFDIR/$RDSCNF save entries not got commented" 
        fi

        if ! "$SED" -i "/^port/ s/\([1-9]\{1,\}\)/$RDSPRT/" "$RDSCNFDIR/$RDSCNF"
        then
            exitOnErr "$RDSCNFDIR/$RDSCNF port not changed to $RDSPRT" 
        fi

        if ! "$SED" -i "/^ *logfile/ s|stdout|$RDSLOGDIR/redis.log|" "$RDSCNFDIR/$RDSCNF"
        then
            exitOnErr "$RDSCNFDIR/$RDSCNF logfile not changed to $RDSLOGDIR/redis.log" 
        fi

        if ! "$SED" -i "/^dir/ s|\./|$RDSDTADIR|" "$RDSCNFDIR/$RDSCNF"
        then
            exitOnErr "$RDSCNFDIR/$RDSCNF dir not changed to $RDSDTADIR"
        fi
    fi

    "$SLEEP" "$SLPFLSYS"

}

recnfgrRedis() {

    if [ ! -f "/tmp/$SLAVECNF" ]
    then
        exitOnErr "Required /tmp/$SLAVECNF not found"
    fi

    if [ ! -f "$RDSCNFDIR/$RDSCNF" ]
    then
        exitOnErr "Required $RDSCNFDIR/$RDSCNF not found"
    fi

    local mstrip=$("$SED" -n 's/^ *MASTER *= *//p' "/tmp/$SLAVECNF" | "$SED" 's/ *$//')
    if [ ! -z "$mstrip" ]
    then
        if ! "$SED" -i -e "/^ *# *slaveof/ s/<masterip>/$mstrip/" \
                       -e "/^ *# *slaveof/ s/<masterport>/$RDSPRT/" \
                       -e "/^ *# *slaveof/ s/^ *# *//" "$RDSCNFDIR/$RDSCNF"
        then
            exitOnErr "$RDSCNFDIR/$RDSCNF slaveof not changed to master params and uncommented"
        fi
    fi

    if ! "$SED" -i "/^ *slave-read-only/ s/yes/no/" "$RDSCNFDIR/$RDSCNF"
    then
        exitOnErr "$RDSCNFDIR/$RDSCNF slave-read-only not changed to no" 
    fi
    
    "$SLEEP" "$SLPFLSYS"

}

crteUpstrtCnf() {

    if [ ! -d "$UPSTRTDIR" ]
    then
        exitOnErr "$UPSTRTDIR does not exist"
    else
        if [ ! -e "$UPSTRTDIR/$RDSCNF" ]
        then
            > "$UPSTRTDIR/$RDSCNF"
            "$TEE" "$UPSTRTDIR/$RDSCNF" <<EOF

            start on runlevel [35]
            stop on runlevel [!35]
            respawn
            exec $RDSBINDIR/redis-server $RDSCNFDIR/$RDSCNF

EOF
        fi
    fi

}

setupRdrLgrttn() {

    if [ ! -f "$RDSLGRTTE" ]
    then
        > "$RDSLGRTTE"
        "$TEE" "$RDSLGRTTE" <<EOF
   
        $RDSLOGDIR/redis.log {
        weekly
        rotate 10
        copytruncate
        missingok
        notifempty
        }

EOF
    fi

}

dumpInfo() {

    "$RDSBINDIR/redis-server" -v 
    "$GREP" -E '^ *dir' "$RDSCNFDIR/$RDSCNF"
    "$GREP" -E '^#save' "$RDSCNFDIR/$RDSCNF"
    "$GREP" -E '^ *port' "$RDSCNFDIR/$RDSCNF"
    "$GREP" -E '^ *logfile' "$RDSCNFDIR/$RDSCNF"
    "$GREP" -E '^ *slaveof' "$RDSCNFDIR/$RDSCNF"
    "$GREP" -E '^ *slave-read-only' "$RDSCNFDIR/$RDSCNF"
    
    "$CAT" "$UPSTRTDIR/$RDSCNF"
    "$CAT" "$RDSLGRTTE"
    "$NTST" -nlptu | "$GREP" redis

    "$RDSBINDIR/redis-cli" -p $RDSPRT ping
    "$RDSBINDIR/redis-cli" -p $RDSPRT config get save
    "$RDSBINDIR/redis-cli" -p $RDSPRT config get dir
    "$RDSBINDIR/redis-cli" -p $RDSPRT config get port
    "$RDSBINDIR/redis-cli" -p $RDSPRT config get logfile
    "$RDSBINDIR/redis-cli" -p $RDSPRT config get slaveof
    "$RDSBINDIR/redis-cli" -p $RDSPRT config get slave-read-only

    "$TAIL" -n 15 "$RDSLOGDIR/redis.log"

}

main() {

    preChecks

    if $INSTL
    then
        instlRedis
        dumpInfo
    fi

    if $CNFGR
    then
        chkMkDirsCnf
        cnfgrRedis
        crteUpstrtCnf
        setupRdrLgrttn
        dumpInfo
    fi

    if $RECNFG
    then
        stopRDR
        recnfgrRedis
        startRDR
        dumpInfo
    fi

    if $DUMP
    then
        dumpInfo
    fi

    if $STARTR
    then
        startRDR
        dumpInfo
    fi

    if $STOPR
    then
        stopRDR
        dumpInfo
    fi

    if $ALL
    then
        instlRedis
        chkMkDirsCnf
        cnfgrRedis
        crteUpstrtCnf
        setupRdrLgrttn
        startRDR
        dumpInfo
    fi     

    if $CLEAN
    then
        stopRDR
        cleanRedis
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

