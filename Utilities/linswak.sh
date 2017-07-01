#! /usr/bin/env bash
############################################################################
# File name : linswak.sh
# Purpose   : RichNusGeeks SWAK for all RHEL 6.x (x>=3) based GNU/Linux roles.
# Usages    : ./linswak.sh [-r|--rds|-c|--mcb|-p|--pgr|-g|--pgp|-r|--msg
#                                |-h|--hap|-t|--trc]
#             (make it executable using chmod +x). 
# Start date : 07/01/2013
# End date   : 07/0x/2013
# Author : Ankur Kumar <richnusgeeks@gmail.com>
# Download link : http://www.richnusgeeks.me
# License : RichNusGeeks
# Version : 0.0.1
# Modification history : 
# Notes : TODO - 1. Eliminate hard coded stuff,
#                2. Break code in more subroutines, 
############################################################################
# <start of global section>
PS=$(which ps)
WC=$(which wc)
DF=$(which df)
SU=$(which su)
AWK=$(which awk)
SED=$(which sed)
TEE=$(which tee)
SEQ=$(which seq)
RPM=$(which rpm)
ECHO=$(which echo)
SRVC=$(which service)
SORT=$(which sort)
MKDR=$(which mkdir)
GREP=$(which grep)
NTST=$(which netstat)
INTCTL=$(which initctl)
BSNME=$(which basename)
CHKCNFG=$(which chkconfig)
SWTCH="$1"
NUMARG=$#
PRGNME=$("$ECHO" $("$BSNME" "$0") | "$SED" -n 's/\.sh//p')
IPTBLS='iptables'
RDSCNF='redis.conf'
RDSBINDIRS='/usr/local/bin'
RDSBINDIRR='/usr/sbin'
RDSCLIDIRR='/usr/bin'
MCBSRVR='couchbase-server'
MCBADMN='Administrator'
MCBPSWRD='d3vu$er'
MCBBINDIR='/opt/couchbase/bin'
MCBBCKTS="bucket1 \
          bucket2 \
          bucket3 \
          bucket4"
MCBPRTS="4369 \
         8091 \
         8092 \
         11209 \
         11210 \
         11211" 
MSGBINDIR='/usr/sbin/'
MSGSRVR='rabbitmq-server'
MSGMGMT='rabbitmq_management'
MSGPRTS="4369 \
         5672 \
         15672 \
         55672"
PGRCNFPTH='/var/lib/pgsql/9.2/data'
PGRCONF='postgresql.conf'
PGRTRST='pg_hba.conf'
PGRUSR='postgres'
PGISDB='postgis_central'
PGISTBLS="spatial_ref_sys \
          shapecatalog"
PGRPRT='5432'
PRTSTRT=6379
PRTEND=6408
NUMRDSINST=30
RDSTKAVAL=60
RDSHMZEVAL=200
RDSHMZVVAL=4096
ROOTUWM=90
RDSVER='2.6.10'
PGRVER='9.2.5'
PGSVER='2.0.3'
PGPVER='3.2.3'
MCBVER='2.1.1'
MSGVER='3.0.2'
HAPVER='1.4.24'
RDSROLER=false
RDSROLES=false
PGRROLE=false
MCBROLE=false
PGPROLE=false
MSGROLE=false
HAPROLE=false
TRACE=false
ANYIPV4='0.0.0.0'
ANYIPV6='::'
# <end of global section>

# <start of helper section>
printMesg() {

    local msg=$1
    local clr=$2

    if [ "$clr" = "red" ]
    then
        "$ECHO" -e "\033[31;40;1m$msg\033[m"
    elif [ "$clr" = "green" ]
    then
        "$ECHO" -e "\033[32;40;1m$msg\033[m"
    elif [ "$clr" = "yellow" ]
    then
        "$ECHO" -e "\033[33;40;1m$msg\033[m"
    elif [ "$clr" = "blue" ]
    then
        "$ECHO" -e "\033[34;40;1m$msg\033[m"
    fi

}

prntHeader() {

    "$ECHO"
    printMesg "############ RichNusGeeks GNU/Linux SWAK Report #############" blue
    printMesg "# Report suggestions/bugs to <richnusgeeks@gmail.com> #" blue
    printMesg "####################################################" blue
    "$ECHO"

}

prntFooter() {

    "$ECHO"
    printMesg "####################################################" blue
    "$ECHO"

}

prntUsage() {

    "$ECHO" "Usages: $PRGNME [-r|--rds|-c|--mcb|-p|--pgr|-g|--pgp|-r|--msg"
    "$ECHO" "                |-h|--hap|-t|--trc]"
    "$ECHO" "        -r|--rds Verify for RDS role,"
    "$ECHO" "        -c|--mcb Verify for MCB role,"
    "$ECHO" "        -p|--pgr Verify for PGR role,"
    "$ECHO" "        -g|--pgp Verify for PGP role,"
    "$ECHO" "        -r|--msg Verify for MSG role,"
    "$ECHO" "        -h|--hap Verify for HAProxy role,"
    "$ECHO" "        -t|--trc Enable tracing for debug,"
    prntFooter
    exit 0

}

parseArgs() {

    if [ $NUMARG -gt 1 ]
    then
        prntUsage
    fi

    if [ $NUMARG -eq 1 ]
    then
    
        if [ "$SWTCH" = "-r" ] || [ "$SWTCH" = "--rds" ]
        then
            RDSROLE=true
        elif [ "$SWTCH" = "-c" ] ||  [ "$SWTCH" = "--mcb" ]
        then
            MCBROLE=true
        elif [ "$SWTCH" = "-p" ] || [ "$SWTCH" = "--pgr" ]
        then
            PGRROLE=true
        elif [ "$SWTCH" = "-g" ] || [ "$SWTCH" = "--pgp" ]
        then
            PGPROLE=true
        elif [ "$SWTCH" = "-r" ] || [ "$SWTCH" = "--msg" ]
        then
            MSGROLE=true
        elif [ "$SWTCH" = "-h" ] || [ "$SWTCH" = "--hap" ]
        then
            HAPROLE=true
        elif [ "$SWTCH" = "-t" ] || [ "$SWTCH" = "--trc" ]
        then
            TRACE=true
        else
            prntUsage
        fi

    fi

}



preChecks() {

    if [ "$EUID" -ne 0 ]
    then
        printMesg "This script needs superuser rights, exiting ..." red
        prntFooter
        exit -1
    fi

    parseArgs
    if $TRACE
    then
        set -x
    fi

    if "$SRVC" "$IPTBLS" status > /dev/null 2>&1
    then
        printMesg "IPTABLES running [ FAIL ]" red
        printMesg "$($SRVC $IPTBLS status)" red
        "$ECHO"
    else
        printMesg "IPTABLES not running [ PASS ]" green
        printMesg "$($SRVC $IPTBLS status)" green
        "$ECHO"
    fi

    if "$CHKCNFG" --list "$IPTBLS" 2>&1 | "$GREP" -E 'on' > /dev/null 2>&1
    then
        printMesg "IPTABLES on for some runlevel(s) [ FAIL ]" red
        printMesg "$($CHKCNFG --list $IPTBLS)" red
        "$ECHO"
    else
        printMesg "IPTABLES off for all runlevel(s) [ PASS ]" green
        printMesg "$($CHKCNFG --list $IPTBLS)" green
        "$ECHO"
    fi

    # TODO: Extend diskusage check to other partitions too.
    local rpu=$("$DF" -kh | "$GREP" -w / | "$AWK" '{print $5}' | "$SED" -n 's/%//p')
    if [[ $rpu -gt $ROOTUWM ]]
    then
        printMesg "DISKUSAGE for root partition exceeding $ROOTUWM% [ WARN ]" yellow
        printMesg "$($DF -kh | $GREP -w /)" yellow
        "$ECHO"
    else
        printMesg "DISKUSAGE for root partition not exceeding $ROOTUWM% [ PASS ]" green
        printMesg "$($DF -kh | $GREP -w /)" green
        "$ECHO"
    fi

}

isrdsRole() {

    if "$RPM" -qa '*redis*' 2>&1 | "$GREP" 'redis' > /dev/null 2>&1
    then
        RDSROLER=true
    fi

    if [ -x "$RDSBINDIRS/redis-server" ]
    then
        RDSROLES=true
    fi

}

ispgrRole() {

    if "$RPM" -qa '*postgresql*-server*' 2>&1 | "$GREP" 'postgresql' > /dev/null 2>&1
    then
        PGRROLE=true
    fi

}

ismcbRole() {

    if "$RPM" -qa '*couchbase-server*' 2>&1 | "$GREP" 'couchbase-server' > /dev/null 2>&1
    then
        MCBROLE=true
    fi

}

ispgpRole() {

    true

}

ismsgRole() {

    if "$RPM" -qa '*rabbitmq-server*' 2>&1 | "$GREP" 'rabbitmq-server' > /dev/null 2>&1
    then
        MSGROLE=true
    fi

}

ishapRole() {

    true

}

whichRoles() {

    isrdsRole
    ispgrRole
    ismcbRole
    ispgpRole
    ismsgRole
    ishapRole

}

vrfyRDSBsc() {

    if $RDSROLES
    then

        if ! "$RDSBINDIRS/redis-server" -v 2>&1 | "$GREP" "$RDSVER" > /dev/null 2>&1
        then
            printMesg "VERSION of redis-server [ FAIL ]" red       
            printMesg "$($RDSBINDIRS/redis-server -v)" red
            "$ECHO"
        else
            printMesg "VERSION of redis-server [ PASS ]" green       
            printMesg "$($RDSBINDIRS/redis-server -v)" green
            "$ECHO"
        fi

    fi

    if $RDSROLER
    then

        if ! "$RDSBINDIRR/redis-server" -v 2>&1 | "$GREP" "$RDSVER" > /dev/null 2>&1
        then
            printMesg "VERSION of redis-server [ FAIL ]" red       
            printMesg "$($RDSBINDIRR/redis-server -v)" red
            "$ECHO"
        else
            printMesg "VERSION of redis-server [ PASS ]" green       
            printMesg "$($RDSBINDIRR/redis-server -v)" green
            "$ECHO"
        fi
    
    fi


}

vrfyRDSRt() {

    local rdsinst=$($NTST -nlptu | $GREP redis)

    for i in $($SEQ $PRTSTRT $PRTEND)
    do
    
        if ! "$ECHO" "$rdsinst" | "$GREP" "0.0.0.0:$i" > /dev/null 2>&1
        then
            printMesg "Redis instance not listening on $i for all interfaces [ FAIL ]" red
        else    
            printMesg "Redis instance listening on $i for all interfaces [ PASS ]" green
        fi

    done

    if ! "$NTST" -nlptu | "$GREP" redis | "$WC" -l | "$GREP" "$NUMRDSINST" > /dev/null 2>&1
    then
        "$ECHO"
        printMesg "Total $($NTST -nlptu | $GREP redis | $WC -l) redis instances are running [ FAIL ]" red
        "$ECHO"
    else
        "$ECHO"
        printMesg "Total $NUMRDSINST redis instances are running [ PASS ]" green
        "$ECHO"
    fi

}

vrfyRDSCnf() {

    for i in $($PS aux | $GREP redis | $GREP -v grep | $AWK '{print $12}')
    do
       
       "$ECHO" "Redis conf settings in $i =>"

       if ! "$GREP" -E '^#save' "$i" > /dev/null 2>&1
       then
           printMesg " Redis conf setting save not commented [ FAIL ]" red
           printMesg "$($GREP -E '^#save' $i)" red
           "$ECHO" 
       else
           printMesg " Redis conf setting save commented [ PASS ]" green
           printMesg "$($GREP -E '^#save' $i)" green
           "$ECHO" 
       fi

       if ! "$GREP" -E '^ *dir' "$i" > /dev/null 2>&1
       then
           printMesg " Redis conf setting dir not there [ FAIL ]" red
           printMesg "$($GREP -E '^ *dir' $i)" red
           "$ECHO" 
       else
           printMesg " Redis conf setting dir is there [ PASS ]" green
           printMesg "$($GREP -E '^ *dir' $i)" green
           "$ECHO" 
       fi
        
       if ! "$GREP" -E '^ *logfile' "$i" > /dev/null 2>&1
       then
           printMesg " Redis conf setting logfile not there [ FAIL ]" red
           printMesg "$($GREP -E '^ *logfile' $i)" red
           "$ECHO" 
       else
           printMesg " Redis conf setting logfile is there [ PASS ]" green
           printMesg "$($GREP -E '^ *logfile' $i)" green
           "$ECHO" 
       fi

       if ! "$GREP" -E '^ *port *6[34][0789][0-9]' "$i" > /dev/null 2>&1
       then
           printMesg " Redis conf setting port not proper [ FAIL ]" red
           printMesg "$($GREP -E '^ *port' $i)" red
           "$ECHO" 
       else
           printMesg " Redis conf setting port is proper [ PASS ]" green
           printMesg "$($GREP -E '^ *port' $i)" green
           "$ECHO" 
       fi

       if ! "$GREP" -E "^ *tcp-keepalive *$RDSTKAVAL" "$i" > /dev/null 2>&1
       then
           printMesg " Redis conf setting tcp-keepalive not proper [ FAIL ]" red
           printMesg "$($GREP -E '^ *tcp-keepalive')" red
           "$ECHO" 
       else
           printMesg " Redis conf setting tcp-keepalive is proper [ PASS ]" green
           printMesg "$($GREP -E '^ *tcp-keepalive' $i)" green
           "$ECHO" 
       fi

       if ! "$GREP" -E "^ *hash-max-ziplist-entries *$RDSHMZEVAL" "$i" > /dev/null 2>&1
       then
           printMesg " Redis conf setting hash-max-ziplist-entries not proper [ FAIL ]" red
           printMesg "$($GREP -E '^ *hash-max-ziplist-entries' $i)" red
           "$ECHO" 
       else
           printMesg " Redis conf setting hash-max-ziplist-entries is proper [ PASS ]" green
           printMesg "$($GREP -E '^ *hash-max-ziplist-entries' $i)" green
           "$ECHO" 
       fi

       if ! "$GREP" -E "^ *hash-max-ziplist-value *$RDSHMZVVAL" "$i" > /dev/null 2>&1
       then
           printMesg " Redis conf setting hash-max-ziplist-value not proper [ FAIL ]" red
           printMesg "$($GREP -E '^ *hash-max-ziplist-value' $i)" red
           "$ECHO" 
       else
           printMesg " Redis conf setting hash-max-ziplist-value is proper [ PASS ]" green
           printMesg "$($GREP -E '^ *hash-max-ziplist-value' $i)" green
           "$ECHO" 
       fi

    done

}

summaryRDS() {

    vrfyRDSBsc
    vrfyRDSRt
    vrfyRDSCnf

}

vrfyMCBBsc() {

    if ! "$RPM" -qa '*couchbase-server*' 2>&1 | "$GREP" "$MCBVER" > /dev/null 2>&1
    then
        printMesg "VERSION of couchbase server [ FAIL ]" red
        printMesg "$($RPM -qa '*couchbase-server*')" red
        "$ECHO"
    else
        printMesg "VERSION of couchbase server [ PASS ]" green
        printMesg "$($RPM -qa '*couchbase-server*')" green
        "$ECHO"
    fi

    if ! "$CHKCNFG" --list 'couchbase-server' 2>&1 | "$GREP" -E '3 *:on' > /dev/null 2>&1
    then
        printMesg "COUCHBASE is off for reboot [ FAIL ]" red
        printMesg "$($CHKCNFG --list couchbase-server)" red
        "$ECHO"
    else
        printMesg "COUCHBASE is on for reboot [ PASS ]" green
        printMesg "$($CHKCNFG --list couchbase-server)" green
        "$ECHO"
    fi

    for i in $MCBPRTS
    do
        if ! "$NTST" -nlptu 2>&1 | "$GREP" tcp 2>&1 | "$GREP" "$ANYIPV4:$i" > /dev/null 2>&1
        then
            printMesg "COUCHBASE is not listening on all interfaces for port $i [ FAIL ]" red
            printMesg "$($NTST -nlptu 2>&1 | $GREP tcp 2>&1 | $GREP $ANYIPV4:$i)" red 
            "$ECHO"
        else
            printMesg "COUCHBASE is listening on all interfaces for port $i [ PASS ]" green
            printMesg "$($NTST -nlptu 2>&1 | $GREP tcp 2>&1 | $GREP $ANYIPV4:$i)" green 
            "$ECHO"
        fi
    done

}

vrfyMCBRt() {

    local admnpswrd=$($MCBBINDIR/erl -noinput -eval 'case file:read_file("/opt/couchbase/var/lib/couchbase/config/config.dat") of {ok, B} -> io:format("~p~n", [binary_to_term(B)]) end.' -run init stop | $GREP cred | $GREP pass)

    local mcbadmn=$($ECHO $admnpswrd | $AWK -F"," '{print $2}' | $SED -n 's/\[{"\(.\{1,\}\)"/\1/p')

    local mcbpswrd=$($ECHO $admnpswrd | "$AWK" -F"," '{print $4}' | "$SED" -n 's/"\(.\{1,\}\)"}]}\]}]}/\1/p')
    
    for i in $MCBBCKTS
    do
        if ! "$MCBBINDIR/couchbase-cli" bucket-list -c localhost -u "$mcbadmn" -p "$mcbpswrd" 2>&1 | "$GREP" "$i" > /dev/null 2>&1
        then
            printMesg "BUCKET $i does not exist [ FAIL ]" red
            "$ECHO"
        else
            printMesg "BUCKET $i exists [ PASS ]" green
            "$ECHO"
        fi   
    done

}

vrfyMCBCnf() {

    if ! "$MCBBINDIR/erl" -noinput -eval 'case file:read_file("/opt/couchbase/var/lib/couchbase/config/config.dat") of {ok, B} -> io:format("~p~n", [binary_to_term(B)]) end.' -run init stop | "$GREP" cred | "$GREP" pass | "$GREP" "$MCBADMN" > /dev/null 2>&1
    then
        printMesg "ADMINUSER is not $MCBADMN for MCB [ FAIL ]" red
        "$ECHO"       
    else
        printMesg "ADMINUSER is $MCBADMN for MCB [ PASS ]" green
        "$ECHO"       
    fi

    if ! "$MCBBINDIR/erl" -noinput -eval 'case file:read_file("/opt/couchbase/var/lib/couchbase/config/config.dat") of {ok, B} -> io:format("~p~n", [binary_to_term(B)]) end.' -run init stop | "$GREP" cred | "$GREP" pass | "$GREP" "$MCBPSWRD" > /dev/null 2>&1
    then
        printMesg "PASSWORD is not $MCBPSWRD for MCB [ FAIL ]" red
        "$ECHO"       
    else
        printMesg "PASSWORD is $MCBPSWRD for MCB [ PASS ]" green
        "$ECHO"       
    fi

}

summaryMCB() {

    vrfyMCBBsc
    vrfyMCBCnf
    vrfyMCBRt

}

vrfyPGRBsc() {

    if ! "$RPM" -qa '*postgresql*-server*' 2>&1 | "$GREP" "$PGRVER" > /dev/null 2>&1
    then
        printMesg "VERSION of postgresql server [ FAIL ]" red
        printMesg "$($RPM -qa '*postgresql*-server*')" red
        "$ECHO"
    else
        printMesg "VERSION of postgresql server [ PASS ]" green
        printMesg "$($RPM -qa '*postgresql*-server*')" green
        "$ECHO"
    fi

    if ! "$RPM" -qa '*postgis*' 2>&1 | "$GREP" "$PGSVER" > /dev/null 2>&1
    then
        printMesg "VERSION of postgis [ FAIL ]" yellow
        printMesg "$($RPM -qa '*postgis*')" yellow
        "$ECHO"
    else
        printMesg "VERSION of postgis [ PASS ]" green
        printMesg "$($RPM -qa '*postgis*')" green
        "$ECHO"
    fi

    if ! "$CHKCNFG" --list 'postgresql-9.2' 2>&1 | "$GREP" -E '3 *:on' > /dev/null 2>&1
    then
        printMesg "POSTGRESQL is off for reboot [ FAIL ]" red
        printMesg "$($CHKCNFG --list postgresql-9.2)" red
        "$ECHO"
    else
        printMesg "POSTGRESQL is on for reboot [ PASS ]" green
        printMesg "$($CHKCNFG --list postgresql-9.2)" green
        "$ECHO"
    fi

    if ! "$NTST" -nlptu 2>&1 | "$GREP" tcp 2>&1 | "$GREP" "$ANYIPV4:$PGRPRT" > /dev/null 2>&1
    then
        printMesg "POSTGRESQL is not listening on all interfaces for port $PGRPRT [ FAIL ]" red
        printMesg "$($NTST -nlptu 2>&1 | $GREP tcp 2>&1 | $GREP $ANYIPV4:$PGRPRT)" red 
        "$ECHO"
    else
        printMesg "POSTGRESQL is listening on all interfaces for port $PGRPRT [ PASS ]" green
        printMesg "$($NTST -nlptu 2>&1 | $GREP tcp 2>&1 | $GREP $ANYIPV4:$PGRPRT)" green 
        "$ECHO"
    fi

}

vrfyPGRRt() {

    if ! eval "$SU" -c "'psql -l'" - "$PGRUSR" 2>&1 | "$GREP" "$PGISDB" > /dev/null 2>&1
    then
        printMesg "POSTGIS database is missing [ FAIL ]" red
        printMesg "$(eval $SU -c \"'psql -l'\" - $PGRUSR 2>&1 | $GREP $PGISDB)" red
        "$ECHO"
    else
        printMesg "POSTGIS database is present [ PASS ]" green
        printMesg "$(eval $SU -c \"'psql -l'\" - $PGRUSR 2>&1 | $GREP $PGISDB)" green
        "$ECHO"
    fi

    if ! eval "$SU" -c "'psql -c \"select postgis_full_version();\" -d $PGISDB'" - "$PGRUSR" 2>&1 | "$GREP" "$PGSVER" > /dev/null 2>&1
    then
        printMesg "POSTGIS is not configured [ FAIL ]" red 
        printMesg "$(eval $SU -c \"'psql -c \"select postgis_full_version();\" -d $PGISDB'\" - $PGRUSR 2>&1 | $GREP $PGSVER)" red
        "$ECHO"
    else
        printMesg "POSTGIS is configured [ PASS ]" green 
        printMesg "$(eval $SU -c \"'psql -c \"select postgis_full_version();\" -d $PGISDB'\" - $PGRUSR 2>&1 | $GREP $PGSVER)" green
        "$ECHO"
    fi

    for i in $PGISTBLS
    do
        if ! eval "$SU" -c "'psql -c \\\\dt -d $PGISDB'" - "$PGRUSR" 2>&1 | "$GREP" "$i" > /dev/null 2>&1
        then
            printMesg "POSTGIS $i table is missing [ FAIL ]" red
            printMesg "$(eval $SU -c \"'psql -c \\\\dt -d $PGISDB'\" - $PGRUSR)" red
            "$ECHO"
        else
            printMesg "POSTGIS $i table is present [ PASS ]" green
            printMesg "$(eval $SU -c \"'psql -c \\\\dt -d $PGISDB'\" - $PGRUSR 2>&1 | $GREP $i)" green
            "$ECHO"
        fi
    done

}

vrfyPGRCnf() {

    # FIXME: Substitute with some loop/hash based logic.
    if ! "$GREP" -E '^ *max_connections *= *200' "$PGRCNFPTH/$PGRCONF" > /dev/null 2>&1
    then
        printMesg "POSTGRESQL setting max_connections is not proper [ FAIL ]" red
        printMesg "$($GREP -E '^ *max_connections' $PGRCNFPTH/$PGRCONF)" red
        "$ECHO" 
    else
        printMesg "POSTGRESQL setting max_connections is proper [ PASS ]" green
        printMesg "$($GREP -E '^ *max_connections' $PGRCNFPTH/$PGRCONF)" green
        "$ECHO" 
    fi

    if ! "$GREP" -E '^ *shared_buffers *= *2048MB' "$PGRCNFPTH/$PGRCONF" > /dev/null 2>&1
    then
        printMesg "POSTGRESQL setting shared_buffers is not proper [ FAIL ]" red
        printMesg "$($GREP -E '^ *shared_buffers' $PGRCNFPTH/$PGRCONF)" red
        "$ECHO" 
    else
        printMesg "POSTGRESQL setting shared_buffers is proper [ PASS ]" green
        printMesg "$($GREP -E '^ *shared_buffers' $PGRCNFPTH/$PGRCONF)" green
        "$ECHO" 
    fi

    if ! "$GREP" -E '^ *work_mem *= *8MB' "$PGRCNFPTH/$PGRCONF" > /dev/null 2>&1
    then
        printMesg "POSTGRESQL setting work_mem is not proper [ FAIL ]" red
        printMesg "$($GREP -E '^ *work_mem' $PGRCNFPTH/$PGRCONF)" red
        "$ECHO" 
    else
        printMesg "POSTGRESQL setting work_mem is proper [ PASS ]" green
        printMesg "$($GREP -E '^ *work_mem' $PGRCNFPTH/$PGRCONF)" green
        "$ECHO" 
    fi

    if ! "$GREP" -E '^ *maintenance_work_mem *= *64MB' "$PGRCNFPTH/$PGRCONF" > /dev/null 2>&1
    then
        printMesg "POSTGRESQL setting maintenance_work_mem is not proper [ FAIL ]" red
        printMesg "$($GREP -E '^ *maintenance_work_mem' $PGRCNFPTH/$PGRCONF)" red
        "$ECHO" 
    else
        printMesg "POSTGRESQL setting maintenance_work_mem is proper [ PASS ]" green
        printMesg "$($GREP -E '^ *maintenance_work_mem' $PGRCNFPTH/$PGRCONF)" green
        "$ECHO" 
    fi

    if ! "$GREP" -E '^ *checkpoint_segments *= *10' "$PGRCNFPTH/$PGRCONF" > /dev/null 2>&1
    then
        printMesg "POSTGRESQL setting checkpoint_segments is not proper [ FAIL ]" red
        printMesg "$($GREP -E '^ *checkpoint_segments' $PGRCNFPTH/$PGRCONF)" red
        "$ECHO" 
    else
        printMesg "POSTGRESQL setting checkpoint_segments is proper [ PASS ]" green
        printMesg "$($GREP -E '^ *checkpoint_segments' $PGRCNFPTH/$PGRCONF)" green
        "$ECHO" 
    fi

    if ! "$GREP" -E '^ *checkpoint_completion_target *= *0.75' "$PGRCNFPTH/$PGRCONF" > /dev/null 2>&1
    then
        printMesg "POSTGRESQL setting checkpoint_completion_target is not proper [ FAIL ]" red
        printMesg "$($GREP -E '^ *checkpoint_completion_target' $PGRCNFPTH/$PGRCONF)" red
        "$ECHO" 
    else
        printMesg "POSTGRESQL setting checkpoint_completion_target is proper [ PASS ]" green
        printMesg "$($GREP -E '^ *checkpoint_completion_target' $PGRCNFPTH/$PGRCONF)" green
        "$ECHO" 
    fi

    if ! "$GREP" -E '^ *effective_cache_size *= *4096MB' "$PGRCNFPTH/$PGRCONF" > /dev/null 2>&1
    then
        printMesg "POSTGRESQL setting effective_cache_size is not proper [ FAIL ]" red
        printMesg "$($GREP -E '^ *effective_cache_size' $PGRCNFPTH/$PGRCONF)" red
        "$ECHO" 
    else
        printMesg "POSTGRESQL setting effective_cache_size is proper [ PASS ]" green
        printMesg "$($GREP -E '^ *effective_cache_size' $PGRCNFPTH/$PGRCONF)" green
        "$ECHO" 
    fi

    if ! "$GREP" -E "^ *listen_addresses *= '*'" "$PGRCNFPTH/$PGRCONF" > /dev/null 2>&1
    then
        printMesg "POSTGRESQL setting listen_addresses is not proper [ FAIL ]" red
        printMesg "$($GREP -E '^ *listen_addresses' $PGRCNFPTH/$PGRCONF)" red
        "$ECHO" 
    else
        printMesg "POSTGRESQL setting listen_addresses is proper [ PASS ]" green
        printMesg "$($GREP -E '^ *listen_addresses' $PGRCNFPTH/$PGRCONF)" green
        "$ECHO" 
    fi

    if ! "$GREP" -E "^ *host *all *all *0.0.0.0/0 *trust" "$PGRCNFPTH/$PGRTRST" > /dev/null 2>&1
    then
        printMesg "POSTGRESQL setting host all all 0.0.0.0/0 trust is not proper [ FAIL ]" red
        printMesg "$($GREP -E '^ *host *all *all *0.0.0.0/0 *trust' $PGRCNFPTH/$PGRTRST)" red
        "$ECHO" 
    else
        printMesg "POSTGRESQL setting host all all 0.0.0.0/0 trust is proper [ PASS ]" green
        printMesg "$($GREP -E '^ *host *all *all *0.0.0.0/0 *trust' $PGRCNFPTH/$PGRTRST)" green
        "$ECHO" 
    fi

}

summaryPGR() {

    vrfyPGRBsc
    vrfyPGRCnf
    vrfyPGRRt

}

vrfyPGPBsc() {

    true

}   

vrfyPGPCnf() {

    true

}
   
vrfyPGPRt() {

    true

}

summaryPGP() {

    vrfyPGPBsc
    vrfyPGPCnf
    vrfyPGPRt

}

vrfyMSGBsc() {

    if ! "$RPM" -qa '*rabbitmq-server*' 2>&1 | "$GREP" "$MSGVER" > /dev/null 2>&1
    then
        printMesg "VERSION of rabbitmq server [ FAIL ]" red
        printMesg "$($RPM -qa '*rabbitmq-server*')" red
        "$ECHO"
    else
        printMesg "VERSION of rabbitmq server [ PASS ]" green
        printMesg "$($RPM -qa '*rabbitmq-server*')" green
        "$ECHO"
    fi

    if ! "$CHKCNFG" --list 'rabbitmq-server' 2>&1 | "$GREP" -E '3 *:on' > /dev/null 2>&1
    then
        printMesg "RABBITMQ is off for reboot [ FAIL ]" red
        printMesg "$($CHKCNFG --list rabbitmq-server)" red
        "$ECHO"
    else
        printMesg "RABBITMQ is on for reboot [ PASS ]" green
        printMesg "$($CHKCNFG --list rabbitmq-server)" green
        "$ECHO"
    fi

    local bndadr=$ANYIPV4    

    for i in $MSGPRTS
    do
        if [ "$i" = "5672" ]
        then
            bndadr=$ANYIPV6
        else
            bndadr=$ANYIPV4
        fi 

        if ! "$NTST" -nlptu 2>&1 | "$GREP" tcp 2>&1 | "$GREP" "$bndadr:$i" > /dev/null 2>&1
        then
            printMesg "RABBITMQ is not listening on all interfaces for port $i [ FAIL ]" red
            printMesg "$($NTST -nlptu 2>&1 | $GREP tcp 2>&1 | $GREP $bndadr:$i)" red 
            "$ECHO"
        else
            printMesg "RABBITMQ is listening on all interfaces for port $i [ PASS ]" green
            printMesg "$($NTST -nlptu 2>&1 | $GREP tcp 2>&1 | $GREP $bndadr:$i)" green 
            "$ECHO"
        fi
    done

}

vrfyMSGCnf() {

    true

}

vrfyMSGRt() {

    if ! "$SRVC" rabbitmq-server status 2>&1 | "$GREP" "$MSGMGMT" > /dev/null 2>&1
    then
        printMesg "RABBITMQ management plugin not configured [ FAIL ]" red
        "$ECHO"
    else
        printMesg "RABBITMQ management plugin configured [ PASS ]" green
        printMesg "$($SRVC rabbitmq-server status 2>&1 | $GREP $MSGMGMT)" green
        "$ECHO"
    fi

}

summaryMSG() {

    vrfyMSGBsc
    vrfyMSGCnf
    vrfyMSGRt

}

summaryHAP() {

    true

}

main() {
   
    prntHeader    
 
    preChecks

    whichRoles

    if $RDSROLER || $RDSROLES
    then
        summaryRDS
    fi

    if $MCBROLE
    then
        summaryMCB
    fi
    
    if $PGRROLE
    then
        summaryPGR
    fi
    if $PGPROLE
    then
        summaryPGP
    fi
    if $MSGROLE
    then
        summaryMSG
    fi
    if $HAPROLE
    then
        summaryHAP
    fi

    prntFooter
    
}
# <end of helper section>


# <start of test section>

# <end of test section>


# <start of init section>

# <end of init section>


# <start of cleanup section>

# <end of cleanup section>


# <start of main section>
set -u
main 2>&1 | "$TEE" "${PRGNME}.log"
# <end of main section>

