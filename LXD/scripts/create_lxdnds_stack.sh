#! /bin/bash
#set -u
set -o pipefail

CAT=$(which cat)
AWK=$(which awk)
SED=$(which sed)
LXC=$(which lxc)
TEE=$(which tee)
ECHO=$(which echo)
GREP=$(which grep)
XARG=$(which xargs)
OPTN="${1}"
BSNME=$(which basename)
SLEEP=$(which sleep)
ANSBL=$(which ansible)
SSHPASS=$(which sshpass)
SSHCPID=$(which ssh-copy-id)
NUMOPTN=${#}
SLPDRTN=10
NUMOPTNE=1
ANSBLRPO='ansible.repo'
LXDIMAGS="ubuntu:18.04/amd64
          images:centos/7/amd64
          images:centos/6/amd64"
PCKGSTOI="monit"
PRGNME=$("${BSNME}" "${0}")
LOGNME=$("${ECHO}" "${PRGNME}" | "${SED}" 's/\.sh/\.log/')

printUsage() {

  "${TEE}" <<EOF
  Usage: ${PRGNME} -b|--bringup|-c|--cleanup
                   -s|--setup|-d|--dump|-a|--all
EOF
  exit 0

}

preChecks() {

  if [[ ${NUMOPTN} -ne ${NUMOPTNE} ]]
  then
    printUsage
  fi 

}

getOsInfo() {

  "${LXC}" list| \
  "${GREP}" -Ev '^\+'| \
  "${GREP}" -iv name| \
  "${AWK}" '{print $2}'| \
  "${XARGS}" -I % "${LXC}" exec % -- "${GREP}" '^PRETTY_NAME=' /etc/os-release|\
  "${SED}" 's/"//g'

}

setupSSHLogin() {

  local cnms=$("${LXC}" list| \
         "${GREP}" -Ev '^\+'| \
         "${GREP}" -iv name| \
         "${AWK}" '{print $2}')

  for c in ${cnms}
  do

    "${LXC}" file push ./certs/out/monit.pem "${c}"/etc/ssl/certs/monit.pem
    "${LXC}" file push ./setup_sshlgn.sh "${c}"/tmp/setup_sshlgn.sh
    "${LXC}" exec "${c}" -- /tmp/setup_sshlgn.sh

  done

}

pushSSHKey() {

  local cnms=$("${LXC}" list| \
         "${GREP}" -Ev '^\+'| \
         "${GREP}" -iv name| \
         "${AWK}" '{print $2}')

  > "ansible/${ANSBLRPO}"

  for c in ${cnms}
  do

    local cip=$("${LXC}" list -c4 "${c}"| \
         "${GREP}" -Ev '^\+'| \
         "${GREP}" -iv ipv4| \
         "${AWK}" '{print $2}')

    if [[ ! -z "${cip}" ]]
    then

      if "${ECHO}" "${c}"|"${GREP}" centos > /dev/null 2>&1
      then
        local PSWD=centos
      elif "${ECHO}" "${c}"|"${GREP}" ubuntu > /dev/null 2>&1
      then
        local PSWD=ubuntu
      fi

      "${SSHPASS}" -p "${PSWD}" "${SSHCPID}" -oStrictHostKeyChecking=no \
      "${PSWD}"@"${cip}"

      if [[ "${PSWD}" = "centos" ]]
      then
        "${ECHO}" "${PSWD}@${cip}" >> "ansible/${ANSBLRPO}"
      elif [[ "${PSWD}" = "ubuntu" ]]
      then
        "${ECHO}" "${PSWD}@${cip} ansible_python_interpreter=/usr/bin/python3" >> "ansible/${ANSBLRPO}"
      fi

    fi

  done

}

bringupLXDCntnrs() {

  for c in ${LXDIMAGS}
  do
    "${LXC}" launch "${c}" \
      "$(echo "${c}"|sed -e 's/\///g' -e 's/images//' -e 's/amd64//' -e 's/://' -e 's/\.//')"
  done

}

setupLXDCntnrs() {

  setupSSHLogin
  pushSSHKey

}

dumpLXDInfo() {

  "${LXC}" list
  "${ECHO}"

  pushd ansible
  "${ANSBL}" all -m ping -i "${ANSBLRPO}"
  popd
  "${ECHO}"

  "${LXC}" list| \
    "${GREP}" -Ev '^\+'| \
    "${GREP}" -iv name| \
    "${AWK}" '{print $2}'| \
    "${XARG}" -I % "${LXC}" exec % -- monit summary
  "${ECHO}"
  #"${LXC}" image list

}

teardownLXDCntnrs() {

  "${LXC}" list| \
    "${GREP}" -Ev '^\+'| \
    "${GREP}" -iv name| \
    "${AWK}" '{print $2}'| \
    "${XARG}" -I % "${LXC}" delete -f %

  > "ansible/${ANSBLRPO}"

}

main() {

  preChecks
  
  if [[ "${OPTN}" = "-b" ]] || [[ "${OPTN}" = "--bringup" ]]
  then
    bringupLXDCntnrs
  elif [[ "${OPTN}" = "-s" ]] || [[ "${OPTN}" = "--setup" ]]
  then
    setupLXDCntnrs
  elif [[ "${OPTN}" = "-c" ]] || [[ "${OPTN}" = "--cleanup" ]]
  then
    teardownLXDCntnrs
  elif [[ "${OPTN}" = "-d" ]] || [[ "${OPTN}" = "--dump" ]]
  then
    dumpLXDInfo
  elif [[ "${OPTN}" = "-a" ]] || [[ "${OPTN}" = "--all" ]]
  then
    bringupLXDCntnrs
    "${SLEEP}" "${SLPDRTN}"
    setupLXDCntnrs
    dumpLXDInfo
  else
    printUsage
  fi

}

main 2>&1|"${TEE}" "${LOGNME}"
