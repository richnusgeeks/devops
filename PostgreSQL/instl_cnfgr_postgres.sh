#! /usr/bin/env bash
############################################################################
# File name : instl_cnfgr_postgres.sh
# Purpose   : Install and configure PostgreSQL on CentOS 6.x (x>=4).
# Usages    : ./instl_cnfgr_postgres.sh <-i|--install|-c|--config|-d|--dump
#                                          |-s|--start|-t|--stop
#                                          |-r|--clean|-a|--all>
#             (make it executable using chmod +x)
# Start date : 11/05/2013
# End date   : 10/0x/2013
# Author : Ankur Kumar <richnusgeeks@gmail.com>
# Download link : www.richnusgeeks.me
# License : RichNusGeeks
# Version : 0.0.1
# Modification history : 
# Notes : TODO: 1. Refactor more to eliminate code duplication,
############################################################################
# <start of include section>

# <end of include section>


# <start of global section>
RM=rm
TR=$(which tr)
SU=$(which su)
SED=$(which sed)
AWK=$(which awk)
TEE=$(which tee)
YUM=$(which yum)
RPM=$(which rpm)
DATE=$(which date)
ECHO=$(which echo)
WGET=$(which wget)
SUDO=$(which sudo)
CHKCNFG=$(which chkconfig)
BSNME=$(which basename)
GREP=$(which grep)
NTST=$(which netstat)
SRVC=$(which service)
CURL=$(which curl)
SLEEP=$(which sleep)
SWTCH="$1"
NUMARG=$#
PRGNME=$("$ECHO" $("$BSNME" "$0") | "$SED" -n 's/\.sh//p')
INSTL=false
CNFGR=false
DUMP=false
STOP=false
START=false
ALL=false
REM=false
RECNFG=false
SLPSRVR=10
SLPFLSYS=5
IPTBLS='iptables'
EPELRPM='http://download.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm'
PSQLSRVR='postgresql-9.2'
PSQLPTH='/var/lib/pgsql/9.2'
PSQLDTA='data'
PSQLBKP='backups'
PSQLLOG='pgstartup.log'
PGSQLUSR='postgres'
PSQLCONF='postgresql.conf'
PSQLTRST='pg_hba.conf'
PSQLURL='http://yum.postgresql.org/9.2/redhat/rhel-6.4-x86_64'
PSQL="postgresql92-9.2.5-1PGDG.rhel6.x86_64.rpm \
      postgresql92-libs-9.2.5-1PGDG.rhel6.x86_64.rpm \
      postgresql92-server-9.2.5-1PGDG.rhel6.x86_64.rpm"
UNINSTL="postgresql92-server-9.2.5-1PGDG.rhel6.x86_64.rpm \
         postgresql92-9.2.5-1PGDG.rhel6.x86_64.rpm \
         postgresql92-libs-9.2.5-1PGDG.rhel6.x86_64.rpm"
FLDS="^max_connections \
      ^shared_buffers \
      ^work_mem \
      ^maintenance_work_mem \
      ^checkpoint_segments \
      ^checkpoint_completion_target \
      ^effective_cache_size \
      trust$"
# <end of global section>

# <start of helper section>
exitOnErr() {

    local date=$($DATE)
    "$ECHO" " Error: <$date> $1, exiting ..."
    exit 1

}

prntUsage() {

    "$ECHO" "Usages: $PRGNME <-i|--install|-c|--config|-d|--dump"
    "$ECHO" "                |-s|--start|-t|--stop|-r|--clean"
    "$ECHO" "                |-e|--recnfg|-a|--all>"
    "$ECHO" "        -i|--install Install Postgres components,"
    "$ECHO" "        -c|--config  Configure Postgres components post install,"
    "$ECHO" "        -d|--dump    Dump various Postgres related info,"
    "$ECHO" "        -r|--clean   Cleanup Postgres components,"
    "$ECHO" "        -a|--all     Install+Configure+Start+Dump Postgres,"
    "$ECHO" "        -s|--start   Start Postgres components,"
    "$ECHO" "        -t|--stop    Stop Postgres components,"
    "$ECHO" "        -e|--recnfg  Re configure Postgres components,"
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
    elif [ "$SWTCH" = "-r" ] || [ "$SWTCH" = "--clean" ]
    then
        REM=true
    elif [ "$SWTCH" = "-s" ] || [ "$SWTCH" = "--start" ]
    then
        START=true
    elif [ "$SWTCH" = "-t" ] || [ "$SWTCH" = "--stop" ]
    then
        STOP=true
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

    "$SRVC" "$IPTBLS" stop
    "$SRVC" "$IPTBLS" status

    "$CHKCNFG" "$IPTBLS" off
    "$CHKCNFG" --list "$IPTBLS"

    if $INSTL || $ALL
    then
        "$YUM" -y update
    fi

}

instlLPG() {

    for psg in $PSQL
    do
        if [ ! -e "$psg" ]
        then
            if ! "$WGET" "$PSQLURL/$psg"
            then
                exitOnErr "$WGET $PSQLURL/$psg failed"
            fi
        fi
    done

    "$SLEEP" "$SLPFLSYS"

    if ! "$RPM" -Uvh $PSQL
    then
        exitOnErr "$RPM -Uvh $PSQL failed"
    fi

}

removeLPG() {

    for psg in $UNINSTL
    do
        local pckg=$($ECHO $psg | $SED 's/\.rpm$//')
        if [ $? -ne 0 ]
        then
            exitOnErr "Package name deduction from $psg failed"
        fi
 
        if [ ! -z "$pckg" ]
        then
            if $RPM -qa '*postg*' | "$GREP" "$pckg" > /dev/null 2>&1
            then

                if ! "$RPM" -e "$pckg"
                then
                    exitOnErr "Package $pckg removal failed"
                fi

            fi
        fi  

    done

    "$RM" -rfv "$PSQLPTH"

}

startLPG() {

    if ! "$SRVC" "$PSQLSRVR" status
    then
        if ! "$SRVC" "$PSQLSRVR" start
        then
            exitOnErr "$SRVC $PSQLSRVR start failed"
        else
            "$SLEEP" "$SLPSRVR"
        fi
    fi

}

stopLPG() {

    if "$SRVC" "$PSQLSRVR" status
    then
        if ! "$SRVC" "$PSQLSRVR" stop
        then
            exitOnErr "$SRVC $PSQLSRVR stop failed" 
        else
            "$SLEEP" "$SLPSRVR"
        fi
    fi

}

cnfgrLPG() {

    # TODO: Refine logic more to chheck on/off state.
    if "$CHKCNFG" --list | "$GREP" -i "$PSQLSRVR" > /dev/null 2>&1
    then
        if ! "$CHKCNFG" "$PSQLSRVR" on
        then
            exitOnErr "$CHKCNFG $PSQLSRVR on failed" 
        fi
    fi 
   
    if ! "$SRVC" "$PSQLSRVR" initdb
    then
        exitOnErr "$SRVC $PSQLSRVR initdb failed"
    fi 

    "$SLEEP" "$SLPSRVR"

    # TODO: Use inplace substitution.
    if [ -f "$PSQLPTH/$PSQLDTA/$PSQLCONF" ]
    then
        if ! "$SED" -i.old -e '/^max_connections *=/d'               \
                           -e '/^shared_buffers *=/d'                \
                           -e '/^#work_mem *=/d'                     \
                           -e '/^#maintenance_work_mem *=/d'         \
                           -e '/^#checkpoint_segments *=/d'          \
                           -e '/^#checkpoint_completion_target *=/d' \
                           -e '/^#effective_cache_size *=/d'         \
                           -e '/^#listen_addresses *=/d'             \
                           "$PSQLPTH/$PSQLDTA/$PSQLCONF"
        then
            exitOnErr "Removal of fields from $PSQLPTH/$PSQLDTA/$PSQLCONF failed"
        else
            # TODO: Move the duplicate code to a subroutine.
            if ! "$GREP" -E '^ *max_connections *= *600' "$PSQLPTH/$PSQLDTA/$PSQLCONF" > /dev/null 2>&1
            then 
                "$ECHO" "max_connections = 600" >> "$PSQLPTH/$PSQLDTA/$PSQLCONF"
            fi

            if ! "$GREP" -E '^ *shared_buffers *= *4096MB' "$PSQLPTH/$PSQLDTA/$PSQLCONF" > /dev/null 2>&1
            then
                "$ECHO" "shared_buffers = 4096MB" >> "$PSQLPTH/$PSQLDTA/$PSQLCONF"
            fi

            if ! "$GREP" -E '^ *work_mem *= *16MB' "$PSQLPTH/$PSQLDTA/$PSQLCONF" > /dev/null 2>&1
            then
                "$ECHO" "work_mem = 16MB" >> "$PSQLPTH/$PSQLDTA/$PSQLCONF"
            fi

            if ! "$GREP" -E '^ *maintenance_work_mem *= *128MB' "$PSQLPTH/$PSQLDTA/$PSQLCONF" > /dev/null 2>&1
            then
                "$ECHO" "maintenance_work_mem = 128MB" >> "$PSQLPTH/$PSQLDTA/$PSQLCONF"
            fi
        
            if ! "$GREP" -E '^ *checkpoint_segments *= *10' "$PSQLPTH/$PSQLDTA/$PSQLCONF" > /dev/null 2>&1
            then
                "$ECHO" "checkpoint_segments = 10" >> "$PSQLPTH/$PSQLDTA/$PSQLCONF"
            fi

            if ! "$GREP" -E '^ *checkpoint_completion_target *= *0.75' "$PSQLPTH/$PSQLDTA/$PSQLCONF" > /dev/null 2>&1
            then
                "$ECHO" "checkpoint_completion_target = 0.75" >> "$PSQLPTH/$PSQLDTA/$PSQLCONF"
            fi

            if ! "$GREP" -E '^ *effective_cache_size *= *8192MB' "$PSQLPTH/$PSQLDTA/$PSQLCONF" > /dev/null 2>&1
            then
                "$ECHO" "effective_cache_size = 8192MB" >> "$PSQLPTH/$PSQLDTA/$PSQLCONF"
            fi

            if ! "$GREP" -E "^ *listen_addresses *= *'*'" "$PSQLPTH/$PSQLDTA/$PSQLCONF" > /dev/null 2>&1
            then
                "$ECHO" "listen_addresses = '*'" >> "$PSQLPTH/$PSQLDTA/$PSQLCONF"
            fi

        fi
    else
        exitOnErr "Required $PSQLPTH/$PSQLDTA/$PSQLCONF not found"
    fi

    if [ -f "$PSQLPTH/$PSQLDTA/$PSQLTRST" ]
    then
        if ! "$SED" -i.old -e '/^host \{1,\}all \{1,\}all \{1,\}127.0.0.1\/32/s/127.0.0.1\/32/0.0.0.0\/0/' \
                           -e '/^host \{1,\}all \{1,\}all \{1,\}0.0.0.0\/0/s/ident/trust/' \
                           "$PSQLPTH/$PSQLDTA/$PSQLTRST"
        then
            exitOnErr "Authentication modifications to trust in $PSQLPTH/$PSQLDTA/$PSQLTRST failed"
        else
            "$SLEEP" "$SLPFLSYS"
        fi
    else
        exitOnErr "Required $PSQLPTH/$PSQLDTA/$PSQLTRST not found"
    fi
 
}

recnfgrLPG() {

    true

}

dumpLPG() {

    "$RPM" -qa '*postgresql*-server*'
  
    for f in $FLDS
    do
         "$GREP" "$f" "$PSQLPTH/$PSQLDTA/$PSQLCONF" $PSQLPTH/$PSQLDTA/$PSQLTRST
    done

    "$CHKCNFG" --list "$PSQLSRVR"
    "$NTST" -nlptu | "$GREP" post

    "$SUDO" "$SU" -c "psql -c '\l+'" - postgres

}

main() {

    preChecks

    if $INSTL
    then
        instlLPG
        dumpLPG
    fi

    if $CNFGR
    then
        cnfgrLPG
        dumpLPG
    fi

    if $DUMP
    then
        dumpLPG
    fi

    if $ALL
    then
        instlLPG
        cnfgrLPG
        startLPG
        dumpLPG
    fi

    if $START
    then
        startLPG
        dumpLPG
    fi

    if $STOP
    then
        stopLPG
        dumpLPG
    fi

    if $REM
    then
        stopLPG
        removeLPG
        dumpLPG
    fi

    if $RECNFG
    then
        stopLPG
        recnfgrLPG
        startLPG
        dumpLPG
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

