#! /bin/bash
set -o pipefail

OPTN=${1}
OPTNTST=${2}
NUMOPTNMX=3
DLYTOMSTL=3
CLDCNFGDR='.'
NUMCPUALC=1
MEMAMOUNT='2G'
DSKAMOUNT='10G'
PUBKEYLOC="${HOME}/.ssh/id_rsa.pub"
RQRDCMNDS="awk
           basename
           cat
           date
           grep
           multipass
           sed
           ssh
           ssh-keygen
           wc"

preReq() {

  for c in ${RQRDCMNDS}
  do
    if ! command -v "${c}" > /dev/null 2>&1
    then
      echo " Error: required command ${c} not found, exiting ..."
      exit -1
    fi
  done

}

exitOnErr() {

  echo " Error: <$(date)> $1, exiting ..."
  exit 1

}

printUsage() {

  cat <<EOF
 Usage: $(basename "${0}")
   < ping - test ssh connectivity to created local cloudvms |
     start - start all local cloudvms |
     stop - stop all local cloudvms |
     show - dumps info about all local cloudvms |
     create - bringup fully configured localvm for,
              [cassandra|consuldev|opensearch|
               kafka|kafka-kraft|nomadev|spark|vaultdev] |
     delete - deletes all local cloudvms |
     cleandelete - cleanup everything for all local cloudvms >
EOF
  exit 0

}

parseArgs() {

  if [[ $# -gt ${NUMOPTNMX} ]]
  then
    printUsage
  fi

  if [[ "${OPTN}" != "create" ]] && \
     [[ "${OPTN}" != "ssh" ]] && \
     [[ "${OPTN}" != "cleandelete" ]] && \
     [[ "${OPTN}" != "delete" ]] && \
     [[ "${OPTN}" != "ping" ]] && \
     [[ "${OPTN}" != "start" ]] && \
     [[ "${OPTN}" != "stop" ]] && \
     [[ "${OPTN}" != "show" ]]
  then
    printUsage
  fi

  if [[ "${OPTN}" = "create" ]] || [[ "${OPTN}" = "ssh" ]]
  then
    if [[ "${OPTNTST}" != "cassandra" ]]  && \
       [[ "${OPTNTST}" != "consuldev" ]]  && \
       [[ "${OPTNTST}" != "opensearch" ]] && \
       [[ "${OPTNTST}" != "kafka" ]]      && \
       [[ "${OPTNTST}" != "kafka-kraft" ]]  && \
       [[ "${OPTNTST}" != "nomadev" ]]    && \
       [[ "${OPTNTST}" != "spark" ]]      && \
       [[ "${OPTNTST}" != "vaultdev" ]]
    then
      printUsage
    fi
  fi

}

showMLPStack() {

  if ! multipass ls
  then
    exitOnErr "multipass ls failed"
  fi

}

startMLPStack() {

  if ! multipass start --all
  then
    exitOnErr "multipass start --all failed"
  fi

}

stopMLPStack() {

  if ! multipass stop --all
  then
    exitOnErr "multipass stop --all failed"
  fi

}

deleteMLPStack() {

  if ! multipass delete --all
  then
    exitOnErr "multipass delete --all failed"
  fi

}

clndlteMLPStack() {

  local numhsts=$(multipass ls | grep -v Name | awk '{if($1 !~ /[0-9]\./) print $1}'|wc -l)

  if [[ ${numhsts} -gt 1 ]]
  then
    multipass ls | grep -v Name | awk '{if($1 !~ /[0-9]\./) print $3}' | \
                   xargs -I % ssh-keygen -R %
  else
    multipass ls | grep -v Name | awk '{if($1 !~ /[0-9]\./) print $1}' | \
                   xargs -I % ssh-keygen -R %.local
  fi

  if ! multipass delete --all -p
  then
    exitOnErr "multipass delete --all -p failed"
  fi

}

setupStack() {

  if [[ ! -f "${CLDCNFGDR}/cloud-config-${1}.yaml" ]]
  then
    exitOnErr "required ${CLDCNFGDR}/cloud-config-${1}.yaml not found"
  fi

  local pubkey="$(cat ${PUBKEYLOC})"
  if ! sed -i.orig "s|PUBLICKEY|${pubkey}|" "${CLDCNFGDR}/cloud-config-${1}.yaml"
  then
    exitOnErr "sed -i.orig \"s|PUBLICKEY|\${pubkey}|\" ${CLDCNFGDR}/cloud-config-${1}.yaml failed"
  fi

  if [[ "${1}" = "cassandra" ]] || \
     [[ "${1}" = "opensearch" ]] || \
     [[ "${1}" = "kafka" ]] || \
     [[ "${1}" = "kafka-kraft" ]] || \
     [[ "${1}" = "spark" ]]
  then
    NUMCPUALC=2
  fi

  if ! cat "cloud-config-${1}.yaml"|multipass launch -c "${NUMCPUALC}" \
	                                             -m "${MEMAMOUNT}" \
                                                     -d "${DSKAMOUNT}" \
                                                     -n "${1}" --cloud-init -
  then
    mv -f cloud-config-${1}.yaml{.orig,}
    exitOnErr "multipass launch -c ${NUMCPUALC} -m ${MEMAMOUNT} -n "${1}" --cloud-init cloud-config-${1}.yaml failed"
  fi

  mv -f cloud-config-${1}.yaml{.orig,}

}

pingStack() {

  local numhsts=$(multipass ls | grep -v Name | awk '{if($1 !~ /[0-9]\./) print $1}'|wc -l)

  if [[ ${numhsts} -gt 1 ]]
  then
    multipass ls | grep -v Name | awk '{if($1 !~ /[0-9]\./) print $3}' | \
      xargs -I % \
      sh -c 'echo HOST: %;ssh -oStrictHostKeyChecking=no ubuntu@% \
           sudo ss -ltnp;echo'
  else
    multipass ls | grep -v Name | awk '{if($1 !~ /[0-9]\./) print $1}' | \
      xargs -I % \
      sh -c 'echo HOST: %.local;ssh -oStrictHostKeyChecking=no ubuntu@%.local \
           sudo ss -ltnp;echo'
  fi

}

# FIXME: entering into microvm seems always waiting for stdin,
#        some tty n decriptors mess as a logical guess.
sshMicroVM() {

  local numhsts=$(multipass ls | grep -v Name | awk '{if($1 !~ /[0-9]\./) print $1}'|wc -l)

  if [[ ${numhsts} -gt 1 ]]
  then
    multipass ls | grep -v Name | grep "${1}" | \
      awk '{if($1 !~ /[0-9]\./) print $3}' | \
      xargs -I % sh -c 'ssh -tt -oStrictHostKeyChecking=no ubuntu@%'
  else
    multipass ls | grep -v Name | grep "${1}" | \
      awk '{if($1 !~ /[0-9]\./) print $1}' | \
      xargs -I % \
      sh -c 'ssh -tt -oStrictHostKeyChecking=no ubuntu@%.local'
  fi

}

createAndShow() {

  setupStack "${1}"
  echo
  sleep "${DLYTOMSTL}"
  showMLPStack
  echo

}

main() {

  parseArgs

  preReq

  if [[ "${OPTN}" = "create" ]]
  then
    createAndShow "${OPTNTST}"
  elif [[ "${OPTN}" = "ssh" ]]
  then
    sshMicroVM "${OPTNTST}"
  elif [[ "${OPTN}" = "cleandelete" ]]
  then
    clndlteMLPStack
    showMLPStack
  elif [[ "${OPTN}" = "delete" ]]
  then
    deleteMLPStack
    showMLPStack
  elif [[ "${OPTN}" = "ping" ]]
  then
    pingStack
    showMLPStack
  elif [[ "${OPTN}" = "start" ]]
  then
    startMLPStack
    showMLPStack
  elif [[ "${OPTN}" = "stop" ]]
  then
    stopMLPStack
    showMLPStack
  elif [[ "${OPTN}" = "show" ]]
  then
    showMLPStack
  fi

}

main 2>&1
