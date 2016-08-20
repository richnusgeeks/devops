#! /bin/bash
set -u

PCKGSG="unzip \
        apt-transport-https \
        ca-certificates"
PCKGSK="linux-image-extra-$(uname -r) \
        apparmor"
PCKGSB="build-essential \
        libssl-dev \
        libffi-dev \
        python-dev \
        python-pip \
        git"
PCKGSP="fabric \
        requests \
        boto \
        bottle \
        cryptography"
HCTLSLOC='/usr/local/bin'
HCTLSURL='https://releases.hashicorp.com'
declare -A HCTLSVER
HCTLS="consul \
       nomad \
       otto \
       packer \
       terraform \
       vault"
HCTLSVER[consul]='0.6.4'
HCTLSVER[nomad]='0.4.1'
HCTLSVER[otto]='0.2.0'
HCTLSVER[packer]='0.10.1'
HCTLSVER[terraform]='0.7.0'
HCTLSVER[vault]='0.6.0'
NDJSVER='6.4.0'
NDJSURL='https://nodejs.org'
GCPSVER='122.0.0'
GCPSURL='https://dl.google.com/dl/cloudsdk/channels/rapid/downloads'


exitOnErr() {

    local date=$(date)
    echo " Error: <$date> $1, exiting ..."
    exit 1

}

instlGeneral() {

  if ! sudo apt-key adv --keyserver \
    hkp://p80.pool.sks-keyservers.net:80 \
    --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
  then
    exitOnErr "sudo apt-key adv --keyserver failed"
  else
    echo
  fi

  sudo apt-get update
  if ! sudo apt-get install -y --no-install-recommends ${PCKGSG}
  then
    exitOnErr "apt-get install ${PCKGSG} failed"
  else
    echo
  fi

}

instlDocker() {

  if ! echo 'deb https://apt.dockerproject.org/repo ubuntu-trusty main'| \
    sudo tee /etc/apt/sources.list.d/docker.list
  then
    exitOnErr "tee /etc/apt/sources.list.d/docker.list failed"
  else
    echo
  fi

  sudo apt-get update
  if ! sudo apt-get purge lxc-docker
  then
    exitOnErr "apt-get purge lxc-docker failed"
  else
    echo
  fi

  apt-cache policy docker-engine
  echo

  if ! sudo apt-get install -y --no-install-recommends ${PCKGSK}
  then
    exitOnErr "apt-get install ${PCKGSK} failed"
  else
    echo
  fi

  if ! sudo apt-get install -y --no-install-recommends \
    docker-engine
  then
    exitOnErr "apt-get install docker-engine failed"
  else
    echo
  fi

  sudo usermod -aG docker ubuntu
  echo

}

instlPtools() {

  if ! sudo apt-get install -y --no-install-recommends ${PCKGSB}
  then
    exitOnErr "apt-get install ${PCKGSB} failed"
  else
    echo
  fi

  if ! sudo pip install -U ${PCKGSP}
  then
    exitOnErr "pip install ${PCKGSP} failed"
  else
    echo
  fi

}

instlHctls() {

  if uname -v | grep -i darwin 2>&1 > /dev/null
  then
    OS='darwin'
    HCTLSLOC='~/Development/Cloud/Works'
  else
    OS='linux'
  fi

  for t in $HCTLS
  do
    if ! wget -P /tmp --tries=5 -q -L "$HCTLSURL/$t/${HCTLSVER[$t]}/${t}_${HCTLSVER[$t]}_${OS}_amd64.zip"
    then
      exitOnErr "wget -P /tmp $HCTLSURL/$t/${HCTLSVER[$t]}/${t}_${HCTLSVER[$t]}_${OS}_amd64.zip failed"
    else
      if ! sudo unzip -o "/tmp/${t}_${HCTLSVER[$t]}_${OS}_amd64.zip" -d "$HCTLSLOC"
      then
        exitOnErr "unzip /tmp/${t}_${HCTLSVER[$t]}_${OS}_amd64.zip -d $HCTLSLOC"
      else
        rm -fv "/tmp/${t}_${HCTLSVER[$t]}_${OS}_amd64.zip"
        eval "$t" version
      fi
    fi
  done

}

instlNodejs() {

  pushd /opt
  if ! sudo wget -P /opt --tries=5 -q -L "${NDJSURL}/dist/v${NDJSVER}/node-v${NDJSVER}-${OS}-x64.tar.xz" 2>&1 > /dev/null
  then
    exitOnErr "wget -P /opt ${NDJSURL}/dist/v${NDJSVER}/node-v${NDJSVER}-${OS}-x64.tar.xz failed"
  else
    if ! sudo tar Jxf "node-v${NDJSVER}-${OS}-x64.tar.xz" 2>&1 > /dev/null
    then
      exitOnErr "tar Jxf node-v${NDJSVER}-${OS}-x64.tar.xz failed"
    else
      sudo rm "node-v${NDJSVER}-${OS}-x64.tar.xz"
      sudo mv "node-v${NDJSVER}-${OS}-x64" nodejs
      sudo ln -s "/opt/nodejs/bin/node" /usr/local/bin/node
      sudo ln -s "/opt/nodejs/bin/npm" /usr/local/bin/npm
    fi
  fi

}

instlGcpsdk() {

  pushd /opt
  if ! sudo wget -P /opt --tries=5 -q -L "${GCPSURL}/google-cloud-sdk-${GCPSVER}-${OS}-x86_64.tar.gz" 2>&1 > /dev/null
  then
    exitOnErr "wget -P /opt ${GCPSURL}/google-cloud-sdk-${GCPSVER}-${OS}-x86_64.tar.gz failed"
  else
    if ! sudo tar zxf "google-cloud-sdk-${GCPSVER}-${OS}-x86_64.tar.gz" 2>&1 > /dev/null
    then
      exitOnErr "tar google-cloud-sdk-${GCPSVER}-${OS}-x86_64.tar.gz failed"
    else
      sudo rm "google-cloud-sdk-${GCPSVER}-${OS}-x86_64.tar.gz"
      sudo google-cloud-sdk/install.sh -q
      sudo google-cloud-sdk/bin/gcloud -q components install kubectl
      echo 'export PATH=/opt/google-cloud-sdk/bin/:$PATH'|sudo tee /etc/profile.d/gcpsdk.sh
    fi
  fi

}

dumpCmpnts() {

  pip list|grep -Ei '(boto|requests|bottle|cryptography)'
  echo
  fab -V
  echo
  node -v
  echo
  npm -v
  echo
  sudo docker info
  echo
  /opt/google-cloud-sdk/bin/gcloud components list
  echo

}

main() {

  instlGeneral
  instlDocker
  instlPtools
  instlHctls
  instlNodejs
  instlGcpsdk
  dumpCmpnts

}

main
