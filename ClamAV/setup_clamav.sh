#! /bin/bash
set -u

AVVER="$1"

apt-get install -y --no-install-recommends \
  build-essential \
  zlib1g-dev      \
  libssl-dev      \
  libbz2-dev && \
  echo ' INFO: development tools/libraries installed.'

wget "http://www.clamav.net/downloads/production/clamav-${AVVER}.tar.gz" -P /tmp && \
  tar zxvf "/tmp/clamav-${AVVER}.tar.gz" -C /tmp && \
  echo "INFO: clamav tarball fetched and untar'd."
sleep 5
cd "/tmp/clamav-${AVVER}" && \
  ./configure && \
  make install && \
  ldconfig &&     \
  echo 'INFO: clamav binaries installed.'

useradd -r -U clamav -s /bin/false && \
  mkdir -p /usr/local/share/clamav && \
  chown clamav:clamav /usr/local/share/clamav && \
  echo 'INFO: clamav user/group created.' 

for f in freshclam clamd
do
  mv /usr/local/etc/${f}.conf.sample /usr/local/etc/${f}.conf
done
sleep 5
sed -i '/^ *Example/s/^/#/' /usr/local/etc/freshclam.conf
sleep 5
freshclam && \
  echo ' INFO: virus db updated.'

rm -fv "/tmp/clamav-${AVVER}.tar.gz" \
  /tmp/*.sh \
  /tmp/*.log && \
  echo ' INFO: .sh and .logs cleaned.'
cd "/tmp/clamav-${AVVER}" && \
  make clean && \
  make distclean && \
  echo ' INFO: clamav source tree cleaned.'
