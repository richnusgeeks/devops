#! /bin/bash
set -u

ROLES="env-tag1 \
       env-tag2 \
       env-tag3 \
       env-tag4 \
       env-tag5 \
       env-tag6 \
       env-tag7 \
       env-tag8 \
       env-tag9"
PRGNME="$(basename "$0"|sed 's/\.sh//')"

(
rm -f activity.log && ./dumpawsinfo.py > /dev/null

for r in $ROLES
do

  lsg=$(grep $r activity.log|grep -v 'INFO - *$'| \
        grep -E '(us-east-1|us-west-2|eu-west-1|ap-southeast-1)'| \
        grep -i 'state: running'| \
        grep -v "${r}-dynamic"| \
        grep -Ev '(ignore1|ignore2|ignore3)' | \
        awk -F"|" '{print $9}'| \
        sed 's/^ *GRPS: *//'| \
        sort -u| \
        sed 's/awseb\-e\-[0-9a-zA-Z]\{1,\}\-stack\-AWSEBSecurityGroup\-[0-9a-zA-Z]:sg\-[0-9a-zA-Z]\{1,\}\,//'| \
        sed 's/,/ /g'| \
        xargs| \
        sed 's/\(sg-[0-9a-zA-Z]\{1,\}\)/"\1"/g'| \
        sed 's/ /,/g')

  sgs=$(python -c "t=[$lsg];l=list(set(t));print ' '.join(l)")

  eip=$(terraform output -state=../prod/terraform.tfstate| \
        grep vrscnrprt_public_ip| \
        awk -F"=" '{print $2}'| \
        sed 's/^ \{1,\}//')

  sfx=$(echo ${r}|sed 's/-/_/g')
  sgfl="sg_rule_${sfx}.tf"
  mkdir -p "$sfx"
  > "${sfx}/${sgfl}"

  for s in $sgs
  do
tee -a "${sfx}/${sgfl}" <<EOF

  resource "aws_security_group_rule" "rule_${s}" {
    type = "ingress"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["${eip}/32"]

    security_group_id = "${s}"
  }

EOF

  done

  for f in $(ls ${sfx}/sg_rule_*.tf|xargs basename)
  do
    echo "$f =>"
    for g in $(grep security_group_id $f|awk -F"=" '{print $NF}'|sed 's/^ *//'|sed 's/"//g')
    do
      grep $g activity.log|awk -F"|" '{print $NF}'|sort -u
    done
    echo
  done

done

rm -f activity.log
) 2>&1|tee "${PRGNME}.log"

#sed -n '/=>/,/^ *$/p' "${PRGNME}.log"
