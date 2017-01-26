#! /bin/bash
set -eu

ROLES="env-tag1 \
       env-tag2 \
       env-tag3 \
       env-tag4 \
       env-tag5 \
       env-tag6 \
       env-tag7 \
       env-tag8 \
       env-tag9 \
       env-tag10"

rm -f activity.log
python dumpawsinfo.py -i > /dev/null

for r in $ROLES
do

  case $r in
  env-tag1)
    ENVR=env1
    ;;
  env-tag2)
    ENVR=env2
    ;;
  env-tag3)
    ENVR=env3
    ;;
  env-tag4)
    ENVR=env4
    ;;
  env-tag5)
    ENVR=env5
    ;;
  env-tag6)
    ENVR=env6
    ;;
  env-tag7)
    ENVR=env7
    ;;
  env-tag8)
    ENVR=env8
    ;;
  env-tag9)
    ENVR=env9
    ;;
  env-tag10)
    ENVR=env10
    ;;
  esac

  NDFL="$(echo ${r}|sed 's/-/_/g')_nodes.py"

tee "${NDFL}" <<EOF
from fabric.api import env

env.roledefs["${r}.${ENVR}"] = [

EOF

  cat activity.log                | \
  grep -v 'INFO - *$'             | \
  grep -E '(us-east-1|us-west-2|eu-west-1|ap-southeast-1)' | \
  grep -i 'state: running'        | \
  grep -v "${r}-dynamic"          | \
  grep -Ev '(ignore1|ignore2|ignore3)' | \
  awk -F"|" '{print $5}'          | \
  grep "${r}"                    | \
  sed 's/^ *Tags: *//'            | \
  sort -u|sed 's/^ *//'           | \
  sed 's/ *$//'                   | \
  sed "s/$/.${ENVR}.domain.com/"  | \
  sed 's/ *$//'                   | \
  sed 's/^/"/'                    | \
  sed 's/$/",/'                   | \
  tee -a "${NDFL}"

tee -a "${NDFL}" <<EOF

]
EOF

done

rm -f activity.log
