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
NUMOPTN=${#}
NUMOPTNE=1
SSHDCNFG='/etc/ssh/shd_config'
SDRSCNFG='/etc/'
LXDIMAGS="ubuntu:18.04/amd64 \
          ubuntu:16.04/amd64 \
          images:centos/7/amd64"
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

  true

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

}

dumpLXDInfo() {

  "${LXC}" list
  "${ECHO}"
  "${LXC}" image list

}

teardownLXDCntnrs() {

  "${LXC}" list| \
    "${GREP}" -Ev '^\+'| \
    "${GREP}" -iv name| \
    "${AWK}" '{print $2}'| \
    "${XARG}" -I % "${LXC}" delete -f %

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
    setupLXDCntnrs
    dumpLXDInfo
  else
    printUsage
  fi

}

main 2>&1|"${TEE}" "${LOGNME}"
