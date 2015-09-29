#! /usr/bin/env bash
############################################################################
# File name : instl-cnfgr-pgpool.sh
# Purpose   : Install and configure PGPool II on CentOS 6.x (x>=4).
# Usages    : ./instl-cnfgr-pgpool.sh <-i|--install|-c|--config|-d|--dump
#                                        |-s|--start|-t|--stop|-a|--all
#                                        |-e|--recnfg|-r|--clean>
#             (make it executable using chmod +x).
# Start date : 05/17/2013
# End date   : 05/dd/2013
# Author : Ankur Kumar <richnusgeeks@gmail.com>
# Download link : www.richnusgeeks.me
# License : RichNusGeeks
# Version : 0.0.1
# Modification history : 1. Porting to CentOS 6.x (x>=4), Ankur 11/19/2013,
# Notes : ToDo - 1. Implement PgPool Admin Tool switch, 
############################################################################
# <start of include section>

# <end of include section>


# <start of global section>
RM='rm'
WC=$(which wc)
MV='mv'
CP='cp'
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
MKDIR=$(which mkdir)
STOP=$(which stop)
START=$(which start)
STATUS=$(which status)
SWTCH="$1"
NUMARG=$#
PRGNME=$("$ECHO" $("$BSNME" "$0") | "$SED" -n 's/\.sh//p')
INSTL=false
CNFGR=false
DUMP=false
STARTP=false
STOPP=false
ALL=false
CLEAN=false
RECNFG=false
SLPFLSYS=5
SLPSRVR=10
PGSQL='postgresql-9.2.5'
PGSQLLNK='http://ftp.postgresql.org/pub/source/v9.2.5'
PGPOOL='pgpool-II-3.2.3'
PGPLBINPTH='/usr/local/bin'
PGPLCNFPTH='/usr/local/etc'
PGPLLNK='http://www.pgpool.net/download.php?f='
PGPLPCP='pcp.conf'
PGPLCNFG='pgpool.conf'
PGPADMN=''
PGPALNK=''
UPSTRTPTH='/etc/init'
DEVTOOLS='Development tools'
DEVLIBS='Development libraries'
ZLIB='zlib'
READLN='readline'
IPTBLS='iptables'
PGSQLNDS='pgpool.nodes'
PGSQLROOT='/usr/local/pgsql'
PGPLLOGPTH='/var/log'
PGPLDATAPTH='/var/lib/pgpool'
PGPLPIDPTH='/var/run/pgpool'
PGRDATAPTH='/var/lib/pgsql/9.2/data'
PGPLPRT=5432
PCPUSRID='Administrator'
PCPPSWRD='d3vu$er'
PCPPORT='9898'
PCPTMOUT=10
FLDS="^listen_address \
      ^port \
      ^replication_mode \
      ^logdir \
      ^backend_hostname \
      ^backend_port \
      ^backend_weight \
      ^backend_data_directory \
      ^backend_flag \
      ^black_function_list \
      ^fail_over_on_backend_error \
      ^load_balance_mode \
      ^num_init_children \
      ^client_idle_limit \
      ^[^#]+:"
# <end of global section>


# <start of helper section>
exitOnErr() {

    local date=$($DATE)
    "$ECHO" " Error: <$date> $1, exiting ..."
    exit 1

}

prntUsage() {

    "$ECHO" "Usages: $PRGNME <-i|--install|-c|--config|-d|--dump"
    "$ECHO" "                   |-s|--start|-t|--stop|-a|--all"
    "$ECHO" "                   |-e|--recnfg|-r|--clean>"
    "$ECHO" "        -i|--install Install PgPool-II,"
    "$ECHO" "        -c|--config  Configure PgPool-II post install,"
    "$ECHO" "        -d|--dump    Dump various PgPool-II related info,"
    "$ECHO" "        -r|--start   Start PgPool-II service,"
    "$ECHO" "        -t|--stop    Stop PgPool-II service,"
    "$ECHO" "        -a|--all     Install+Configure+Start+Dump PgPool-II,"
    "$ECHO" "        -r|--clean   Clean PgPool-II from the system,"
    "$ECHO" "        -e|--recnfg  Reconfigure PgPool-II for backends,"
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
    elif [ "$SWTCH" = "-s" ] || [ "$SWTCH" = "--start" ]
    then
        STARTP=true
    elif [ "$SWTCH" = "-t" ] || [ "$SWTCH" = "--stop" ]
    then
        STOPP=true
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

    if ! "$YUM" -y install "$ZLIB" "${ZLIB}-devel" "$READLN" "${READLN}-devel"
    then
        exitOnErr "$YUM install $ZLIB ${ZLIB}-devel $READLN ${READLN}-devel failed"
    fi


}

instlPgsql() {

    if ! "$WGET" -nc "$PGSQLLNK/${PGSQL}.tar.gz"    
    then
        exitOnErr "$WGET $PGSQLLNK/${PGSQL}.tar.gz failed"
    fi

    "$SLEEP" "$SLPFLSYS"

    if ! "$TAR" zxvf "${PGSQL}.tar.gz"
    then
        exitOnErr "$TAR" zxvf "${PGSQL}.tar.gz failed"
    fi

    if [ -d "$PGSQL" ]
    then
        
        cd "$PGSQL"
        if [ $? -eq 0 ]
        then
            if ! ./configure
            then
                exitOnErr "Configuration of PGSQL source failed"
            else
                "$SLEEP" "$SLPFLSYS"
                if ! make -j$($CAT /proc/cpuinfo | "$WC" -l)
                then
                    exitOnErr "Compilation of PGSQL source failed"
                else
                    "$SLEEP" "$SLPFLSYS"
                    if ! make install
                    then
                        exitOnErr "Installation of PGSQL binaries failed"
                    fi 

                fi

            fi   

        fi

    fi

    cd ..

}

instlPgpool() {

    if [ ! -e "${PGPOOL}.tar.gz" ]
    then
        if ! "$WGET" "${PGPLLNK}${PGPOOL}.tar.gz" -O "${PGPOOL}.tar.gz"   
        then
            exitOnErr "$WGET ${PGPLLNK}${PGPOOL}.tar.gz failed"
        fi
    fi

    "$SLEEP" "$SLPFLSYS"

    if ! "$TAR" zxvf "${PGPOOL}.tar.gz"
    then
        exitOnErr "$TAR" zxvf "${PGPOOL}.tar.gz failed"
    fi

    if [ -d "$PGPOOL" ]
    then
        
        cd "$PGPOOL"
        if [ $? -eq 0 ]
        then
            if ! ./configure
            then
                exitOnErr "Configuration of PGPOOL source failed"
            else
                "$SLEEP" "$SLPFLSYS"
                if ! make -j$($CAT /proc/cpuinfo | "$WC" -l)
                then
                    exitOnErr "Compilation of PGPOOL source failed"
                else
                    "$SLEEP" "$SLPFLSYS"
                    if ! make install
                    then
                        exitOnErr "Installation of PGPOOL binaries failed"
                    fi 

                fi

            fi   

        fi

    fi

    cd ..

}

crteUpstrtCnf() {

    if [ ! -f "$UPSTRTPTH/pgpool.conf" ]
    then
        > "$UPSTRTPTH/pgpool.conf"
        "$ECHO" "start on runlevel [35]" >> "$UPSTRTPTH/pgpool.conf"
        "$ECHO" "stop on runlevel [!35]" >> "$UPSTRTPTH/pgpool.conf"
        "$ECHO" "respawn" >> "$UPSTRTPTH/pgpool.conf"
        "$ECHO" "exec $PGPLBINPTH/pgpool -d -n > $PGPLLOGPTH/pgpool.log 2>&1" >> "$UPSTRTPTH/pgpool.conf"

    fi

}

startPgpl() {

    local stts=$("$STATUS" pgpool)
    if [ ! -z "$stts" ]
    then
        if "$ECHO" "$stts" 2>&1 | "$GREP" -i 'stop/waiting' > /dev/null 2>&1
        then
            if ! "$START" pgpool
            then
                exitOnErr "$START pgpool failed"
            else
                "$SLEEP" "$SLPSRVR"
            fi
        fi
    fi


}

stopPgpl() {

    local stts=$("$STATUS" pgpool)
    if [ ! -z "$stts" ]
    then
        if "$ECHO" "$stts" 2>&1 | "$GREP" -i 'start/running' > /dev/null 2>&1
        then
            if ! "$STOP" pgpool
            then
                exitOnErr "$STOP pgpool failed"
            else
                "$SLEEP" "$SLPSRVR"
            fi
        fi
    fi

}

mdfyPcpConf() {

    local pcpmd5=$("$PGPLBINPTH/pg_md5" "$PCPPSWRD")
    if ! "$GREP" -E "^ *$PCPUSRID *: *$pcpmd5"  "$PGPLCNFPTH/$PGPLPCP" > /dev/null 2>&1
    then
        "$ECHO" "$PCPUSRID:$pcpmd5" >> "$PGPLCNFPTH/$PGPLPCP"
    fi   

}

mdfyPgplConf() {

    if ! "$SED" -i '/^ *listen_addresses *= */ s/localhost/*/' "$PGPLCNFPTH/$PGPLCNFG"
    then
        exitOnErr "$SED -i '/^ *listen_addresses *= */ s/localhost/*/' $PGPLCNFPTH/$PGPLCNFG failed"
    fi   

    if ! "$NTST" -nlptu | "$GREP" "0.0.0.0:$PGPLPRT" > /dev/null 2>&1
    then
        "$SED" -i "/^ *port *= */ s/\([0-9]\{1,\}\)/$PGPLPRT/" "$PGPLCNFPTH/$PGPLCNFG" 
    fi

    if ! "$SED" -i '/^ *replication_mode *= */ s/off/on/' "$PGPLCNFPTH/$PGPLCNFG"
    then
        exitOnErr "$SED -i '/^ *replication_mode *= */ s/off/on/' $PGPLCNFPTH/$PGPLCNFG failed"
    fi

    if ! "$SED" -i '/^ *load_balance_mode *= */ s/off/on/' "$PGPLCNFPTH/$PGPLCNFG"
    then
        exitOnErr "$SED -i '/^ *load_balance_mode *= */ s/off/on/' $PGPLCNFPTH/$PGPLCNFG failed"
    fi

    if ! "$SED" -i '/^ *num_init_children *= */ s/\([0-9]\{1,\}\)/200/' "$PGPLCNFPTH/$PGPLCNFG"
    then
        exitOnErr "$SED -i '/^ *num_init_children *= */ s/\([0-9]\{1,\}\)/200/' $PGPLCNFPTH/$PGPLCNFG failed"
    fi

    if ! "$SED" -i '/^ *client_idle_limit *= */ s/\([0-9]\{1,\}\)/60/' "$PGPLCNFPTH/$PGPLCNFG"
    then
        exitOnErr "$SED -i '/^ *client_idle_limit *= */ s/\([0-9]\{1,\}\)/60/' $PGPLCNFPTH/$PGPLCNFG failed"
    fi

    if ! "$SED" -i '/^ *logdir *=/d' "$PGPLCNFPTH/$PGPLCNFG"
    then
        exitOnErr "$SED -i '/^ *logdir *=/d' $PGPLCNFPTH/$PGPLCNFG failed"
    else
        "$ECHO" "logdir = '$PGPLLOGPTH'" >> "$PGPLCNFPTH/$PGPLCNFG"
    fi

    if ! "$SED" -i '/^ *black_function_list *=/d' "$PGPLCNFPTH/$PGPLCNFG"
    then
        exitOnErr "$SED -i '/^ *black_function_list *=/d' $PGPLCNFPTH/$PGPLCNFG failed"
    else
        "$ECHO" "black_function_list = 'nextval,setval,AddGeometryColumn'" >> "$PGPLCNFPTH/$PGPLCNFG"
    fi

    if ! "$SED" -i '/^ *fail_over_on_backend_error *=/d' "$PGPLCNFPTH/$PGPLCNFG"
    then
        exitOnErr "$SED -i '/^ *fail_over_on_backend_error *=/d' $PGPLCNFPTH/$PGPLCNFG failed"
    else
        "$ECHO" 'fail_over_on_backend_error = off'  >> "$PGPLCNFPTH/$PGPLCNFG"
    fi

    "$SLEEP" "$SLPFLSYS"

}

recnfgPgplNds() {

    if [ ! -f "/tmp/$PGSQLNDS" ]
    then
        exitOnErr "The /tmp/$PGSQLNDS not found for backend node(s) info"
    fi

    local index=0
    while read tag host port weight datadir
    do
        if "$ECHO" "$tag" | "$GREP" -E '^ *#' > /dev/null 2>&1
        then
            continue
        fi
        
        # TODO: Make it more intelligent.
        if ! "$GREP" -E "^ *backend_hostname$index *= *'$host'" "$PGPLCNFPTH/$PGPLCNFG" > /dev/null 2>&1
        then
            "$SED" -i "/^ *backend_hostname$index/d" "$PGPLCNFPTH/$PGPLCNFG"
            "$ECHO" "backend_hostname$index = '$host'" >> "$PGPLCNFPTH/$PGPLCNFG"
        fi

        if ! "$GREP" -E "^ *backend_port$index *= *[0-9]+" "$PGPLCNFPTH/$PGPLCNFG" > /dev/null 2>&1
        then
            "$SED" -i "/^ *backend_port$index/d" "$PGPLCNFPTH/$PGPLCNFG"
            "$ECHO" "backend_port$index = $port" >> "$PGPLCNFPTH/$PGPLCNFG"
        fi

        if ! "$GREP" -E "^ *backend_weight$index *= *[0-9]+" "$PGPLCNFPTH/$PGPLCNFG" > /dev/null 2>&1
        then
            "$SED" -i "/^ *backend_weight$index/d" "$PGPLCNFPTH/$PGPLCNFG"
            "$ECHO" "backend_weight$index = $weight" >> "$PGPLCNFPTH/$PGPLCNFG"
        fi

        if ! "$GREP" -E "^ *backend_data_directory$index *= *'$PGRDATAPTH'" "$PGPLCNFPTH/$PGPLCNFG" > /dev/null 2>&1
        then
            "$SED" -i "/^ *backend_data_directory$index/d" "$PGPLCNFPTH/$PGPLCNFG"
            "$ECHO" "backend_data_directory$index = '$PGRDATAPTH'" >> "$PGPLCNFPTH/$PGPLCNFG"
        fi

        if ! "$GREP" -E "^ *backend_flag$index *= *'ALLOW_TO_FAILOVER'" "$PGPLCNFPTH/$PGPLCNFG" > /dev/null 2>&1
        then
            "$SED" -i "/^ *backend_flag$index/d" "$PGPLCNFPTH/$PGPLCNFG"
            "$ECHO" "backend_flag$index = 'ALLOW_TO_FAILOVER'" >> "$PGPLCNFPTH/$PGPLCNFG"
        fi

        index=$((index+=1))

    done < "/tmp/$PGSQLNDS"

    "$SLEEP" "$SLPFLSYS"

}

cnfgrPgpool() {

    if ! "$MKDIR" -p "$PGPLPIDPTH"
    then
        exitOnErr "$MKDIR -p $PGPLPIDPTH failed"
    fi

    if [ -d "$PGPLCNFPTH" ]
    then
        cd "$PGPLCNFPTH"
        if [ ! -f "${PGPLCNFG}.sample" ] && [ !-f "${PGPLPCP}.sample" ]
        then
            exitOnErr "Required $PGPLCNFG and $PGPLPCP not available"
        else
            if [ ! -f "$PGPLCNFG" ]
            then 
                if ! "$CP" "${PGPLCNFG}.sample" "${PGPLCNFG}"
                then
                    exitOnErr "$CP ${PGPLCNFG}.sample ${PGPLCNFG} failed" 
                fi
            fi  
            
            if [ ! -f "$PGPLPCP" ]
            then  
                if ! "$CP" "${PGPLPCP}.sample" "${PGPLPCP}"
                then
                    exitOnErr "${PGPLPCP}.sample ${PGPLPCP}"
                fi
            fi

            mdfyPgplConf
            mdfyPcpConf

        fi 
    fi

    "$SLEEP" "$SLPFLSYS"

}

instlPgplAdmn() {

    true

}

cnfgrPgplAdmn() {

    true

}

cleanPgpl() {

    stopPgpl
    "$RM" -rfv "$PGPLPIDPTH"
    "$RM" -rfv "$PGSQLROOT"
    "$RM" -fv "$PGPLBINPTH"/{pcp*,pg*,hba*}
    "$RM" -fv "$PGPLCNFPTH"/{pcp*,pg*,hba*}
    "$RM" -fv "$UPSTRTPTH/pgpool.conf"

}

dumpPgpl() {

    ls -lhrt "$PGPLBINPTH" | "$GREP" -E '(pcp|pg)'
    ls -lhrt "$PGPLCNFPTH" | "$GREP" -E '(pcp|pg|hba)'

    for f in $FLDS
    do
        "$GREP" "$f" "$PGPLCNFPTH/$PGPLCNFG"
    done

    "$NTST" -nlptu | "$GREP" pgpool
    "$PGPLBINPTH"/pgpool -v
    "$PGPLBINPTH/pcp_node_count" "$PCPTMOUT" localhost "$PCPPORT" "$PCPUSRID" "$PCPPSWRD"
    "$PGPLBINPTH/pcp_pool_status" "$PCPTMOUT" localhost "$PCPPORT" "$PCPUSRID" "$PCPPSWRD"

}

main() {

    preChecks

    if $INSTL
    then
        instlDeps
        instlPgsql
        instlPgpool
        dumpPgpl    
    fi
    
    if $CNFGR
    then
        cnfgrPgpool
        crteUpstrtCnf
        dumpPgpl    
    fi

    if $STARTP
    then
        startPgpl
        dumpPgpl    
    fi

    if $STOPP
    then
        stopPgpl
        dumpPgpl    
    fi

    if $DUMP
    then
        dumpPgpl    
    fi
 
    if $ALL
    then
        instlDeps
        instlPgsql
        instlPgpool
        cnfgrPgpool
        crteUpstrtCnf
        startPgpl
        dumpPgpl    
    fi

    if $RECNFG
    then
        stopPgpl
        recnfgPgplNds
        startPgpl
        dumpPgpl    
    fi

    if $CLEAN
    then
        cleanPgpl
        dumpPgpl    
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
main 2>&1 | "$TEE" "${PRGNME}.log"
# <end of main section>

