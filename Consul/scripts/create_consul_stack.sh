#! /bin/bash

export VAGRANT_CWD=../tests

vagrant up
pushd ../ansible
ansible-playbook site.yml -i ../tests/test_vagrant
