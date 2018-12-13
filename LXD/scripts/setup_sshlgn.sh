#! /bin/bash
#set -u
set -o pipefail

# FIXME: surprisingly the centos/7/amd64 Linux Container image doesn't have
#        a very basic which command.
OSVRSNFL='/etc/os-release'
CMNPCKGS="monit"
if grep -i '^ *PRETTY_NAME="centos' "${OSVRSNFL}" > /dev/null 2>&1
then
  yum update
  rpm -ivh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
  yum install -y which ${CMNPCKGS}
fi

CAT=$(which cat)
TEE=$(which tee)
SED=$(which sed)
GREP=$(which grep)
SRVC=$(which service)
ECHO=$(which echo)
DATE=$(which date)
CHMOD=$(which chmod)
CHPSWD=$(which chpasswd)
ADDUSR=$(which adduser)
SYSCTL=$(which systemctl)
USRMOD='/usr/sbin/usermod'
CTOSPKGS="openssh-server
          sudo"
SSHDCNFL='/etc/ssh/sshd_config'
SUDORSFL='/etc/sudoers'

exitOnErr() {

    local date=$("${DATE}")
    "${ECHO}" " Error: <$date> $1, exiting ..."
    exit 1

}

if "${GREP}" -i '^ *PRETTY_NAME="centos' "${OSVRSNFL}" > /dev/null 2>&1
then
  YUM=$(which yum)

  if ! "${YUM}" install -y ${CTOSPKGS}
  then
    exitOnErr "${YUM} install -y ${CTOSPCKGS}"
  fi
 
  if ! "${SRVC}" sshd start
  then
    exitOnErr "${SRVC} sshd start"
  fi

  if ! "${GREP}" centos /etc/passwd > /dev/null 2>&1
  then
    if ! "${ADDUSR}" centos
    then
      exitOnErr "${ADDUSR} centos"
    fi
  fi

  if ! "${ECHO}"  'centos:centos'|"${CHPSWD}"
  then
    exitOnErr "${ECHO} -n 'centos:centos'|${CHPSWD}"
  fi

  if ! "${USRMOD}" -aG wheel centos
  then
    exitOnErr "${USERMOD} -aG wheel centos"
  fi

  if ! "${SED}" -i '/NOPASSWD: ALL/s/^#//' "${SUDORSFL}"
  then
    exitOnErr "${SED} -i '/NOPASSWD: ALL/s/^#//' ${SUDORSFL}"
  fi

  "${CAT}" <<EOF|"${TEE}" /etc/monitrc
set daemon  30
set log syslog

set httpd port 2812 and
  use address 0.0.0.0
  allow localhost
  allow 0.0.0.0/0
  allow admin:monit
  allow guest:guest readonly

include /etc/monit.d/*
EOF

  "${CHMOD}" 0600 /etc/monitrc

elif "${GREP}" -i '^ *PRETTY_NAME="ubuntu' "${OSVRSNFL}" > /dev/null 2>&1 
then
  APT=$(which apt-get)
  "${APT}" update
  "${APT}" install -y ${CMNPCKGS}

  if ! "${ECHO}" -n 'ubuntu:ubuntu'|"${CHPSWD}"
  then
    exitOnErr "${ECHO} 'ubuntu:ubuntu'|${CHPSWD}"
  fi

  if ! "${SED}" -i '/^%sudo/s/ALL$/NOPASSWD: ALL/' "${SUDORSFL}"
  then
    exitOnErr "${SED} -i '/^%sudo/s/ALL$/NOPASSWD: ALL/ ${SUDORSFL}"
  fi

  if ! "${SED}" -i '/^PasswordAuthentication/s/no/yes/' "${SSHDCNFL}"
  then
    exitOnErr "${SED} -i '/^PasswordAuthentication/s/no/yes/' ${SSHDCNFL}"
  fi

  if ! "${SRVC}" sshd restart
  then
    exitOnErr "${SRVC} sshd restart"
  fi

  "${CAT}" <<EOF|"${TEE}" /etc/monit/monitrc
  set daemon 30
  set log /var/log/monit.log

  set idfile /var/lib/monit/id
  set statefile /var/lib/monit/state

  set eventqueue
    basedir /var/lib/monit/events
    slots 100

  set httpd port 2812 and
    use address 0.0.0.0
    allow localhost
    allow 0.0.0.0/0
    allow admin:monit
    allow guest:guest readonly

  include /etc/monit/conf.d/*
  include /etc/monit/conf-enabled/*
EOF

  "${CHMOD}" 0600 /etc/monit/monitrc

fi

"${SYSCTL}" enable monit
"${SYSCTL}" start monit
monit reload
