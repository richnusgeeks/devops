#! /bin/bash
set -uo pipefail

FTLSCFGINFL=${FTLSCFGINFL:-'/etc/bootloose.cfg'}
FTLSCFGOUFL=${FTLSCFGOUFL:-'bootloose.yaml'}
FTLSCFGFLDS=(Name Count Image Networks Ports)

if [[ ! -f "${FTLSCFGINFL}" ]]
then
  echo " Error: required ${FTLSCFGINFL} not found, exiting ..."
  exit 1
fi

tee "${FTLSCFGOUFL}" <<EOF
cluster:
  name: cluster
  privateKey: cluster-key
machines:
EOF

while read -r Name Count Image Networks Ports
do
if echo "${Name}"|grep '^ *#' > /dev/null 2>&1 || echo "${Name}"|grep '^ *$' > /dev/null
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
for n in ${Networks//,/ }
do
tee -a "${FTLSCFGOUFL}" <<EOF
    - ${n}
EOF
done
tee -a "${FTLSCFGOUFL}" <<EOF
    portMappings:
EOF
for p in ${Ports//,/ }
do
if echo "${p}" | grep ':' > /dev/null 2>&1
then
hstprt="$(echo "${p}" | awk -F':' '{print $1}')"
ctrprt="$(echo "${p}" | awk -F':' '{print $2}')"
tee -a "${FTLSCFGOUFL}" <<EOF
    - containerPort: ${ctrprt}
      hostPort: ${hstprt}
EOF
else
tee -a "${FTLSCFGOUFL}" <<EOF
    - containerPort: ${p}
EOF
fi
done
tee -a "${FTLSCFGOUFL}" <<EOF
    privileged: true
    volumes:
    - type: volume
      destination: /var/lib/docker
EOF
done < "${FTLSCFGINFL}"

mv "${FTLSCFGOUFL}" "/tmp/${FTLSCFGOUFL}"
