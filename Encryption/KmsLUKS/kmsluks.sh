#! /bin/bash
set -u

DF=$(which df)
TEE=$(which tee)
GREP=$(which grep)
SRVC=$(which service)
SLEEP=$(which sleep)
SLPDUR=5
NUMARG=$#
KEYALS="$1"
PRGNME=$(basename "$0" | sed -n 's/\.sh//p')
AWSCLI=$(which aws)
BASE64=$(which base64)
LR0MDN='raid0'
RAID0DEV='/dev/md0'
LUKSKEY='/luks.key'
LUKSEKEY='/.luks'
CRPTSTUP=$(which cryptsetup)

exitOnErr() {

  local date=$(date)
  echo " Error: <$date> $1, exiting ..."
  exit 1

}

preChecks() {

  if [ ${NUMARG} -ne 1 ]
  then
    echo " Usage: ${PRGNME} <Master Key Alias>"
    exit 0
  fi

  if [ ! -e "${LUKSEKEY}" ]
  then
    exitOnErr "required ${LUKSEKEY} not found"
  fi

  if ! "${AWSCLI}" kms list-aliases | \
        "${GREP}" AliasName | \
        "${GREP}" "${KEYALS}" > /dev/null 2>&1

  then
    exitOnErr "list-aliases ${KEYALS} failed"
  fi
   
}

decMntLUKSKey() {

  if ! "$DF" -kh | \
       "${GREP}" "${LR0MDN}" > /dev/null 2>&1
  then
    if ! "${AWSCLI}" kms decrypt --ciphertext-blob "fileb://${LUKSEKEY}" --output text --query Plaintext | \
         "${BASE64}" -d | \
         "${TEE}" "${LUKSKEY}" 1>/dev/null
    then
      exitOnErr "kms decrypt fileb://${LUKSEKEY} failed"
    else
      if ! "${CRPTSTUP}" luksOpen --key-file "${LUKSKEY}" "${RAID0DEV}" "${LR0MDN}"
      then
        exitOnErr "${CRPTSTUP} luksOpen failed"
      else
        rm -fv "${LUKSKEY}"
      fi
    fi
  fi

}

strtDSE() {

  if "$DF" -kh | \
     "${GREP}" "${LR0MDN}" > /dev/null 2>&1
  then
    if ! "${SRVC}" dse status > /dev/null 2>&1
    then
      "${SRVC}" dse start
      "${SLEEP}" "${SLPDUR}"
      "${SRVC}" dse status
    fi
  fi

}

main() {

  while true
  do

    preChecks 
    decMntLUKSKey
    strtDSE

    "${SLEEP}" "${SLPDUR}"
  done

}

main 2>&1
