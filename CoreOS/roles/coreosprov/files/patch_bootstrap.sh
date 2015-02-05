#! /bin/bash
AWK=$(which awk)
SED=$(which sed)
ECHO=$(which echo)
CURL=$(which curl)
DIFF=$(which diff)

token=$("$CURL" https://discovery.etcd.io/new | \
        "$AWK" -F"/" '{print $4}')

"$SED" -i.old "/^ \{1,\}discovery:/s/[0-9a-zA-Z]\{32\}/$token/" bootstrap
"$DIFF" bootstrap{,.old} || true

