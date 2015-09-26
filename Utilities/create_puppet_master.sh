#! /usr/bin/env bash
############################################################################
# File name : create_puppet_master.sh
# Purpose   : Bringup AWS EC2 instance and provision Puppet Master on it
# Usages    : ./create_puppet_master.sh <-b|--bringup|-p|--provision
#                                          |-d|--dump|-r|--remove|-a|--all>
#             (make it executable using chmod +x)
# Start date : 11/20/2014
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
JQ=$(which jq)
SSH=$(which ssh)
SCP=$(which scp)
AWS=$(which aws)
CAT=$(which cat)
SED=$(which sed)
AWK=$(which awk)
TEE=$(which tee)
DATE=$(which date)
ECHO=$(which echo)
WGET=$(which wget)
GREP=$(which grep)
NTST=$(which netstat)
CURL=$(which curl)
BSNME=$(which basename)
PIDOF=$(which pidof)
SLEEP=$(which sleep)
SWTCH="$1"
NUMARG=$#
PRGNME=$("$ECHO" $("$BSNME" "$0") | "$SED" -n 's/\.sh//p')
BRNG=false
PROV=false
DUMP=false
RMVE=false
ALL=false
SLPAWS=60
SLPSSH=5
RM='/bin/rm'
GIT='/usr/bin/git'
CHKCNFG='/sbin/chkconfig'
GITREPO='github.com/richnusgeeks/puppet.git'
GITBRNCH='puppet-4ansible-test-ankur'
GITUSR='<PUT YOUR USER>'
GITPSWRD='<PUT YOUR PASSWORD>'
PKEY='ankurkumar-west2'
KEYL="$HOME/.ssh/${PKEY}.cer"
TGNM='Puppet Master Test'
RGNE='us-west-2'
TYPE='m3.medium'
SGRP='puppetmaster-test'
AMID='ami-69dc9459'
LUSR='ec2-user'
# <end of global section>


# <start of helper section>
exitOnErr() {

  local date=$($DATE)
  "$ECHO" " Error: <$date> $1, exiting ..."
  exit 1

}

prntUsage() {

  "$ECHO" "Usages: $PRGNME <-b|--bringup|-p|--provision"
  "$ECHO" "                   |-d|--dump|-r|--remove|-a|--all>"
  "$ECHO" "        -b|--bringup   Create AWS EC2 instance for Puppet Master,"
  "$ECHO" "        -p|--provision Setup Puppet Master out of the box,"
  "$ECHO" "        -d|--dump      Dump various info from Puppet Master,"
  "$ECHO" "        -r|--remove    Remove Puppet Master AWS EC2 instance,"
  "$ECHO" "        -a|--all       Bringup+Provision+Dump Puppet Master,"
  exit 0

}

parseArgs() {

  if [ $NUMARG -ne 1 ]
  then
    prntUsage
  fi

  if [ "$SWTCH" = "-b" ] || [ "$SWTCH" = "--bringup" ]
  then
    BRNG=true
  elif [ "$SWTCH" = "-p" ] ||  [ "$SWTCH" = "--provision" ]
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

  if $BRNG || $ALL
  then
    if [ -z "$JQ" ]
    then
      exitOnErr "Check if jq installed and in path"   
    fi

    if [ -z "$AWS" ]
    then
      exitOnErr "Check if aws-cli installed and in path"   
    fi
  fi 

  if ! "$CURL" www.github.com > /dev/null 2>&1
  then
    exitOnErr "Check your internet/dns settings"
  fi

  if ! "$AWS" ec2 describe-images --region="$RGNE" --image-ids="$AMID" > /dev/null 2>&1
  then
    exitOnErr "Check if image $AMID exist in $RGNE"
  fi

  if ! "$AWS" ec2 describe-security-groups --region="$RGNE" --group-names="$SGRP" > /dev/null 2>&1
  then
    exitOnErr "Check if security group $SGRP exist in $RGNE"
  fi

  if ! "$AWS" ec2 describe-key-pairs --region="$RGNE" --key-names="$PKEY" > /dev/null 2>&1
  then
    exitOnErr "Check if keypair $PKEY exist in $RGNE"
  fi

}

bringupPptMstr() {

                    #--user-data "`cat <path/to>/puppetmaster.yml`" \
  local instance=$("$AWS" ec2 run-instances \
                    --region "$RGNE" \
                    --image-id "$AMID" \
                    --key-name "$PKEY" \
                    --security-groups "$SGRP" \
                    --instance-type "$TYPE" \
                    --count 1 | \
            "$JQ" '.Instances[].InstanceId' | "$SED" 's/"//g')

  if [ -z "$instance" ]
  then
    exitOnErr "Empty instance info"
  fi

  if ! "$AWS" ec2 create-tags --region "$RGNE" \
              --resources "$instance" --tags Key=Name,Value="$TGNM"
  then
    "$ECHO" " WARN: $instance tagging failed"
  fi

  "$SLEEP" "$SLPAWS"

  publicdns=$("$AWS" ec2 describe-instances \
              --instance-id "$instance" \
              --region="$RGNE" --output=text | \
              "$GREP" -i instances | \
              "$AWK" '{print $14}')
  if [ -z "$publicdns" ]
  then
    exitOnErr "Empty public dns"
  fi
  
  while [ 1 ]
  do
    if ! "$SSH" -oStrictHostKeyChecking=no -tt -l "$LUSR" \
                -i "$KEYL" "$publicdns" uname > /dev/null 2>&1
    then
      "$SLEEP" "$SLPSSH"
    else
      break
    fi
  done

}

provisionPptMstr() {

  if ! "$SCP" -oStrictHostKeyChecking=no \
              -i "$KEYL" "prov_puppet_master.sh" "$LUSR@$publicdns:/tmp"
  then
    exitOnErr "Remote copy of provision_puppet_master.sh failed"
  fi

  if ! "$SSH" -oStrictHostKeyChecking=no -tt -l "$LUSR" \
              -i "$KEYL" "$publicdns" \
              "cd /tmp && sudo -H bash prov_puppet_master.sh -a"
  then
    exitOnErr "Remote execution of puppet provision script failed"
  fi

}

removePptMstr() {

  true 

}

dumpPptMstr() {

  while [ 1 ]
  do
    if ! "$SSH" -oStrictHostKeyChecking=no -tt -l "$LUSR" \
                -i "$KEYL" "$publicdns" uname > /dev/null 2>&1
    then
      "$SLEEP" "$SLPSSH"
    else
      break
    fi
  done

  "$SCP" -oStrictHostKeyChecking=no \
         -i "$KEYL" "$LUSR@$publicdns:/tmp/prov_puppet_master.log" .

  "$SSH" -oStrictHostKeyChecking=no -tt -l "$LUSR" \
         -i "$KEYL" "$publicdns" \
         "cd /tmp && sudo -H rm -rfv prov_puppet_master.*"

}

main() {

    preChecks

    if $BRNG
    then
      bringupPptMstr
      dumpPptMstr
    fi

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
      bringupPptMstr
      provisionPptMstr
      dumpPptMstr
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

