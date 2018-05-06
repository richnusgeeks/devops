#! /bin/bash
set -u

failed() {
  echo "${1} failed"
  exit -1
}

rm -rf staging
mkdir staging || failed "mkdir staging"

cp ./run.sh staging || failed "cp ./run.sh staging"
cp ./test_elasticsearch.py staging || failed "cp ./test_elasticsearch.py staging"
cp ../ansible/elk.yml staging || failed "cp -r ../ansible/elk.yml staging"
cp ../ansible/ansible.cfg staging || failed "cp -r ../ansible/ansible.cfg staging"
cp -r ../ansible/roles staging || failed "cp -r ../ansible/roles staging"
cp -r ../ansible/group_vars staging || failed "cp -r ../ansible/group_vars staging"

tee staging/Dockerfile <<EOF
FROM richnusgeeks.com:5001/richnusgeeks/rngelk/elkstack-base

WORKDIR /elkstack
COPY . /elkstack
RUN sed -i '/env/s|/usr/bin/env python|/elk/bin/python|' /elkstack/test_elasticsearch.py
RUN mv /elkstack/test_elasticsearch.py  /usr/local/bin/test_elasticsearch

CMD ./run.sh
EOF

tee staging/.dockerignore <<EOF
Dockerfile
roles/*/*/x-pack-5.5.0.zip
EOF

pushd staging || failed "pushd staging"
docker build --rm -t richnusgeeks.com:5001/richnusgeeks/rngelk/elkstack-tools . || failed "docker build -t richnusgeeks.com:5001/richnusgeeks/rngelk/elkstack-tools ."
docker push richnusgeeks.com:5001/richnusgeeks/rngelk/elkstack-tools
popd || failed "popd"

rm -rf staging || failed "rm -rfv staging"
