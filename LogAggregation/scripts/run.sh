#! /bin/sh

ANSIBLE=/elk/bin/ansible-playbook
PLAYBOOK=elk.yml
INVENTORY=/tmp/inventory

if [[ ! -z ${ELK_BASE_URL} ]]
then
  ANSBLOPTS="-e base_url=${ELK_BASE_URL}"
fi

if [[ ! -z ${ELK_CLUSTER_NAME} ]]
then
  ANSBLOPTS="${ANSBLOPTS} -e cluster_name=${ELK_CLUSTER_NAME}"
fi

if [[ ! -z ${ELK_TCP_PORT} ]]
then
  ANSBLOPTS="${ANSBLOPTS} -e tcp_port=${ELK_TCP_PORT}"
fi

if [[ ! -z ${ELK_HTTP_PORT} ]]
then
  ANSBLOPTS="${ANSBLOPTS} -e http_port=${ELK_HTTP_PORT}"
fi

if [[ ! -z ${ELK_KIBANA_PORT} ]]
then
  ANSBLOPTS="${ANSBLOPTS} -e kibana_port=${ELK_KIBANA_PORT}"
fi

if [[ ! -z ${ELK_XPACK_ENABLE} ]]
then
  ANSBLOPTS="${ANSBLOPTS} -e '{\"apply_xpack\": ${ELK_XPACK_ENABLE}}'"
fi

if [[ ! -z ${ELK_CONSUL_ENABLE} ]]
then
  ANSBLOPTS="${ANSBLOPTS} -e '{\"apply_elkconsul\": ${ELK_CONSUL_ENABLE}}'"
fi

if [[ ! -z ${ELK_TAGS} ]]
then
  TAGS="-t ${ELK_TAGS}"
fi

${ANSIBLE} ${PLAYBOOK} -i ${INVENTORY} ${ANSBLOPTS} ${TAGS} -vvvv
