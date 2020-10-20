#! /bin/bash
set -uo pipefail

FTLSCFGINFL='/etc/footloose.cfg'
FTLSCFGOUFL='footloose.yaml'
FTLSCFGFLDS=(Name Count Image Networks Ports)

if [[ ! -f "${FTLSCFGINFL}" ]]
then
  echo " Error: required ${FTLSCFGINFL} not found, exiting ..."
  exit -1
fi

tee "${FTLSCFGOUFL}" <<EOF
cluster:
  name: cluster
  privateKey: cluster-key
machines:
EOF

while read Name Count Image Networks Ports
do
if echo ${Name}|grep '^ *#' > /dev/null 2>&1 || echo ${Name}|grep '^ *$' > /dev/null
then
  continue
fi
tee -a "${FTLSCFGOUFL}" <<EOF
- count: ${Count}
  spec:
    image: ${Image}  
    name: ${Name}%d
EOF
tee -a "${FTLSCFGOUFL}" <<EOF
    networks:
EOF
for n in $(echo "${Networks}"|sed 's/,/ /g')
do
tee -a "${FTLSCFGOUFL}" <<EOF
    - ${n}
EOF
done
tee -a "${FTLSCFGOUFL}" <<EOF
    portMappings:
EOF
for p in $(echo "${Ports}"|sed 's/,/ /g')
do
tee -a "${FTLSCFGOUFL}" <<EOF
    - containerPort: ${p}
EOF
done
tee -a "${FTLSCFGOUFL}" <<EOF
    privileged: true
    volumes:
    - type: volume
      destination: /var/lib/docker
EOF
done < "${FTLSCFGINFL}"

mv "${FTLSCFGOUFL}" "/tmp/${FTLSCFGOUFL}"
