#! /usr/bin/env bash
############################################################################
# File name : instl_cnfgr_haproxy.sh
# Purpose   : Install and configure HAProxy for web services HA and load
#             balancing on CentOS/RHEL 6.x (x>=4).
# Usages    : ./instl-cnfgr-haproxy.sh <-i|--install|-c|--config|-s|--start|
#                                       -d|--dump|-a|--all|-t|--stop|
#                                       -r|--clean|-e|--role>
#             (make it executable using chmod +x instl-cnfgr-haproxy.sh)
# Start date : 05/14/2013
# End date   : 05/dd/2013
# Author : Ankur Kumar <richnusgeeks@gmail.com>
# Download link : www.richnusgeeks.me
# License : RichNusGeeks
# Version : 0.0.1
# Modification history : 
# Notes : TODO 1. Refactor for duplicate portions, 
############################################################################
# <start of include section>

# <end of include section>


# <start of global section>
RM=$(which rm)
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
INTCTL=$(which initctl)
INSTALL=$(which install)
GZIP=$(which gzip)
SSTRT=$(which start)
SSTOP=$(which stop)
SSTTS=$(which status)
SWTCH="$1"
NUMARG=$#
PRGNME=$("$ECHO" $("$BSNME" "$0") | "$SED" -n 's/\.sh//p')
SLPPRD=5
HAPRT='haproxy-1.4.24'
HAPCNF='haproxy.cfg'
HAPCNFDIR='/etc/haproxy'
HAPBINDIR='/usr/local/sbin'
HAPTBLNK='http://haproxy.1wt.eu/download/1.4/src'
UPSTRTDIR='/etc/init'
BLDESNTLS='Development tools'
PCREDEVEL='pcre-devel.x86_64'
IPTBLS='iptables'
HATOPLNK='http://hatop.googlecode.com/files'
HATOP='hatop-0.7.7'
RSLDDIR='/etc/rsyslog.d'
LGRTDIR='/etc/logrotate.d'
LGCNFGFL='49-haproxy.conf'
HAPRLSFL='haproxy.roles'
HATBINDIR='/usr/local/bin'
INSTL=false
CNFGR=false
DUMP=false
START=false
STOP=false
ALL=false
ROLE=false
CLEAN=false
HAT=false
# <end of global section>


# <start of helper section>
exitOnErr() {

    local date=$($DATE)
    "$ECHO" " Error: <$date> $1, exiting ..."
    exit 1

}

prntUsage() {

    "$ECHO" "Usages: $PRGNME <-i|--install|-c|--config|-s|--start"
    "$ECHO" "                 |-d|--dump|-a|--all|-t|--stop"
    "$ECHO" "                 |-r|--clean|-e|--role|-h|--hatop>"
    "$ECHO" "        -i|--install Install HAProxy,"
    "$ECHO" "        -c|--config  Configure HAProxy post install,"
    "$ECHO" "        -d|--dump    Dump various HAProxy related info,"
    "$ECHO" "        -s|--start   Start HAProxy server,"
    "$ECHO" "        -t|--stop    Stop HAProxy server,"
    "$ECHO" "        -r|--delete  Remove HAProxy,"
    "$ECHO" "        -a|--all     Install+Configure+Start+Dump HAProxy,"
    "$ECHO" "        -e|--role    Role specific HAProxy config,"
    "$ECHO" "        -h|--hatop   Invoke HATop for HAProxy service,"
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
    elif [ "$SWTCH" = "-r" ] || [ "$SWTCH" = "--delete" ]
    then
        CLEAN=true
    elif [ "$SWTCH" = "-e" ] || [ "$SWTCH" = "--role" ]
    then
        ROLE=true
    elif [ "$SWTCH" = "-h" ] || [ "$SWTCH" = "--hatop" ]
    then
        HAT=true
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

    if $INSTL
    then
        "$CURL" www.richnusgeeks.me > /dev/null 2>&1
        if [ $? -ne 0 ]
        then
            exitOnErr "Check your internet/dns settings"
        fi
    fi 

    "$SRVC" "$IPTBLS" stop
    "$SRVC" "$IPTBLS" status

    "$CHKCNFG" "$IPTBLS" off
    "$CHKCNFG" --list "$IPTBLS"

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

    "$YUM" -y install "$PCREDEVEL"
    if [ $? -ne 0 ]
    then
        exitOnErr "$YUM install $PCREDEVEL failed"
    fi

}

dwnldHAPrxy() {

    "$WGET" -nc "$HAPTBLNK/${HAPRT}.tar.gz"
    if [ $? -ne 0 ]
    then
        exitOnErr "$WGET $HAPTBLNK/${HAPRT}.tar.gz failed"
    fi

    "$SLEEP" "$SLPPRD"

    "$TAR" zxvf "${HAPRT}.tar.gz"
    if [ $? -ne 0 ]
    then
        exitOnErr "$TAR zxvf ${HAPRT}.tar.gz failed"
    fi

}

cmplInstlHAP() {

    if [ -d "$HAPRT" ]
    then

        cd "$HAPRT"
        if [ $? -eq 0 ]
        then

            make TARGET=linux26 USE_PCRE=1
            if [ $? -ne 0 ]
            then
                exitOnErr "Compilation of HAProxy source failed"
            else
                make install
                if [ $? -ne 0 ]
                then
                    exitOnErr "Installation of HAProxy binary failed"
                fi  
            fi
  
        fi

    fi

}

crteHAPConf() {

    "$MKDR" -pv "$HAPCNFDIR"

    #if [ ! -e "$HAPCNFDIR/$HAPCNF" ]
    #then

        > "$HAPCNFDIR/$HAPCNF"
        "$ECHO" "global" >> "$HAPCNFDIR/$HAPCNF"
        "$ECHO" "    log 127.0.0.1 local0 debug" >> "$HAPCNFDIR/$HAPCNF"
        "$ECHO" "    maxconn 4096" >> "$HAPCNFDIR/$HAPCNF"
        "$ECHO" "    stats socket /tmp/haproxy" >> "$HAPCNFDIR/$HAPCNF"
        "$ECHO" "" >> "$HAPCNFDIR/$HAPCNF"

        "$ECHO" "defaults" >> "$HAPCNFDIR/$HAPCNF"
        "$ECHO" "    log global" >> "$HAPCNFDIR/$HAPCNF"
        "$ECHO" "    mode http" >> "$HAPCNFDIR/$HAPCNF"
        "$ECHO" "    timeout connect 5s" >> "$HAPCNFDIR/$HAPCNF"
        "$ECHO" "    timeout client 50s" >> "$HAPCNFDIR/$HAPCNF"
        "$ECHO" "    timeout server 600s" >> "$HAPCNFDIR/$HAPCNF"
        "$ECHO" "    option dontlognull" >> "$HAPCNFDIR/$HAPCNF"
        "$ECHO" "    option httplog" >> "$HAPCNFDIR/$HAPCNF"
        "$ECHO" "    option redispatch" >> "$HAPCNFDIR/$HAPCNF"
        "$ECHO" "    balance roundrobin" >> "$HAPCNFDIR/$HAPCNF"
        "$ECHO" "    stats enable" >> "$HAPCNFDIR/$HAPCNF"
        "$ECHO" "    stats hide-version" >> "$HAPCNFDIR/$HAPCNF"
        "$ECHO" "    stats scope ." >> "$HAPCNFDIR/$HAPCNF"
        "$ECHO" "    stats realm Haproxy\ Statistics" >> "$HAPCNFDIR/$HAPCNF"
        "$ECHO" "    stats uri /haproxy?stats" >> "$HAPCNFDIR/$HAPCNF"
        "$ECHO" "" >> "$HAPCNFDIR/$HAPCNF"

        "$ECHO" "frontend http" >> "$HAPCNFDIR/$HAPCNF"
        "$ECHO" "    mode http" >> "$HAPCNFDIR/$HAPCNF"
        #"$ECHO" "    maxconn 2000" >> "$HAPCNFDIR/$HAPCNF"
        "$ECHO" "    bind 0.0.0.0:80" >> "$HAPCNFDIR/$HAPCNF"
        "$ECHO" "    default_backend servers-http" >> "$HAPCNFDIR/$HAPCNF"
        "$ECHO" "" >> "$HAPCNFDIR/$HAPCNF"
        
        "$ECHO" "frontend tcp" >> "$HAPCNFDIR/$HAPCNF"
        "$ECHO" "    mode tcp" >> "$HAPCNFDIR/$HAPCNF"
        "$ECHO" "    option tcplog" >> "$HAPCNFDIR/$HAPCNF"
        #"$ECHO" "    maxconn 2000" >> "$HAPCNFDIR/$HAPCNF"
        "$ECHO" "    bind 0.0.0.0:5000" >> "$HAPCNFDIR/$HAPCNF"
        "$ECHO" "    default_backend servers-tcp" >> "$HAPCNFDIR/$HAPCNF"
        "$ECHO" "" >> "$HAPCNFDIR/$HAPCNF"

        "$ECHO" "backend servers-http" >> "$HAPCNFDIR/$HAPCNF"
        "$ECHO" "    server server1 127.0.0.1:80 check" >> "$HAPCNFDIR/$HAPCNF"
        "$ECHO" "" >> "$HAPCNFDIR/$HAPCNF"

        "$ECHO" "backend servers-tcp" >> "$HAPCNFDIR/$HAPCNF"
        "$ECHO" "    mode tcp" >> "$HAPCNFDIR/$HAPCNF"
        "$ECHO" "    server server1 127.0.0.1:5000 check" >> "$HAPCNFDIR/$HAPCNF"
        "$ECHO" "" >> "$HAPCNFDIR/$HAPCNF"

        "$SLEEP" "$SLPPRD"
        "$HAPBINDIR/haproxy" -c -f "$HAPCNFDIR/$HAPCNF"
        if [ $? -ne 0 ]
        then
            exitOnErr "HAProxy conf file check failed"
        fi

    #fi

}

getRole() {

    local role=$($SED -n '/^ *ROLE/,/^ *end/p' $HAPRLSFL | $GREP -Ei '(RABBITMQ|REDIS)' | $SED -n 's/ *\([a-zA-Z]\{1,\}\) */\1/p')
    
    if [ -z "$role" ]
    then
        exitOnErr "Empty role returned from $HAPRLSFL"
    fi

    "$ECHO" "$role"

}

getBknds() {

    local bknds=$($SED -n "/^ *$role/,/^ *end/p" $HAPRLSFL | $AWK -F"=" '{print $2}' | $SED -n 's/^ \{1,\}//p' | $SED -n 's/ \{1,\}$//p')

    if [ -z "$bknds" ]
    then
        exitOnErr "Empty backends list returned from $HAPRLSFL"
    fi

    "$ECHO" "$bknds"

}

getEnv() {

    local env=$($SED -n "/^ *$role/,/^ *end/p" $HAPRLSFL | $SED -n 's/ *env *= *\([a-zA-Z]\{1,\}[0-9]*\)/\1/p')

    if [ -z "$env" ]
    then
        exitOnErr "Empty env returned from $HAPRLSFL"
    fi

    "$ECHO" "$env"

}

cnfgrTmeOts() {

    local role=$1

    local connect=$($SED -n "/^ *$role/,/^ *end/p" $HAPRLSFL | $SED -n 's/ *connect *= *\([0-9]\{1,\}[sm]\{1\}\)/\1/p')

    local client=$($SED -n "/^ *$role/,/^ *end/p" $HAPRLSFL | $SED -n 's/ *client *= *\([0-9]\{1,\}[sm]\{1\}\)/\1/p')

    local server=$($SED -n "/^ *$role/,/^ *end/p" $HAPRLSFL | $SED -n 's/ *server *= *\([0-9]\{1,\}[sm]\{1\}\)/\1/p')

    if [ -z "$connect" ] || [ -z "$client" ] || [ -z "$server" ]
    then
        exitOnErr "Empty connect/client/server timeout(s) returned from $HAPRLSFL"
    fi 

    if ! "$SED" -i "/timeout \{1,\}connect/s/[0-9]\{1,\}[sm]\{1\}/$connect/" "$HAPCNFDIR/$HAPCNF"
    then
        exitOnErr "Updation of timeout connect to $connect in $HAPCNFDIR/$HAPCNF failed"
    fi 

    if ! "$SED" -i "/timeout \{1,\}client/s/[0-9]\{1,\}[sm]\{1\}/$client/" "$HAPCNFDIR/$HAPCNF"
    then
        exitOnErr "Updation of timeout client to $connect in $HAPCNFDIR/$HAPCNF failed"
    fi 

    if ! "$SED" -i "/timeout \{1,\}server/s/[0-9]\{1,\}[sm]\{1\}/$server/" "$HAPCNFDIR/$HAPCNF"
    then
        exitOnErr "Updation of timeout server to $server in $HAPCNFDIR/$HAPCNF failed"
    fi

    if [ "$role" = "RABBITMQ" ] || [ "$role" = "REDIS" ]
    then
        if [ "$role" = "RABBITMQ" ]
        then
            if ! "$SED" -i '/^ \{1,\}balance/s/roundrobin/leastconn/' "$HAPCNFDIR/$HAPCNF"
            then
                exitOnErr "RABBITMQ balance logic change to leastconn in $HAPCNFDIR/$HAPCNF failed"
            fi
        fi

        if ! "$SED" -i '/^ *option *redispatch/d' "$HAPCNFDIR/$HAPCNF"
        then
            exitOnErr "(RABBITMQ|REDIS) option redispatch removal from $HAPCNFDIR/$HAPCNF failed"
        fi
        
        if ! "$SED" -i '/^ *defaults/a\    option tcpka' "$HAPCNFDIR/$HAPCNF"
        then
            exitOnErr "Appending option tcpka to $HAPCNFDIR/$HAPCNF failed"
        fi

    fi 
 
}

getHttpPrt() {

    local hprt=$($SED -n "/^ *$role/,/^ *end/p" $HAPRLSFL | $GREP '^ *type' | $AWK -F"=" '{print $2}' | $SED 's/ *tcp:[0-9]\{1,\} *//' | $SED 's/ *http:\([0-9]\{1,\}\) */\1/')

    if [ -z "$hprt" ]
    then
        exitOnErr "Empty http port returned from $HAPRLSFL"
    fi

    "$ECHO" "$hprt" 

}

getTcpPrt() {

        local tprt=$($SED -n "/^ *$role/,/^ *end/p" $HAPRLSFL | $GREP '^ *type' | $AWK -F"=" '{print $2}' | $SED 's/ *http:[0-9]\{1,\} *//' | $SED 's/ *tcp:\([0-9]\{1,\}\) */\1/')

    if [ -z "$tprt" ]
    then
        exitOnErr "Empty tcp port returned from $HAPRLSFL"
    fi

    "$ECHO" "$tprt" 
}

cnfgrFrntnds() {

    local role=$1

    if ! "$SED" -n "/^ *$role/,/^ *end/p" "$HAPRLSFL" | "$GREP" '^ *type *=' | "$GREP" http > /dev/null 2>&1
    then

        if ! "$SED" -i '/^ *frontend \{1,\}http/,/^ *$/s/^/#/' "$HAPCNFDIR/$HAPCNF"
        then
            exitOnErr "Commenting of frontend http section in $HAPCNFDIR/$HAPCNF failed" 
        fi

    else

        local hprt=$(getHttpPrt)
        if ! "$SED" -i "/^ *frontend \{1,\}http/,/^ *$/s/0.0.0.0:[0-9]\{1,\}/0.0.0.0:$hprt/" "$HAPCNFDIR/$HAPCNF"
        then
            exitOnErr "Frontend http bind port not changed to $hprt in $HAPCNFDIR/$HAPCNF"
        fi

        if [ "$role" = "RABBITMQ" ]
        then
            if ! "$SED" -i '/^ *default_backend \{1,\}servers-http/a\
\
frontend http\
    mode http\
    bind 0.0.0.0:15672\
    default_backend servers-http\ ' "$HAPCNFDIR/$HAPCNF"
            then
                exitOnErr "Append of additional frontend http for RABBITMQ failed"
            fi
        fi

    fi   

    if ! "$SED" -n "/^ *$role/,/^ *end/p" "$HAPRLSFL" | "$GREP" '^ *type *=' | "$GREP" tcp > /dev/null 2>&1
    then

        if ! "$SED" -i '/^ *frontend \{1,\}tcp/,/^ *$/s/^/#/' "$HAPCNFDIR/$HAPCNF"
        then
            exitOnErr "Commenting of frontend tcp section in $HAPCNFDIR/$HAPCNF failed" 
        fi

    else

        local tprt=$(getTcpPrt)
        if ! "$SED" -i "/^ *frontend \{1,\}tcp/,/^ *$/s/0.0.0.0:[0-9]\{1,\}/0.0.0.0:$tprt/" "$HAPCNFDIR/$HAPCNF"
        then
            exitOnErr "Frontend tcp bind port not changed to $tprt $HAPCNFDIR/$HAPCNF"
        fi
 
    fi
   
}

cnfgrBcknds() {

    local role=$1
    
    local env=$(getEnv)

    local bcknds=$($SED -n "/^ *$role/,/^ *end/p" $HAPRLSFL | $GREP backends | $AWK -F"=" '{print $2}' | $SED 's/^ \{1,\}//' | $SED 's/ \{1,\}$//')

    if ! "$SED" -n "/^ *$role/,/^ *end/p" "$HAPRLSFL" | "$GREP" '^ *type *=' | "$GREP" http > /dev/null 2>&1
    then

        if ! "$SED" -i '/^ *backend \{1,\}servers-http/,/^ *$/s/^/#/' "$HAPCNFDIR/$HAPCNF"
        then
            exitOnErr "Commenting of backend http section in $HAPCNFDIR/$HAPCNF failed" 
        fi

    else

        local hprt=$(getHttpPrt)

        if [ ! -z "$bcknds" ]
        then
            local j=0
            for i in $bcknds
            do
                local srvrstr="server $role$j.$env $i:$hprt check"

                if [ "$role" = "RABBITMQ" ]
                then
                    srvrstr="server $role$j.$env $i:15672 check"
                fi

                if ! "$SED" -i "/127.0.0.1:80/a\    $srvrstr" "$HAPCNFDIR/$HAPCNF"
                then
                    exitOnErr "Appending backend server $i:$hprt to $HAPCNFDIR/$HAPCNF failed"
                fi
                let "j += 1"
            done

            if ! "$SED" -i '/127.0.0.1:80/d' "$HAPCNFDIR/$HAPCNF"
            then
                exitOnErr "Removal of localhost entry from servers-http section in $HAPCNFDIR/$HAPCNF failed"
            fi
        fi

    fi   

    if ! "$SED" -n "/^ *$role/,/^ *end/p" "$HAPRLSFL" | "$GREP" '^ *type *=' | "$GREP" tcp > /dev/null 2>&1
    then

        if ! "$SED" -i '/^ *backend \{1,\}servers-tcp/,/^ *$/s/^/#/' "$HAPCNFDIR/$HAPCNF"
        then
            exitOnErr "Commenting of frontend tcp section in $HAPCNFDIR/$HAPCNF failed" 
        fi

    else

        local tprt=$(getTcpPrt)

        if [ ! -z "$bcknds" ]
        then
            local j=0
            for i in $bcknds
            do
                local srvrstr="server $role$j.$env $i:$tprt check"

                if [ "$role" = "REDIS" ]
                then  
                    if [ $j -eq 0 ]
                    then
                        srvrstr="server $role$j.$env $i:$tprt check inter 500 downinter 500" 
                    else
                        srvrstr="server $role$j.$env $i:$tprt check inter 500 backup" 

                    fi   

                fi

                if ! "$SED" -i "/127.0.0.1:5000/a\    $srvrstr" "$HAPCNFDIR/$HAPCNF"
                then
                    exitOnErr "Appending backend server $i:$tprt to $HAPCNFDIR/$HAPCNF failed"
                fi
                let "j += 1"
            done

            if ! "$SED" -i '/127.0.0.1:5000/d' "$HAPCNFDIR/$HAPCNF"
            then
                exitOnErr "Removal of localhost entry from servers-tcp section in $HAPCNFDIR/$HAPCNF failed"
            fi
        fi

    fi

}

cnfgrHltchk() {

    local role=$1
    local ftcp=false
    local fhttp=false

    if "$SED" -n "/^ *$role/,/^ *end/p" "$HAPRLSFL" | "$GREP" '^ *type *=' | "$GREP" http > /dev/null 2>&1
    then
        fhttp=true
    fi
    
    if "$SED" -n "/^ *$role/,/^ *end/p" "$HAPRLSFL" | "$GREP" '^ *type *=' | "$GREP" tcp > /dev/null 2>&1
    then
        ftcp=true
    fi

    local hltchk=$($SED -n "/^ *$role/,/^ *end/p" $HAPRLSFL | $GREP healthcheck | $AWK -F"=" '{print $2}' | $SED -n 's/^ *//p' | $SED -n 's/ *$//p')

    if [ ! -z "$hltchk" ]
    then
        "$SED" -i '/^ *option \{1,\}httpchk/d' "$HAPCNFDIR/$HAPCNF"

        if $fhttp && ! $ftcp 
        then
          
            if ! "$SED" -i "/^ *backend \{1,\}servers-http/a\
    option httpchk GET $hltchk" "$HAPCNFDIR/$HAPCNF"
            then
                exitOnErr "Appending healthcheck uri $hltchk to $HAPCNFDIR/$HAPCNF failed"
            fi

        elif ! $fhttp && $ftcp
        then

            if ! "$SED" -i "/^ *backend \{1,\}servers-tcp/a\
    option httpchk GET $hltchk" "$HAPCNFDIR/$HAPCNF"
            then
                exitOnErr "Appending healthcheck uri $hltchk to $HAPCNFDIR/$HAPCNF failed"
            fi

        elif $fhttp && $ftcp
        then 

            if ! "$SED" -i "/^ *backend \{1,\}servers-http/a\
    option httpchk GET $hltchk" "$HAPCNFDIR/$HAPCNF"
            then
                exitOnErr "Appending healthcheck uri $hltchk to $HAPCNFDIR/$HAPCNF failed"
            fi

        fi
 
    fi

}

cnfgrHAPRole() {

    if [ -f "$HAPRLSFL" ]
    then
        if [ -f "$HAPCNFDIR/$HAPCNF" ]
        then
            local role=$(getRole)
            cnfgrTmeOts "$role"
            cnfgrFrntnds "$role"
            cnfgrBcknds "$role"
            cnfgrHltchk "$role"
        fi
    else
        exitOnErr "Required $HAPRLSFL missing"    
    fi 

}

crteUpstrtConf() {

    if [ ! -d "$UPSTRTDIR" ]
    then
        extOnErr "$UPSTRTDIR does not exist"
    else
        if [ ! -e "$UPSTRTDIR/$HAPCNF" ]
        then
            > "$UPSTRTDIR/$HAPCNF"
            "$ECHO" "start on runlevel [35]" >> "$UPSTRTDIR/haproxy.conf"
            "$ECHO" "stop on runlevel [!35]" >> "$UPSTRTDIR/haproxy.conf"
            "$ECHO" "respawn" >> "$UPSTRTDIR/haproxy.conf"
            "$ECHO" "exec $HAPBINDIR/haproxy -f $HAPCNFDIR/$HAPCNF" >> "$UPSTRTDIR/haproxy.conf"
        fi
    fi

}

crteHAPlggng() {

    if [ ! -d "$RSLDDIR" ]
    then
        exitOnErr "$RSLDDIR does not exist"
    else
        if [ ! -e "$RSLDDIR/$LGCNFGFL" ]
        then
            > "$RSLDDIR/$LGCNFGFL"
            "$ECHO" '$ModLoad imudp' >> "$RSLDDIR/$LGCNFGFL" 
            "$ECHO" '$UDPServerAddress 127.0.0.1' >> "$RSLDDIR/$LGCNFGFL" 
            "$ECHO" '$UDPServerRun 514' >> "$RSLDDIR/$LGCNFGFL"
            "$ECHO" '' >> "$RSLDDIR/$LGCNFGFL"
            "$ECHO" 'local1.* -/var/log/haproxy_1.log' >> "$RSLDDIR/$LGCNFGFL"
            "$ECHO" '& ~' >> "$RSLDDIR/$LGCNFGFL"
        fi
    fi 

}

crteHAPlgrtte() {

    if [ ! -d "$LGRTDIR" ]
    then
        exitOnErr "$LGRTDIR does not exist"
    else
        if [ ! -e "$LGRTDIR/haproxy" ]
        then
            > "$LGRTDIR/haproxy"
            "$ECHO" '/var/log/haproxy*.log' >> "$LGRTDIR/haproxy"
            "$ECHO" '{' >> "$LGRTDIR/haproxy"
            "$ECHO" '    rotate 4' >> "$LGRTDIR/haproxy"
            "$ECHO" '    weekly' >> "$LGRTDIR/haproxy"
            "$ECHO" '    missingok' >> "$LGRTDIR/haproxy"
            "$ECHO" '    notifempty' >> "$LGRTDIR/haproxy"
            "$ECHO" '    compress' >> "$LGRTDIR/haproxy"
            "$ECHO" '    delaycompress' >> "$LGRTDIR/haproxy"
            "$ECHO" '    sharedscripts' >> "$LGRTDIR/haproxy"
            "$ECHO" '    postrotate' >> "$LGRTDIR/haproxy"
            "$ECHO" '        reload rsyslog >/dev/null 2>&1 || true' >> "$LGRTDIR/haproxy"
            "$ECHO" '    endscript' >> "$LGRTDIR/haproxy"
            "$ECHO" '}' >> "$LGRTDIR/haproxy"
        fi
    fi

}

strtHAPSrvc() {

    local stts=$($SSTTS haproxy)
    if [ ! -z "$stts" ]
    then
        if "$ECHO" "$stts" 2>&1 | "$GREP" -i 'stop/waiting' > /dev/null 2>&1
        then
            if ! "$SSTRT" haproxy 
            then
                exitOnErr "$SSTRT haproxy failed"
            fi
        fi
    fi

    "$SLEEP" "$SLPPRD"

}

stopHAPSrvc() {

    local stts=$($SSTTS haproxy)
    if [ ! -z "$stts" ]
    then
        if "$ECHO" "$stts" 2>&1 | "$GREP" -i 'start/running' > /dev/null 2>&1
        then
            if ! "$SSTOP" haproxy
            then
                exitOnErr "$SSTOP haproxy failed"
            fi
        fi
    fi
 
    "$SLEEP" "$SLPPRD"

}

cleanHAP() {

    "$RM" -fv "$HAPBINDIR/haproxy"
    "$RM" -fv "$HAPCNFDIR/$HAPCNF"
    "$RM" -fv "$UPSTRTDIR/$HAPCNF"
    "$RM" -fv "$RSLDDIR/$LGCNFGFL"
    "$RM" -fv "$LGRTDIR/haproxy"
    "$RM" -fv /usr/local/share/man/man1/haproxy.1
    "$RM" -rf /usr/local/bin/hatop 
    "$RM" -fv /usr/local/share/man/man1/hatop.1.gz
    "$RM" -rfv ${HAPRT}.tar.gz
    "$RM" -rfv ${HATOP}.tar.gz

}

instlHATop() {

    cd

    "$WGET" "$HATOPLNK/${HATOP}.tar.gz"
    if [ $? -ne 0 ]
    then
        exitOnErr "$WGET $HATOPLNK/${HATOP}.tar.gz failed"
    fi

    "$TAR" zxvf "${HATOP}.tar.gz"
    if [ $? -ne 0 ]
    then
        exitOnErr "$TAR zxvf ${HATOP}.tar.gz failed"
    fi

    cd "$HATOP"
    
    "$INSTALL" -m 755 bin/hatop /usr/local/bin
    if [ $? -ne 0 ]
    then
        exitOnErr "Installation of HATop in /usr/local/bin failed"
    fi

    "$INSTALL" -m 644 man/hatop.1 /usr/local/share/man/man1

    "$GZIP" /usr/local/share/man/man1/hatop.1

    "$YUM" -y install nc
    if [ $? -ne 0 ]
    then
        exitOnErr "$YUM install nc failed"
    fi

}

# FIXME: currently not working, maybe due to process spawning and curses combo? 
invkHATop() {

    local stts=$($SSTTS haproxy)
    if [ ! -z "$stts" ]
    then
        if "$ECHO" "$stts" 2>&1 | "$GREP" -i 'start/running' > /dev/null 2>&1
        then
            "$HATBINDIR/hatop" -s /tmp/haproxy -i 1
        else           
            exitOnErr "HAProxy service not running"
        fi
     fi

}

dumpHAPInfo() {

    ls -lhrt "$HAPBINDIR"
    "$HAPBINDIR/haproxy" -vv 
    ls -lhrt "$HAPCNFDIR/$HAPCNF"
    "$CAT" "$HAPCNFDIR/$HAPCNF"
    ls -lhrt "$UPSTRTDIR/$HAPCNF"
    "$CAT" "$UPSTRTDIR/$HAPCNF"
    ls -lhrt "$RSLDDIR/$LGCNFGFL"
    "$CAT" "$RSLDDIR/$LGCNFGFL"
    ls -lhrt "$LGRTDIR/haproxy"
    "$CAT" "$LGRTDIR/haproxy"
    "$NTST" -nlptu | "$GREP" haproxy

}

main() {

    preChecks
    
    if $INSTL
    then
        instlDeps
        dwnldHAPrxy
        cmplInstlHAP
        instlHATop
    fi

    if $CNFGR
    then
        stopHAPSrvc
        crteHAPConf
        crteUpstrtConf
        crteHAPlggng
        crteHAPlgrtte
        strtHAPSrvc
        dumpHAPInfo
    fi

    if $DUMP
    then
        dumpHAPInfo
    fi

    if $ALL
    then
        instlDeps
        dwnldHAPrxy
        cmplInstlHAP
        crteHAPConf
        crteUpstrtConf
        crteHAPlggng
        crteHAPlgrtte
        strtHAPSrvc
        dumpHAPInfo
        instlHATop
    fi

    if $START
    then
        strtHAPSrvc
    fi

    if $STOP
    then
        stopHAPSrvc
    fi

    if $CLEAN
    then
        stopHAPSrvc
        cleanHAP
    fi

    if $ROLE
    then
        stopHAPSrvc
        crteHAPConf
        cnfgrHAPRole
        strtHAPSrvc
        dumpHAPInfo
    fi

    if $HAT
    then
        invkHATop
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
LGNME=$("$ECHO" $("$BSNME" "$0") | "$SED" -n 's/\.sh//p')
main 2>&1 | "$TEE" "${LGNME}.log"
# <end of main section>

