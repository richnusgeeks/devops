#! /bin/bash
OPTN=${1}
ARGS=${2}
NUMOPTNMX=3

export VAGRANT_CWD=../tests

printUsage() {

  echo " Usage: $(basename $0) < create|status|delete|ssh <machine> >"
  exit 0

}

createStack() {

  vagrant up
  pushd ../ansible
  ansible-playbook elk.yml -i ../tests/test_vagrant \
    -e min_cpu_cores=1 \
    -e min_ram_mb=1800 \
    -e base_url=http://richnusgeeks.com/richnusgeeks/elk/ \
    -e '{"apply_xpack": true}' \
    -e '{"apply_elkconsul": true}' \
    -e hstptrn_esmstr=master \
    -e hstptrn_esdata=data

}

if [[ $# -gt ${NUMOPTNMX} ]]
then
  printUsage
fi

if [[ "${OPTN}" != "create" ]] && \
   [[ "${OPTN}" != "status" ]] && \
   [[ "${OPTN}" != "delete" ]] && \
   [[ "${OPTN}" != "ssh" ]]
then
  printUsage
else
  if [[ "${OPTN}" = "create" ]]
  then
    createStack
  elif [[ "${OPTN}" = "delete" ]]
  then
    vagrant destroy -f
  elif [[ "${OPTN}" = "status" ]]
  then
    vagrant status
  elif [[ "${OPTN}" = "ssh" ]]
  then
    if [[ -z "${ARGS}" ]]
    then
      printUsage
    else
      exec vagrant ssh "${ARGS}"
    fi
  fi
fi
