#! /bin/bash

if [[ "${1}" ]]
then
  docker image prune -f -a
else
  docker image prune -f
fi
