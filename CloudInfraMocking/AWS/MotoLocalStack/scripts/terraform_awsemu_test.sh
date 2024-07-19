#! /bin/sh

TAMD=${1}
EXDR=${2}
OPRN=${3}
NUMOPTNMX=4
TRFRMCNFL=${TRFRMCNFL:-'/etc/terraform/aws_override.tf'}
TRFRMWLOC=${TRFRMWLOC:-'/tmp/terraform'}

printUsage() {

  cat <<EOF
 Usage: $(basename "${0}") <terraform aws module> <example dir> <plan|apply|destroy>
EOF

  exit 0

}

parseArgs() {

  if [[ $# -gt ${NUMOPTNMX} ]]
  then
    printUsage
  fi

  if [[ "${OPRN}" != "plan" ]] && \
     [[ "${OPRN}" != "apply" ]] && \
     [[ "${OPRN}" != "destroy" ]]
  then
    printUsage
  fi

}

preProcess() {

  if [[ -d "/tmp/terraform-aws-${TAMD}" ]]
  then
    cd "/tmp/terraform-aws-${TAMD}"
    git pull
    cd "examples/${EXDR}/"
    terraform init -input=false

  else
    if git clone "https://github.com/terraform-aws-modules/terraform-aws-${TAMD}.git" "/tmp/terraform-aws-${TAMD}"
    then

      if [[ -e "${TRFRMCNFL}" ]]
      then
        if [[ -d "/tmp/terraform-aws-${TAMD}/examples/${EXDR}/" ]]
        then
          if cp -f "${TRFRMCNFL}" "/tmp/terraform-aws-${TAMD}/examples/${EXDR}/"
          then
            cd "/tmp/terraform-aws-${TAMD}/examples/${EXDR}/"
            terraform init -input=false
          fi
        fi	    
      fi

    fi
  fi


}

runOprtn() {

  cd "/tmp/terraform-aws-${TAMD}/examples/${EXDR}/"

  if [[ "${OPRN}" = "apply" ]] || \
     [[ "${OPRN}" = "destroy" ]]
  then
    terraform ${OPRN} -input=false -auto-approve
  else
    terraform "${OPRN}" 
  fi

}

main() {

  parseArgs

  preProcess

  runOprtn

}

main 2>&1
