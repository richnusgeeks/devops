#! /bin/bash
set -u

TEE=$(which tee)
GREP=$(which grep)
NUMARG=$#
KEYALS="$1"
AWSRGN="$2"
AWSAKI="$3"
AWSSAK="$4"
PRGNME=$(basename "$0" | sed -n 's/\.sh//p')
AWSCLI=$(which aws)
BASE64=$(which base64)
START=$(which start)
STATUS=$(which status)
SRVCDIR='/etc/init'
LUKSKEY='/luks.key'
LUKSEKEY='/.luks'
UPSRTCNF='kmsluks'
PLRSCRPT="/opt/${UPSRTCNF}.sh"

exitOnErr() {

    local date=$(date)
    echo " Error: <$date> $1, exiting ..."
    exit 1

}

preChecks() {

  if [ ${NUMARG} -ne 4 ]
  then
    echo " Usage: ${PRGNME} <Master Key Alias> <AWS Region> <AWS Access Key> <AWS Secret Key>"
    exit 0
  fi

  if [ ! -e "${LUKSKEY}" ]
  then
    exitOnErr "required ${LUKSKEY} not found" 
  fi

  if ! "${AWSCLI}" kms list-aliases | \
       "${GREP}" AliasName | \
       "${GREP}" "${KEYALS}" > /dev/null 2>&1 

  then
    exitOnErr "list-aliases ${KEYALS} failed"
  fi

  if [ ! -f "${PLRSCRPT}" ]
  then
    exitOnErr "required ${PLRSCRPT} not found"
  fi 

}

encLUKSKey() {

  if ! "${AWSCLI}" kms encrypt --key-id "alias/${KEYALS}" --plaintext "fileb://${LUKSKEY}" --output text --query CiphertextBlob | \
       "${BASE64}" --decode | \
       "${TEE}" "${LUKSEKEY}" 1>/dev/null
  then
    exitOnErr "kms encrypt fileb://${LUKSEKEY} failed"
  else
    rm -fv "${LUKSKEY}"
  fi

}

crteSrvc() {

  if [ ! -f "${SRVCDIR}/${UPSRTCNF}.conf" ]
  then
    "${TEE}" "${SRVCDIR}/${UPSRTCNF}.conf" <<EOF
start on runlevel [35]
stop on runlevel [!35]
respawn
respawn limit 10 5

script
  export AWS_DEFAULT_REGION='${AWSRGN}'
  export AWS_ACCESS_KEY_ID='${AWSAKI}'
  export AWS_SECRET_ACCESS_KEY='${AWSSAK}'
  exec "${PLRSCRPT}" "${KEYALS}" 2>&1
end script
EOF

    if "${STATUS}" lukskms | \
       "${GREP}" 'stop/waiting' > /dev/null 2>&1
    then
      "${START}" lukskms
    fi
  fi

}

dump() {

  "${AWSCLI}" kms list-aliases --output text | \
    "${GREP}" "${KEYALS}"

  "${STATUS}" lukskms

  ls -lhrt "${LUKSEKEY}"

}

main() {

  preChecks
  encLUKSKey
  crteSrvc
  dump

}

main 2>&1|"$TEE" "${PRGNME}.log"
