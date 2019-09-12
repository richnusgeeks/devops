#! /bin/bash

LPUBKEY='/tmp/test.pub'
LAUTHKEY='/root/.ssh/authorized_keys'

if [[ -e "${LPUBKEY}" ]]
then
  cat "${LPUBKEY}" >> "${LAUTHKEY}"
fi

/sbin/my_init
