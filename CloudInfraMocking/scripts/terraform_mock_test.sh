#! /bin/sh

OPRN=${1}
OPTN=${2}
NUMOPTNMX=3
TRFRMCNFL=${TRFRMCNFL:-'/etc/terraform'}
TRFRMWLOC=${TRFRMWLOC:-'/tmp/terraform'}

printUsage() {

  cat <<EOF
 Usage: $(basename "${0}") <motoserver|localstack> <awssg|awsasg|awsalb>
EOF

  exit 0

}

parseArgs() {

  if [[ $# -gt ${NUMOPTNMX} ]]
  then
    printUsage
  fi

  if [[ "${OPRN}" != "motoserver" ]] && \
     [[ "${OPRN}" != "localstack" ]]
  then
    printUsage
  fi

  if [[ "${OPTN}" != "awssg" ]] && \
     [[ "${OPTN}" != "awsasg" ]] && \
     [[ "${OPTN}" != "awsalb" ]]
  then
    printUsage
  fi

}

preProcess() {

  if [[ -d "${TRFRMCNFL}" ]]
  then
    if cp -rf "${TRFRMCNFL}" /tmp
    then
      cd "${TRFRMWLOC}/${OPTN}" && \
      cp "../aws.tf.${OPRN}" aws.tf && \
      terraform init
    fi	    
  fi

}

runPlan() {

  terraform plan

}

main() {

  parseArgs

  preProcess

  runPlan

}

main 2>&1
