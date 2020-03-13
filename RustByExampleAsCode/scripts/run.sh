#! /bin/bash
set -uo pipefail

BINDADDR="$(grep "$(cat /etc/hostname)" /etc/hosts|awk '{print $1}')"

exec mdbook serve -n "${BINDADDR}"
