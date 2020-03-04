#! /bin/bash
set -uo pipefail

LOGF="$(basename "${0}"|sed 's/\.sh//').log"
DCKRIMG="koalaman/shellcheck$(grep SHCKTAG .env|awk -F"=" '{print $NF}')"

docker run --rm -v "${PWD}:/mnt" "${DCKRIMG}" -- *.sh 2>&1 | \
  tee "${LOGF}"	
