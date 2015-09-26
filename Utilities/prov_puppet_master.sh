#! /usr/bin/env bash
############################################################################
# File name : prov_puppet_master.sh
# Purpose   : Provision Puppet Master on an AWS instance.
# Usages    : ./create_puppet_master.sh <-p|--provision|-d|--dump|-a|--all>
#             (make it executable using chmod +x)
# Start date : 11/24/2014
# End date   : 11/xx/2014
# Author : Ankur Kumar <ankur.kumar@richnusgeeks>
# Download link : www.richnusgeeks.me
# License :
# Version : 0.0.1
# Modification history :
# Notes :
############################################################################
# <start of include section>

# <end of include section>


# <start of global section>
RM=rm
PS=$(which ps)
CAT=$(which cat)
SED=$(which sed)
AWK=$(which awk)
GIT=git
YUM=$(which yum)
RPM=$(which rpm)
TEE=$(which tee)
DIFF=$(which diff)
DATE=$(which date)
ECHO=$(which echo)
CURL=$(which curl)
GREP=$(which grep)
NTST=$(which netstat)
BSNME=$(which basename)
PIDOF=$(which pidof)
SLEEP=$(which sleep)
PUPPET=puppet
REBOOT=reboot
CHKCNFG=$(which chkconfig)
SWTCH="$1"
NUMARG=$#
PRGNME=$("$ECHO" $("$BSNME" "$0") | "$SED" -n 's/\.sh//p')
PROV=false
DUMP=false
RMVE=false
ALL=false
SLPCERT=60
GITREPO='github.com/richnusgeeks/puppet.git'
GITBRNCH='puppet-4ansible-test-ankur'
GITUSR='<Put User Here>'
GITPSWRD='<Put Pswrd Here>'
# <end of global section>


# <start of helper section>
exitOnErr() {

  local date=$($DATE)
  "$ECHO" " Error: <$date> $1, exiting ..."
  exit 1

}

prntUsage() {

  "$ECHO" "Usages: $PRGNME <-p|--provision|-r|--remove"
  "$ECHO" "                   |-d|--dump|-a|--all>"
  "$ECHO" "        -p|--provision Setup Puppet Master out of the box,"
  "$ECHO" "        -d|--dump      Dump Puppet Master info,"
  "$ECHO" "        -r|--remove    Remove Puppet Master,"
  "$ECHO" "        -a|--all       Provision+Dump Puppet Master,"
  exit 0

}

parseArgs() {

  if [ $NUMARG -ne 1 ]
  then
    prntUsage
  fi

  if [ "$SWTCH" = "-p" ] ||  [ "$SWTCH" = "--provision" ]
  then
    PROV=true
  elif [ "$SWTCH" = "-d" ] || [ "$SWTCH" = "--dump" ]
  then
    DUMP=true
  elif [ "$SWTCH" = "-r" ] || [ "$SWTCH" = "--remove" ]
  then
    RMVE=true
  elif [ "$SWTCH" = "-a" ] || [ "$SWTCH" = "--all" ]
  then
    ALL=true
  else
    prntUsage
  fi

}

preChecks() {

  parseArgs

  if [ "$EUID" -ne 0 ]
  then
    exitOnErr "This script requires sudo run"
  fi

  if ! "$CURL" www.github.com > /dev/null 2>&1
  then
    exitOnErr "Check your internet/dns settings"
  fi

}

provisionPptMstr() {

  if ! "$YUM" update -y
  then
    exitOnErr "$YUM update failed"
  fi

  if ! "$YUM" install -y puppet-server git
  then
    exitOnErr "$YUM install -y puppet-server git failed"
  fi

  if ! "$CHKCNFG" puppetmaster on
  then
    exitOnErr "$CHKCNFG puppet-server on failed"
  fi

  if [ -d /etc/puppet ]
  then
    if ! "$RM" -rfv /etc/puppet
    then
      exitOnErr "Removal of existing puppet content failed"
    fi
  fi

  if ! "$GIT" clone -b "$GITBRNCH" "https://$GITUSR:$GITPSWRD@$GITREPO" /etc/puppet
  then
    exitOnErr "$GIT clone of richnusgeeks puppet repo failed"
  fi
 
  local publicdns=$("$CURL" http://169.254.169.254/latest/meta-data/public-hostname)
  if [ ! -z "$publicdns" ]
  then
    if ! "$SED" -i.old "/^ *certname/s/= *[-.a-zA-Z0-9]\{1,\}/= $publicdns/" /etc/puppet/puppet.conf
    then
      exitOnErr "Patching of certname in puppet.conf failed"
    fi 
  fi

  if ! "$PUPPET" master --verbose &
  then
    exitOnErr "Puppet certificate generation failed"
  fi

  "$SLEEP" "$SLPCERT"

}

removePptMstr() {

  true 

}

dumpPptMstr() {

  "$RPM" -qa '*puppet*' git
  "$PUPPET" --version
  "$GIT" --version
 
  "$CHKCNFG" --list puppetmaster
  "$PS" aux | "$GREP" -i ruby | "$GREP" -Ev '(bash|grep)'
  "$NTST" -nlptu | "$GREP" -i ruby | "$GREP" -Ev '(bash|grep)'

  "$DIFF" /etc/puppet/puppet.conf{,.old}
  "$CAT" /var/log/puppet/masterhttp.log
  cd /etc/puppet && "$GIT" branch 

}

main() {

    preChecks

    if $PROV
    then
      provisionPptMstr
      dumpPptMstr
    fi

    if $DUMP
    then
      dumpPptMstr
    fi

    if $ALL
    then
      provisionPptMstr
      dumpPptMstr
      if ! "$REBOOT"
      then
        exitOnErr "Instance reboot failed"
      fi
    fi

    if $RMVE
    then
      removePptMstr  
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

