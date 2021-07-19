#! /bin/bash
# Usage: DOCKER_FILE=<DockerfileName> ./my_docker_file_linting.sh
set -uo pipefail

LOGF="$(basename "${0}"|sed 's/\.sh//').log"
DCKRFL="${DOCKER_FILE:-Dockerfile}"
DCKRIMG="hadolint/hadolint$(grep HDLNTAG .env|awk -F"=" '{print $NF}')"

docker run --rm -i "${DCKRIMG}" < "${DCKRFL}" 2>&1 | \
  tee "${LOGF}$(date +%s)"
