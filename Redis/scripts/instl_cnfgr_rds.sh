#! /usr/bin/env bash
############################################################################
# File name : instl_cnfgr_rds.sh
# Purpose   : Install and configure redis on a CentOS 6.x (x>=4) instance.
# Usages    : ./instl_cnfgr_rds.sh <-i|--install|-c|--config|-d|--dump
#                                     |-s|--start|-t|--stop|-a|--all
#                                     |-r|--clean>
#             (make it executable using chmod +x) 
# Start date : 03/04/2013
# End date   : 03/04/2013
# Author : Ankur Kumar <richnusgeeks@gmail.com>
# Download link : http://www.richnusgeeks.me
# License : RichNusGeeks
# Version : 0.0.1
# Modification history : Modified to merge all the redis stuff till now 
#                        Ankur 06/10/2013
# Notes : ToDo - 1. Make script generic with various options,
#                2. refactor to fill init and cleanup sections,
#                3. fill test section with verification routines,
############################################################################
# <start of include section>
# <end of include section>


# <start of global section>
MV=$(which mv)
WC=$(which wc)
RM=$(which rm)
SED=$(which sed)
AWK=$(which awk)
TEE=$(which tee)
YUM=$(which yum)
RPM=$(which rpm)
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
INTCTL=$(which initctl)
SLEEP=$(which sleep)
SORT=$(which sort)
DATE=$(which date)
LGRTTE=$(which logrotate)
CHMOD=$(which chmod)
IPTBLS='iptables'
RDSRT='redis-2.6.10'
RDSCNF='redis.conf'
RDSBINDIR='/usr/local/bin'
RDSCNFDIR='/etc/redis'
UPSTRTDIR='/etc/init'
LGRTEDIR='/etc/logrotate.d'
CRONHRLY='/etc/cron.hourly'
PRTSTRT=6379
PRTEND=6408
BLDESNTLS='Development tools'
LNKRDS='http://redis.googlecode.com/files/redis-2.6.10.tar.gz'
SWTCH="$1"
NUMARG=$#
PRGNME=$("$ECHO" $("$BSNME" "$0") | "$SED" -n 's/\.sh//p')
INSTL=false
CNFGR=false
DUMP=false
START=false
STOP=false
ALL=false
CLEAN=false
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

stpRdsSrvcs() {

    for i in $("$SEQ" "$PRTSTRT" "$PRTEND")
    do
        "$INTCTL" stop "redis$i"
    done

}

cleanRedis() {

    "$RM" -rf 'redis-2.6.10'
    "$RM" -rf "$RDSCNFDIR"
    
    for i in $("$SEQ" "$PRTSTRT" "$PRTEND")
    do
        "$RM" -rf "/redis$i"
        "$RM" -f "$UPSTRTDIR/redis$i.conf"
        "$RM" -f "$RDSCNFDIR/rdslogrtte$i.conf"
    done

    "$RM" -f "$CRONHRLY/rdslogrtte"

    for i in $RDSBNRS
    do
        "$RM" -f "$RDSBINDIR/$i"
    done

}

dwnldExtrctSrc() {

    if ! "$WGET" "$LNKRDS"
    then
        exitOnErr "$WGET $LNKRDS failed"
    fi

    if ! "$TAR" zxvf redis-2.6.10.tar.gz
    then
        exitOnErr "$TAR zxvf redis-2.6.10.tar.gz failed"
    fi
   
}

instlDeps() {

    if [ ! -e "$RDSRT.tar.gz" ]
    then
        if ! "$WGET" "$LNKRDS"
        then
            exitOnErr "$WGET $LNKRDS failed"
        else
            "$SLEEP" 5
        fi
    fi

    if ! "$TAR" zxvf $RDSRT.tar.gz
    then
        exitOnErr "$TAR zxvf $RDSRT.tar.gz failed"
    else
        "$SLEEP" 5
    fi

}

instlRedis() {

    instlDeps
    dwnldExtrctSrc

    if [ -d 'redis-2.6.10' ]
    then
        pushd redis-2.6.10

        if ! make
        then
            exitOnErr "redis make failed"
        fi

        if ! make install
        then
            exitOnErr "redis make install failed"
        fi

        popd

    else
        exitOnErr "No redis-2.6.10 directory to move"
    fi

}

chkMkDirsCnfs() {
    
    if [ ! -d '/etc/redis' ]
    then
        if ! "$MKDR" -p '/etc/redis'
        then
            exitOnErr "$MKDR -p /etc/redis failed"
        else
            if [ ! -f "$RDSRT/$RDSCNF" ]
            then
                exitOnErr "No $RDSRT/$RDSCNF exists"
            else
                if ! /bin/cp "$RDSRT/$RDSCNF" '/etc/redis'
                then  
                    exitOnErr "cp $RDSRT/$RDSCNF /etc/redis failed"
                fi
            fi 
        fi
    fi

}

crteRDSConfs() {

    if [ ! -d "$RDSCNFDIR" ]
    then
        exitOnErr "$RDSCNFDIR does not exist"
    else
        for i in $("$SEQ" "$PRTSTRT" "$PRTEND")
        do
            if ! /bin/cp "$RDSCNFDIR/$RDSCNF" "$RDSCNFDIR/redis$i.conf"
            then
                exitOnErr "$RDSCNFDIR/redis$i.conf creation failed"
            else
                if ! "$SED" -i '/^save/ s/^/#/' "$RDSCNFDIR/redis$i.conf"
                then
                    exitOnErr "$RDSCNFDIR/redis$i.conf save entries not got commented" 
                fi

                if ! "$SED" -i "/^port/ s/\([1-9]\{1,\}\)/$i/" "$RDSCNFDIR/redis$i.conf"
                then
                    exitOnErr "$RDSCNFDIR/redis$i.conf port not changed to $i" 
                fi

                if ! "$SED" -i "/^tcp-keepalive/ s/\([0-9]\{1,\}\)/60/" "$RDSCNFDIR/redis$i.conf"
                then
                    exitOnErr "$RDSCNFDIR/redis$i.conf tcp-keepalive not chnaged to 60" 
                fi

                if ! "$SED" -i "/^ *hash-max-ziplist-entries/ s/\([1-9]\{1,\}\)/200/" "$RDSCNFDIR/redis$i.conf"
                then
                    exitOnErr "$RDSCNFDIR/redis$i.conf hash-max-ziplist-entries not changed to 200" 
                fi
                
                if ! "$SED" -i "/^ *hash-max-ziplist-value/ s/\([1-9]\{1,\}\)/4096/" "$RDSCNFDIR/redis$i.conf"
                then
                    exitOnErr "$RDSCNFDIR/redis$i.conf hash-max-ziplist-value not changed to 4096" 
                fi

                if ! "$SED" -i "/^ *logfile/ s/stdout/\/redis$i\/redis$i.log/" "$RDSCNFDIR/redis$i.conf"
                then
                    exitOnErr "$RDSCNFDIR/redis$i.conf logfile not changed to /redis$i/redis$i.log" 
                fi

                "$SED" -i '/^dir/d' "$RDSCNFDIR/redis$i.conf"
                if ! "$ECHO" "dir /redis$i" >> "$RDSCNFDIR/redis$i.conf"
                then
                    exitOnErr "Working directory update to /redis$i for $RDSCNFDIR/redis$i.conf failed"
                fi

            fi     
        done
    fi

}

crteUpstrtCnfs() {

    if [ ! -d "$UPSTRTDIR" ]
    then
        exitOnErr "$UPSTRTDIR does not exist"
    else
        for i in $("$SEQ" "$PRTSTRT" "$PRTEND")
        do
            if [ ! -e "$UPSTRTDIR/redis$i.conf" ]
            then
                > "$UPSTRTDIR/redis$i.conf"
                "$ECHO" "start on runlevel [35]" >> "$UPSTRTDIR/redis$i.conf"
                "$ECHO" "stop on runlevel [!35]" >> "$UPSTRTDIR/redis$i.conf"
                "$ECHO" "respawn" >> "$UPSTRTDIR/redis$i.conf"
                "$ECHO" "exec $RDSBINDIR/redis-server $RDSCNFDIR/redis$i.conf" >> "$UPSTRTDIR/redis$i.conf"
            fi
        done
    fi

}

lnchRDSInsts() {

    for i in $("$SEQ" "$PRTSTRT" "$PRTEND")
    do
        if ! "$INTCTL" start "redis$i"
        then
            exitOnErr "$INTCTL start redis$i failed"
        fi
    done

    "$SLEEP" 5

    "$NTST" -nlptu | "$GREP" redis | "$SORT"
    "$ECHO" "Info: Total redis instances running => $($NTST -nlptu | $GREP redis | $WC -l)"

}

crteRDSWkgDrs() {

    for i in $("$SEQ" "$PRTSTRT" "$PRTEND")
    do
        if [ ! -d "/redis$i" ]
        then
            if ! "$MKDR" "/redis$i"
            then
                exitOnErr "$MKDR /redis$i failed"
            fi
        fi
    done

}

setupRdsLgrttn() {

    if [ ! -d "$LGRTEDIR" ] -a [ ! -d "$CRONHRLY" ]
    then
        exitOnErr "Required system directories $LGRTEDIR and $CRONHRLY missing"
    fi

    > "$CRONHRLY/rdslogrtte"

    for i in $("$SEQ" "$PRTSTRT" "$PRTEND")
    do

        if [ ! -f "$RDSCNFDIR/rdslogrtte$i.conf" ]
        then
            > "$RDSCNFDIR/rdslogrtte$i.conf"
            "$ECHO" "/redis$i/redis$i.log {" >> "$RDSCNFDIR/rdslogrtte$i.conf"
            "$ECHO" "    rotate 5" >> "$RDSCNFDIR/rdslogrtte$i.conf"
            "$ECHO" "    size 10M" >> "$RDSCNFDIR/rdslogrtte$i.conf"
            "$ECHO" "    copytruncate" >> "$RDSCNFDIR/rdslogrtte$i.conf"
            "$ECHO" "    missingok" >> "$RDSCNFDIR/rdslogrtte$i.conf"
            "$ECHO" "    notifempty" >> "$RDSCNFDIR/rdslogrtte$i.conf"
            "$ECHO" "}" >> "$RDSCNFDIR/rdslogrtte$i.conf"
        fi

        "$ECHO" "$LGRTTE $RDSCNFDIR/rdslogrtte$i.conf" >> "$CRONHRLY/rdslogrtte"

    done

    "$CHMOD" +x "$CRONHRLY/rdslogrtte"

}

dumpInfo() {

    "$RDSBINDIR/redis-server" -v 
    ls -dlhrt /redis[1-9]*
    ls -lhrt $RDSCNFDIR/redis[1-9]*
    ls -lhrt $RDSCNFDIR/rds* | "$SORT"
    ls -lhrt $CRONHRLY/rds*
    "$GREP" -E '^ *dir' $RDSCNFDIR/redis[1-9]* | "$SORT"
    "$GREP" -E '^#save' $RDSCNFDIR/redis[1-9]* | "$SORT"
    "$GREP" -E '^ *port' $RDSCNFDIR/redis[1-9]* | "$SORT"
    "$GREP" -E '^ *tcp-keepalive' $RDSCNFDIR/redis[1-9]* | "$SORT"
    "$GREP" -E '^ *hash-max-ziplist-entries' $RDSCNFDIR/redis[1-9]* | "$SORT"
    "$GREP" -E '^ *hash-max-ziplist-value' $RDSCNFDIR/redis[1-9]* | "$SORT"
    "$GREP" -E '^ *logfile' $RDSCNFDIR/redis[1-9]* | "$SORT"

    for i in $("$SEQ" "$PRTSTRT" "$PRTEND")
    do
        "$ECHO" "Info: The redis instance listening on $i"
        "$RDSBINDIR/redis-cli" -p $i ping
        "$RDSBINDIR/redis-cli" -p $i config get save
        "$RDSBINDIR/redis-cli" -p $i config get dir
        "$RDSBINDIR/redis-cli" -p $i config get port
        "$RDSBINDIR/redis-cli" -p $i config get tcp-keepalive
        "$RDSBINDIR/redis-cli" -p $i config get hash-max-ziplist-entries
        "$RDSBINDIR/redis-cli" -p $i config get hash-max-ziplist-value
        "$RDSBINDIR/redis-cli" -p $i config get logfile
    done

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
        chkMkDirsCnfs
        crteRDSWkgDrs
        crteRDSConfs
        crteUpstrtCnfs
        setupRdsLgrttn
        dumpInfo
    fi

    if $DUMP
    then
        dumpInfo
    fi

    if $START
    then
        lnchRDSInsts
        dumpInfo
    fi

    if $STOP
    then
        stpRdsSrvcs
        dumpInfo
    fi

    if $ALL
    then
        instlRedis
        chkMkDirsCnfs
        crteRDSWkgDrs
        crteRDSConfs
        crteUpstrtCnfs
        setupRdsLgrttn
        lnchRDSInsts
        dumpInfo
    fi     

    if $CLEAN
    then
        stpRdsSrvcs
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
