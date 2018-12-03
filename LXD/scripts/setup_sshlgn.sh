#! /bin/bash
#set -u
set -o pipefail

# FIXME: surprisingly the centos/7/amd64 Linux Container image doesn't have
#        a very basic which command.
OSVRSNFL='/etc/os-release'
if grep -i '^ *PRETTY_NAME="centos' "${OSVRSNFL}" > /dev/null 2>&1
then
  yum update
  yum install -y which
fi

YUM=$(which yum)
SED=$(which sed)
GREP=$(which grep)
SRVC=$(which service)
ECHO=$(which echo)
DATE=$(which date)
CHPSWD=$(which chpasswd)
ADDUSR=$(which adduser)
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
  if ! "${YUM}" update
  then
    exitOnErr "${YUM} update"
  fi

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

  if ! "${SED}" -i '/NOPASSWD: ALL/s/^#//' "${SUDORSFL}"
  then
    exitOnErr "${SED} -i '/NOPASSWD: ALL/s/^#//' ${SUDORSFL}"
  fi

elif "${GREP}" -i '^ *PRETTY_NAME="ubuntu' "${OSVRSNFL}" > /dev/null 2>&1 
then

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

fi
