#! /bin/sh

TAMD=${1}
EXDR=${2}
OPRN=${3}
NUMOPTNMX=4
TRFRMCNFL=${TRFRMCNFL:-'/etc/opentofu/aws_override.tf'}

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
          fi
        fi	    
      fi

    fi
  fi

  sed -i '/^ *provider/,/\}/d' main.tf
  tofu init -input=false

}

runOprtn() {

  cd "/tmp/terraform-aws-${TAMD}/examples/${EXDR}/"

  if [[ "${OPRN}" = "apply" ]] || \
     [[ "${OPRN}" = "destroy" ]]
  then
    tofu ${OPRN} -input=false -auto-approve
  else
    tofu "${OPRN}" 
  fi

}

main() {

  parseArgs

  preProcess

  runOprtn

}

main 2>&1
