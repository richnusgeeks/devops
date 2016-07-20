#! /bin/bash
set -u

OS='linux'
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
HCTLSVER[nomad]='0.4.0'
HCTLSVER[otto]='0.2.0'
HCTLSVER[packer]='0.10.1'
HCTLSVER[terraform]='0.6.16'
HCTLSVER[vault]='0.6.0'

exitOnErr() {

    local date=$(date)
    echo " Error: <$date> $1, exiting ..."
    exit 1

}

instlBase() {


  sudo apt-get update && sleep 5 && \
  sudo apt-get install -y --no-install-recommends \
   wget \
   unzip \
   apt-transport-https \
   ca-certificates
  echo

}

instlDocker() {

  if [ ! -f '/.dockerenv' ]
  then

    sudo apt-key adv --keyserver \
     hkp://p80.pool.sks-keyservers.net:80 \
     --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
    echo

    echo 'deb https://apt.dockerproject.org/repo ubuntu-trusty main'| \
     sudo tee /etc/apt/sources.list.d/docker.list
    echo

    sudo apt-get update && \
     sudo apt-get purge lxc-docker
    echo

    apt-cache policy docker-engine
    echo

    sudo apt-get update && \
     sudo apt-get install -y --no-install-recommends \
     linux-image-extra-$(uname -r) \
     apparmor
    echo

    sudo apt-get update && \
     sudo apt-get install -y --no-install-recommends \
     docker-engine
    echo

    sudo usermod -aG docker ubuntu
    echo

    sudo docker info
    echo

  fi

}

instlPyStuff() {

  sudo apt-get install -y --no-install-recommends \
   build-essential \
   libssl-dev \
   libffi-dev \
   python-dev \
   python-pip
  echo

  sudo pip install -U fabric \
   ansible \
   requests \
   boto \
   bottle \
   cryptography
  echo

}

instlHcrpStuff() {

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
      fi
    fi
  done

}

dumpCmpnts() {

  gcc --version
  g++ --version

  pip list|grep -Ei '(boto|requests|bottle|cryptography)'
  fab -V
  ansible --version

  for t in $HCTLS
  do
    eval "$t" version
  done

}

instlBase
instlDocker
instlPyStuff
instlHcrpStuff
dumpCmpnts
