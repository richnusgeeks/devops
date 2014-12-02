#! /usr/bin/env bash
############################################################################
# File name : instl_cnfgr_elasticsearch.sh
# Purpose   : Install and configure Elasticsearch on CentOS 6.x (x>=4)
#             for a cluster configuration.
# Usages    : ./instl_cnfgr_elasticsearch.sh <-i|--install|-c|--config
#                                     |-d|--dump|-e|--recnfg|-r|--clean
#                                     |-s|--start|-t|--stop|-a|--all>
#             (make it executable using chmod +x)
# Start date : 10/15/2013
# End date   : 10/xx/2013
# Author : Ankur Kumar <richnusgeeks@gmail.com>
# Download link : www.richnusgeeks.me
# License : RichNusGeeks
# Version : 0.0.1
# Modification history : 1. Use env. specific multicast group address on
#                           reconfiguration,
#                        2. upgrade to v0.90.11, Ankur 02/21/14,
# Notes : TODO: 1. Remove hardcoded strings,
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
SLPSRVR=25
SLPFLSYS=5
NUMSHRDS=50
NUMRPLCA=1
THRSOPS=10000
RFRSHINTVL='30s'
STRTPRT=9200
ENDPRT=9300
ELSLNK='https://download.elasticsearch.org/elasticsearch/elasticsearch/elasticsearch-0.90.11.noarch.rpm'
IPTBLS='iptables'
ELSPTH='/usr/share/elasticsearch'
ELSCNFPTH='/etc/elasticsearch'
ELSCNF='elasticsearch.yml'
ELSNDS='http://localhost:9200/_cluster/nodes?pretty=true'
ELSHLTH='http://localhost:9200/_cluster/health?pretty=true'
RECNFGCNF='elasticsearch.conf'
ELSPLGNS="lukas-vlcek/bigdesk \
          mobz/elasticsearch-head \
          com.yakaz.elasticsearch.plugins/elasticsearch-action-updatebyquery/1.4.1"
ORACLEJDK='jdk-7u45-linux-x64.rpm'
ORACLEPCKG='jdk-1.7.0_45-fcs.x86_64'
ELSSRVR='elasticsearch'
CNFGPARAMS="cluster.name \
            node.name \
            node.data \
            node.master \
            node.client \
            http.enabled \
            index.number_of_shards \
            index.number_of_replicas \
            index.translog.flush_threshold_ops \
            index.refresh_interval \
            index.store.type \
            path.data \
            discovery.zen.ping.unicast.hosts \
            discovery.zen.ping.multicast.enabled \
            discovery.zen.ping.multicast.group \
            index.query.bool.max_clause_count \
            threadpool.bulk.size \
            threadpool.bulk.queue_size"
ELSDATAROOT='/var/lib/elasticsearch'
FSTAB='/etc/fstab'
SRVCELS='/etc/init.d/elasticsearch'
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
    "$ECHO" "        -i|--install Install Elasticsearch,"
    "$ECHO" "        -c|--config  Configure Elasticsearch post install,"
    "$ECHO" "        -d|--dump    Dump various Elasticsearch related info,"
    "$ECHO" "        -s|--start   Start Elasticsearch,"
    "$ECHO" "        -t|--start   Stop Elasticsearch,"
    "$ECHO" "        -r|--clean   Remove Elasticsearch from node,"
    "$ECHO" "        -e|--recnfg  Reconfigure Elasticsearch cluster,"
    "$ECHO" "        -a|--all     Install+Configure+Dump Elasticsearch,"
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

instlJDK() {

    local openjdk=$("$RPM" -qa '*openjdk*')
    if [ ! -z "$openjdk" ]
    then
        if ! "$RPM" -e "$openjdk"
        then
            exitOnErr "$RPM -e $openjdk failed"    
        fi
    fi

    if ! "$RPM" -qa | "$GREP" "$ORACLEPCKG" > /dev/null 2>&1
    then
        if [ ! -e "/tmp/$ORACLEJDK" ]
        then
            exitOnErr "Required /tmp/$ORACLEJDK not found"
        else
            if ! "$RPM" -Uvh "/tmp/$ORACLEJDK"
            then
                exitOnErr "$RPM -Uvh /tmp/$ORACLEJDK failed"
            else
                "$SLEEP" "$SLPFLSYS"
            fi
        fi 
    fi

}

removeJDK() {

    if "$RPM" -qa | "$GREP" "$ORACLEPCKG" > /dev/null 2>&1
    then
        if ! "$RPM" -e "$ORACLEPCKG"
        then
            exitOnErr "$RPM -e $ORACLEPCKG failed"
        else
            "$SLEEP" "$SLPFLSYS"
        fi
    fi

}

preChecks() {

    if [ "$EUID" -ne 0 ]
    then
        exitOnErr "This script needs superuser rights"
    fi

    parseArgs
    if $INSTL || $ALL
    then
        instlJDK
    fi

    if ! "$CURL" www.richnusgeeks.me > /dev/null 2>&1
    then
        exitOnErr "Check your internet/dns settings"
    fi

    "$SRVC" "$IPTBLS" stop
    "$SRVC" "$IPTBLS" status

    "$CHKCNFG" "$IPTBLS" off
    "$CHKCNFG" --list "$IPTBLS"

}

instlELS() {

    local elsrpm=$("$BSNME" "$ELSLNK")

    local elserpm=$("$RPM" -qa '*elasticsearch*')
    if [ -z "$elserpm" ]
    then
        if [ ! -e "$elsrpm" ]
        then
    
            if ! "$WGET" "$ELSLNK"
            then
                exitOnErr "$WGET $ELSLNK failed"
            fi

            if [ -e "$elsrpm" ]
            then
                if ! "$RPM" -Uvh "$elsrpm"
                then
                    exitOnErr "$RPM -Uvh $elsrpm failed"
                fi
            fi

        else
            if ! "$RPM" -Uvh "$elsrpm"
            then
                exitOnErr "$RPM -Uvh $elsrpm failed"
            fi

        fi
    fi

    "$SLEEP" "$SLPSRVR"

}

instlELSPlgns() {

    for i in $ELSPLGNS
    do

        if ! "$ELSPTH/bin/plugin" -install "$i"
        then
            "$ECHO" "$ELSPTH/bin/plugin -install $i failed, continuing ..." 
        fi

    done

}

formELSNodeNme() {

    local ndip=$("$IFCNFG" eth0 | "$GREP" -E '^ *inet *addr' | "$AWK" '{print $2}' | "$AWK" -F":" '{print $2}')

    "$ECHO" "ELS$ndip"

}

cnfgrELS() {

    if [ ! -f "$ELSCNFPTH/$ELSCNF" ]
    then
        exitOnErr "Required $ELSCNFPTH/$ELSCNF not found"
    else
        # TODO: Replace with hash map and loop based logic.
        local ndnme=$(formELSNodeNme)
        if [ ! -z "$ndnme" ]
        then
           if ! "$GREP" -E '^ *node.name: $ndnme' "$ELSCNFPTH/$ELSCNF" > /dev/null 2>&1
           then
               "$ECHO" "node.name: $ndnme" >> "$ELSCNFPTH/$ELSCNF"
           fi 
        fi

        if ! "$GREP" -E '^ *cluster.name: ELSSWDEV' "$ELSCNFPTH/$ELSCNF" > /dev/null 2>&1
        then
            "$ECHO" "cluster.name: ELSSWDEV" >> "$ELSCNFPTH/$ELSCNF"
        fi

        if ! "$GREP" -E "^ *index.number_of_shards: $NUMSHRDS" "$ELSCNFPTH/$ELSCNF" > /dev/null 2>&1
        then
            "$ECHO" "index.number_of_shards: $NUMSHRDS" >> "$ELSCNFPTH/$ELSCNF"
        fi

        if ! "$GREP" -E "^ *index.number_of_replicas: $NUMRPLCA" "$ELSCNFPTH/$ELSCNF" > /dev/null 2>&1
        then
            "$ECHO" "index.number_of_replicas: $NUMRPLCA" >> "$ELSCNFPTH/$ELSCNF"
        fi

        if ! "$GREP" -E "^ *index.translog.flush_threshold_ops: $THRSOPS" "$ELSCNFPTH/$ELSCNF" > /dev/null 2>&1
        then
            "$ECHO" "index.translog.flush_threshold_ops: $THRSOPS" >> "$ELSCNFPTH/$ELSCNF"
        fi

        if ! "$GREP" -E '^ *index.merge.policy.use_compound_files: false' "$ELSCNFPTH/$ELSCNF" > /dev/null 2>&1
        then
            "$ECHO" 'index.merge.policy.use_compound_files: false' >> "$ELSCNFPTH/$ELSCNF"
        fi

        if ! "$GREP" -E "^ *index.refresh_interval: $RFRSHINTVL" "$ELSCNFPTH/$ELSCNF" > /dev/null 2>&1
        then
            "$ECHO" "index.refresh_interval: $RFRSHINTVL" >> "$ELSCNFPTH/$ELSCNF"
        fi

        if ! "$GREP" -E '^ *index.store_type: mmapfs' "$ELSCNFPTH/$ELSCNF" > /dev/null 2>&1
        then
            "$ECHO" 'index.store_type: mmapfs' >> "$ELSCNFPTH/$ELSCNF"
        fi

        if ! "$GREP" -E '^ *index.query.bool.max_clause_count: 10000000' "$ELSCNFPTH/$ELSCNF" > /dev/null 2>&1
        then
            "$ECHO" 'index.query.bool.max_clause_count: 10000000' >> "$ELSCNFPTH/$ELSCNF"
        fi

        if ! "$GREP" -E '^ *threadpool.bulk.size: 16' "$ELSCNFPTH/$ELSCNF" > /dev/null 2>&1
        then
            "$ECHO" 'threadpool.bulk.size: 16' >> "$ELSCNFPTH/$ELSCNF"
        fi

        if ! "$GREP" -E '^ *threadpool.bulk.queue_size: 500' "$ELSCNFPTH/$ELSCNF" > /dev/null 2>&1
        then
            "$ECHO" 'threadpool.bulk.queue_size: 500' >> "$ELSCNFPTH/$ELSCNF"
        fi

        "$SLEEP" "$SLPFLSYS"
    fi

}

startELS() {

    if ! "$SRVC" "$ELSSRVR" status
    then
        if ! "$SRVC" "$ELSSRVR" start
        then
            exitOnErr "$SRVC $ELSSRVR start failed"
        else
            "$SLEEP" "$SLPSRVR"
        fi
    fi   

}

stopELS() {

    if "$SRVC" "$ELSSRVR" status
    then
        if ! "$SRVC" "$ELSSRVR" stop
        then
            exitOnErr "$SRVC $ELSSRVR stop failed"
        else
            "$SLEEP" "$SLPSRVR"
        fi
    fi   

}

cleanELS() {

    local elspkg=$("$RPM" -qa '*elasticsearch*')
    if [ ! -z "$elspkg" ]
    then
        if ! "$RPM" -e "$elspkg"
        then
            exitOnErr "$RPM -e $elspkg failed"
        else
            "$SLEEP" "$SLPFLSYS"
        fi 
    fi

    "$RM" -rfv "$ELSPTH"
    "$RM" -rfv "$ELSCNFPTH"

}

dumpELS() {

    "$RPM" -qa "*jdk*" 
    "$RPM" -qa '*elasticsearch*'
    ls -lhrt $ELSPTH/*
    ls -lhrt $ELSCNFPTH/*
    "$CHKCNFG" --list 'elasticsearch'

    for e in $CNFGPARAMS
    do
        "$GREP" -E "^ *$e" "$ELSCNFPTH/$ELSCNF"
    done

    "$GREP" -E '^ *export ES_JAVA_OPTS' "$SRVCELS" 
    "$GREP" "$ELSDATAROOT" "$FSTAB"

    "$DF" -kh
    "$NTST" -nlptu | "$GREP" 'java'
    "$CURL" -XGET "$ELSNDS"
    "$ECHO"
    "$CURL" -XGET "$ELSHLTH"
    "$ECHO"
    "$ELSPTH/bin/plugin" -l

}

recnfgrMstr() {

    if "$SED" -i '/^ *node.master:/d' "$ELSCNFPTH/$ELSCNF"
    then
        "$ECHO" "node.master: true" >> "$ELSCNFPTH/$ELSCNF"
    else
        exitOnErr "$SED -i '/^ *node.master:/d' $ELSCNFPTH/$ELSCNF failed"
    fi
    
    if "$SED" -i '/^ *node.data:/d' "$ELSCNFPTH/$ELSCNF"
    then
        "$ECHO" "node.data: false" >> "$ELSCNFPTH/$ELSCNF"
    else
        exitOnErr "$SED -i '/^ *node.data:/d' $ELSCNFPTH/$ELSCNF failed"
    fi

    if "$SED" -i '/^ *node.client:/d' "$ELSCNFPTH/$ELSCNF"
    then
        "$ECHO" "node.client: false" >> "$ELSCNFPTH/$ELSCNF"
    else
        exitOnErr "$SED -i '/^ *node.client:/d' $ELSCNFPTH/$ELSCNF failed"
    fi

    if "$SED" -i '/^ *http.enabled:/d' "$ELSCNFPTH/$ELSCNF"
    then
        "$ECHO" "http.enabled: false" >> "$ELSCNFPTH/$ELSCNF"
    else
        exitOnErr "$SED -i '/^ *http.enabled:/d' $ELSCNFPTH/$ELSCNF failed"
    fi

    "$SLEEP" "$SLPFLSYS"

}

recnfgrData() {

    if "$SED" -i '/^ *node.master:/d' "$ELSCNFPTH/$ELSCNF"
    then
        "$ECHO" "node.master: false" >> "$ELSCNFPTH/$ELSCNF"
    else
        exitOnErr "$SED -i '/^ *node.master:/d' $ELSCNFPTH/$ELSCNF failed"
    fi
    
    if "$SED" -i '/^ *node.data:/d' "$ELSCNFPTH/$ELSCNF"
    then
        "$ECHO" "node.data: true" >> "$ELSCNFPTH/$ELSCNF"
    else
        exitOnErr "$SED -i '/^ *node.data:/d' $ELSCNFPTH/$ELSCNF failed"
    fi

    if  "$SED" -i '/^ *node.client:/d' "$ELSCNFPTH/$ELSCNF"
    then
        "$ECHO" "node.client: false" >> "$ELSCNFPTH/$ELSCNF"
    else
        exitOnErr "$SED -i '/^ *node.client:/d' $ELSCNFPTH/$ELSCNF failed"
    fi

    if  "$SED" -i '/^ *http.enabled:/d' "$ELSCNFPTH/$ELSCNF"
    then
        "$ECHO" "http.enabled: false" >> "$ELSCNFPTH/$ELSCNF"
    else
        exitOnErr "$SED -i '/^ *http.enabled:/d' $ELSCNFPTH/$ELSCNF failed"
    fi

    # TODO: Auto detect the partitions and be more intelligent.
    local dsks=$("$SED" -n 's/^ *DATADSKS *= *//p' "/tmp/$RECNFGCNF")
    local s=''
    for d in $dsks
    do
        if "$MKE2FS" -F -t ext4 "/dev/$d"
        then       
            "$MKDR" -pv "$ELSDATAROOT/data-$d"
            "$SLEEP" "$SLPFLSYS"

            if ! "$GREP" -E "^ */dev/$d *$ELSDATAROOT/data-$d *ext4 *defaults *0 *0" "$FSTAB" > /dev/null 2>&1
            then
                "$ECHO" "/dev/$d $ELSDATAROOT/data-$d ext4 defaults 0 0" >> "$FSTAB"   
            fi
        
            "$MOUNT" -a
            "$SLEEP" "$SLPFLSYS"
            "$CHOWN" -R elasticsearch:elasticsearch "$ELSDATAROOT/data-$d" 
             
        fi

        s+="$ELSDATAROOT/data-$d,"

    done

    s=$("$ECHO" "$s" | "$SED" 's/,$//')
    if "$SED" -i '/^ *path.data:/d' "$ELSCNFPTH/$ELSCNF"
    then
        "$ECHO" "path.data: $s" >> "$ELSCNFPTH/$ELSCNF"
    else
        exitOnErr "$SED -i '/^ *path.data:/d' $ELSCNFPTH/$ELSCNF failed"
    fi 

    local jpts=$("$SED" -n 's/^ *JAVAOPTS *= *//p' "/tmp/$RECNFGCNF")
    if [ ! -z "$jpts" ]
    then
        if ! "$SED" -i -e '/^ *export ES_JAVA_OPTS/d' \
                       -e "/^ *export ES_DIRECT_SIZE/a\\export ES_JAVA_OPTS='$jpts'" \
                       "$SRVCELS"
        then
            exitOnErr "Modification of ES_JAVA_OPTS in $SRVCELS failed"
        fi    
    fi
   
}

recnfgrClnt() {

    if "$SED" -i '/^ *node.master:/d' "$ELSCNFPTH/$ELSCNF"
    then
        "$ECHO" "node.master: false" >> "$ELSCNFPTH/$ELSCNF"
    else
        exitOnErr "$SED -i '/^ *node.master:/d' $ELSCNFPTH/$ELSCNF failed"
    fi
    
    if "$SED" -i '/^ *node.data:/d' "$ELSCNFPTH/$ELSCNF"
    then
        "$ECHO" "node.data: false" >> "$ELSCNFPTH/$ELSCNF"
    else 
        exitOnErr "$SED -i '/^ *node.data:/d' $ELSCNFPTH/$ELSCNF failed"
    fi

    if "$SED" -i '/^ *node.client:/d' "$ELSCNFPTH/$ELSCNF"
    then
        "$ECHO" "node.client: true" >> "$ELSCNFPTH/$ELSCNF"
    else
        exitOnErr "$SED -i '/^ *node.client:/d' $ELSCNFPTH/$ELSCNF failed"
    fi

    if "$SED" -i '/^ *http.enabled:/d' "$ELSCNFPTH/$ELSCNF"
    then
        "$ECHO" "http.enabled: true" >> "$ELSCNFPTH/$ELSCNF"
    else
        exitOnErr "$SED -i '/^ *http.enabled:/d' $ELSCNFPTH/$ELSCNF failed"
    fi

    "$SLEEP" "$SLPFLSYS"

}

recnfgrMltcst() {

    if ! "$SED" -i '/^ *discovery.zen.ping.unicast.hosts:/d' "$ELSCNFPTH/$ELSCNF"
    then
        exitOnErr "$SED -i '/^ *discovery.zen.ping.unicast.hosts:/d' $ELSCNFPTH/$ELSCNF failed"
    fi

    if ! "$SED" -i '/^ *discovery.zen.ping.multicast.enabled:/d' "$ELSCNFPTH/$ELSCNF"
    then
        exitOnErr "$SED -i '/^ *discovery.zen.ping.multicast.enabled:/d' $ELSCNFPTH/$ELSCNF failed"
    fi

    if ! "$SED" -i '/^ *discovery.zen.ping.multicast.group:/d' "$ELSCNFPTH/$ELSCNF"
    then
        exitOnErr "$SED -i '/^ *discovery.zen.ping.multicast.group:/d' $ELSCNFPTH/$ELSCNF failed"
    fi

    local envr=$("$SED" -n 's/^ *ENV *= *//p' "/tmp/$RECNFGCNF" | "$SED" 's/ \{1,\}$//p')
    if [ ! -z "$envr" ]
    then

        #TODO: Substitute with hash and loop based logic here.
        if "$ECHO" "$envr" | "$GREP" -i dev01 > /dev/null 2>&1
        then
            "$ECHO" 'discovery.zen.ping.multicast.group: 239.75.1.4' >> "$ELSCNFPTH/$ELSCNF"
        elif "$ECHO" "$envr" | "$GREP" -i dev02 > /dev/null 2>&1
        then
            "$ECHO" 'discovery.zen.ping.multicast.group: 239.75.2.4' >> "$ELSCNFPTH/$ELSCNF"
        elif "$ECHO" "$envr" | "$GREP" -i dev03 > /dev/null 2>&1
        then
            "$ECHO" 'discovery.zen.ping.multicast.group: 239.75.3.4' >> "$ELSCNFPTH/$ELSCNF"
        elif "$ECHO" "$envr" | "$GREP" -i dev04 > /dev/null 2>&1
        then
            "$ECHO" 'discovery.zen.ping.multicast.group: 239.75.4.4' >> "$ELSCNFPTH/$ELSCNF"
        elif "$ECHO" "$envr" | "$GREP" -i dev05 > /dev/null 2>&1
        then
            "$ECHO" 'discovery.zen.ping.multicast.group: 239.75.5.4' >> "$ELSCNFPTH/$ELSCNF"
        elif "$ECHO" "$envr" | "$GREP" -i dev06 > /dev/null 2>&1
        then
            "$ECHO" 'discovery.zen.ping.multicast.group: 239.75.6.4' >> "$ELSCNFPTH/$ELSCNF"
        elif "$ECHO" "$envr" | "$GREP" -i dev07 > /dev/null 2>&1
        then
            "$ECHO" 'discovery.zen.ping.multicast.group: 239.75.7.4' >> "$ELSCNFPTH/$ELSCNF"
        elif "$ECHO" "$envr" | "$GREP" -i dev08 > /dev/null 2>&1
        then
            "$ECHO" 'discovery.zen.ping.multicast.group: 239.75.8.4' >> "$ELSCNFPTH/$ELSCNF"
        elif "$ECHO" "$envr" | "$GREP" -i dev09 > /dev/null 2>&1
        then
            "$ECHO" 'discovery.zen.ping.multicast.group: 239.75.9.4' >> "$ELSCNFPTH/$ELSCNF"
        elif "$ECHO" "$envr" | "$GREP" -i dev10 > /dev/null 2>&1
        then
            "$ECHO" 'discovery.zen.ping.multicast.group: 239.75.10.4' >> "$ELSCNFPTH/$ELSCNF"
        elif "$ECHO" "$envr" | "$GREP" -i qaf01 > /dev/null 2>&1
        then
            "$ECHO" 'discovery.zen.ping.multicast.group: 239.75.12.4' >> "$ELSCNFPTH/$ELSCNF"
        elif "$ECHO" "$envr" | "$GREP" -i qaf02 > /dev/null 2>&1
        then
            "$ECHO" 'discovery.zen.ping.multicast.group: 239.75.13.4' >> "$ELSCNFPTH/$ELSCNF"
        elif "$ECHO" "$envr" | "$GREP" -i qaf03 /dev/null 2>&1
        then
            "$ECHO" 'discovery.zen.ping.multicast.group: 239.75.14.4' >> "$ELSCNFPTH/$ELSCNF"
        fi

    fi

}

recnfgrUnicst() {

    if ! "$SED" -i '/^ *discovery.zen.ping.unicast.hosts:/d' "$ELSCNFPTH/$ELSCNF"
    then
        exitOnErr "$SED -i '/^ *discovery.zen.ping.unicast.hosts:/d' $ELSCNFPTH/$ELSCNF failed"
    fi

    if "$SED" -i '/^ *discovery.zen.ping.multicast.enabled:/d' "$ELSCNFPTH/$ELSCNF"
    then
        "$ECHO" "discovery.zen.ping.multicast.enabled: false" >> "$ELSCNFPTH/$ELSCNF"
    else
        exitOnErr "$SED -i '/^ *discovery.zen.ping.multicast.enabled:/d' $ELSCNFPTH/$ELSCNF failed"
    fi

    local nds=$("$SED" -n 's/^ *CLSTRNODES *= *//p' "/tmp/$RECNFGCNF")
    if [ ! -z "$nds" ]
    then
        local s=''
        for n in $nds
        do
            s+="\"$n\","            
        done

        s=$("$ECHO" "$s" | "$SED" "s/,$//")
        "$ECHO" "discovery.zen.ping.unicast.hosts: [$s]" >> "$ELSCNFPTH/$ELSCNF"
    fi

    "$SLEEP" "$SLPFLSYS"

}

recnfgELS() {

    if [ ! -d "$ELSPTH/bin" ]
    then
        exitOnErr "Elasticsearch runtime tree missing"
    fi

    if [ ! -f "/tmp/$RECNFGCNF" ]
    then
        exitOnErr "Required /tmp/$RECNFGCNF not found"
    fi

    local envr=$("$SED" -n 's/^ *ENV *= *//p' "/tmp/$RECNFGCNF" | "$SED" 's/ \{1,\}$//p')
    if [ ! -z "$envr" ]
    then
        if ! "$SED" -i "/^ *cluster.name/ s/ELSSWDEV/${envr}_SearchLayer/" "$ELSCNFPTH/$ELSCNF"
        then
            exitOnErr "Setting cluster.name to ${envr}_SearchLayer in $ELSCNFPTH/$ELSCNF failed"
        fi
    fi

    local ndrl=$("$SED" -n 's/^ *NODEROLE *= *//p' "/tmp/$RECNFGCNF" | "$SED" 's/ \{1,\}$//p')
    if [ "$ndrl" = "master" ]
    then
        recnfgrMstr
    elif [ "$ndrl" = "data" ]
    then
        recnfgrData
    elif [ "$ndrl" = "client" ]
    then
        recnfgrClnt
    fi

    local zen=$("$SED" -n 's/^ *DISCOVERY *= *//p' "/tmp/$RECNFGCNF" | "$SED" 's/ \{1,\}$//p')
    if [ "$zen" = "multicast" ]
    then
        recnfgrMltcst
    elif [ "$zen" = "unicast" ]
    then
        recnfgrUnicst
    fi

}

main() {

    preChecks

    if $INSTL
    then
        instlELS
        instlELSPlgns
        dumpELS
    fi

    if $CNFGR
    then
        cnfgrELS
        dumpELS
    fi

    if $DUMP
    then
        dumpELS
    fi

    if $ALL
    then
        instlELS
        instlELSPlgns
        stopELS
        cnfgrELS
        startELS
        dumpELS
    fi

    if $START
    then
        startELS
    fi

    if $STOP
    then
        stopELS
    fi

    if $CLEAN
    then
        stopELS
        cleanELS
        dumpELS
    fi

    if $RECNFG
    then
        stopELS
        recnfgELS
        startELS
        dumpELS
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

