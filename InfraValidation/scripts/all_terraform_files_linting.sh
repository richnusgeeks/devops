#! /bin/bash
set -uo pipefail

LOGF="$(basename "${0}"|sed 's/\.sh//').log"
DCKRIMG="tfsec/tfsec"

find ../.. -type f | \
  grep '\.tf$' | \
  awk -F"/" '{print $3}' | \
  sort -u | \
  xargs -I {} sh -c 'echo "<=== {} ===>";docker run --rm -v "${PWD}/../../{}:/src:ro" tfsec/tfsec /src' | \
  tee "${LOGF}$(date +%s)"
