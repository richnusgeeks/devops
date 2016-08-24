#! /bin/bash
set -u

NUMARG=$#
SWTCH="$1"
PRGNME=$(basename "$0" | sed -n 's/\.sh//p')
REPOURL='bitbucket.org/<Repo>'
APPREPO='<App Repo>.git'
STGNDIR='staging'
GCPCRURL='gcr.io'
GCPPRJID='<GCP Project ID>'
APPIDIN='<App GKE ID>'
APPORT=<App Port>
NUMRPLCS=2
IMGSTOKP=3
DLVRY=false
DUMP=false
ALL=false
DPLOY=false
CLEAN=false

exitOnErr() {

    local date=$(date)
    echo " Error: <$date> $1, exiting ..."
    exit 1

}

prntUsage() {

    echo "Usages: $PRGNME <-r|--dlvry|-p|--deploy||"
    echo "                   |-p|--dploy|-c|--clean|-a|--all>"
    echo "        -r|--dlvry Push docker image,"
    echo "        -p|--dploy Deploy latest image,"
    echo "        -d|--dump  Dump various info,"
    echo "        -a|--all   Create+Deliver+Deploy,"
    echo "        -c|--clean Remove everything delivered/deployed,"
    exit 0

}

parseArgs() {

    if [ $NUMARG -ne 1 ]
    then
        prntUsage
    fi

    if [ "$SWTCH" = "-r" ] ||  [ "$SWTCH" = "--dlvry" ]
    then
        DLVRY=true
    elif [ "$SWTCH" = "-d" ] || [ "$SWTCH" = "--dump" ]
    then
        DUMP=true
    elif [ "$SWTCH" = "-a" ] || [ "$SWTCH" = "--all" ]
    then
        ALL=true
    elif [ "$SWTCH" = "-p" ] || [ "$SWTCH" = "--dploy" ]
    then
        DPLOY=true
    elif [ "$SWTCH" = "-c" ] || [ "$SWTCH" = "--clean" ]
    then
        CLEAN=true
    else
        prntUsage
    fi

}

prepareCode() {

  if [ ! -d $(echo ${APPREPO}|awk -F"." '{print $1}') ]
  then
    sudo git clone "https://$(python getscrts.pyc 1):$(python getscrts.pyc 2)@${REPOURL}/${APPREPO}"
  else
    pushd $(echo ${APPREPO}|awk -F"." '{print $1}')
    sudo git pull
    popd
  fi
  
  for d in $(grep <Repo> "$(echo ${APPREPO}|awk -F"." '{print $1}')"/package.json|awk -F":" '{print $1}'|sed 's/^ *//'|sed 's/"//g')
  do
    if [ ! -d ${d} ]
    then
      sudo git clone "https://$(python getscrts.pyc 1):$(python getscrts.pyc 2)@${REPOURL}/${d}.git"
    else
      pushd ${d}
      sudo git pull
      popd
    fi
  done

}

prepareStgng() {

  sudo mkdir -p ${STGNDIR}
  pushd ${STGNDIR}

  sudo tee Dockerfile <<EOF
FROM node:6.4-slim
EXPOSE ${APPORT}
COPY ./<App Repo>/ .
CMD npm start
EOF

  sudo rm -rf $(echo ${APPREPO}|awk -F"." '{print $1}')
  sudo cp -r ../$(echo ${APPREPO}|awk -F"." '{print $1}') .
  pushd $(echo ${APPREPO}|awk -F"." '{print $1}')
  sudo sed -i '/<Repo>/s/bitbucket:<Repo>/..\/../' package.json
  sudo npm install
  popd
  popd

}

createDckrImg() {

  TAG=$(date +%s)

  if ! sudo docker images|grep "${GCPCRURL}/${GCPPRJID}/${APPIDIN}:${TAG}" > /dev/null 2>&1
  then
    pushd ${STGNDIR}
    docker build -t "${GCPCRURL}/${GCPPRJID}/${APPIDIN}:${TAG}" .
    popd  
  fi

}

pushDckrImg() {

  if ! sudo gcloud alpha container images list-tags "${GCPCRURL}/${GCPPRJID}/${APPIDIN}"| \
       grep -v TAGS|grep "${TAG}" > /dev/null 2>&1
  then
    sudo gcloud docker push "${GCPCRURL}/${GCPPRJID}/${APPIDIN}:${TAG}"
  fi

}

deployApp() {

  if ! sudo gcloud container clusters list|grep "${APPIDIN}" > /dev/null 2>&1
  then
    sudo gcloud container clusters create "${APPIDIN}"
    sleep 10
    sudo gcloud container clusters get-credentials "${APPIDIN}"

    if ! sudo kubectl get deployments|grep "${APPIDIN}" > /dev/null 2>&1
    then
      sudo kubectl run "${APPIDIN}" --image="${GCPCRURL}/${GCPPRJID}/${APPIDIN}:${TAG}" \
                                     --port="${APPORT}"
      sleep 10
      sudo kubectl scale deployment "${APPIDIN}" --replicas="${NUMRPLCS}"
      sleep 10
      sudo kubectl expose deployment "${APPIDIN}" --type="LoadBalancer"

      while true
      do
        if sudo kubectl get services "${APPIDIN}"|grep '<pending>' > /dev/null 2>&1
        then
          sleep 5
        else
          break
        fi 
      done
    fi

  else
    sudo kubectl set image "deployment/${APPIDIN}" "${APPIDIN}=${GCPCRURL}/${GCPPRJID}/${APPIDIN}:${TAG}"
  fi

}

cleanAll() {

  sudo kubectl delete service,deployment "${APPIDIN}"
  sudo gcloud container clusters delete "${APPIDIN}" -q

#  for i in $(sudo gcloud alpha container images list-tags "${GCPCRURL}/${GCPPRJID}/${APPIDIN}"|grep -v TAGS|sort -nrk2|awk '{print $2}'|tail -n +$((IMGSTOKP+1)))
#  do
#    sudo gcloud alpha container images
#  done

  for d in $(grep <Repo> "$(echo ${APPREPO}|awk -F"." '{print $1}')"/package.json|awk -F":" '{print $1}'|sed 's/^ *//'|sed 's/"//g')
  do
    sudo rm -rf "${d}"
  done

  sudo rm -rf "$(echo ${APPREPO}|awk -F"." '{print $1}')"

}

dumpInfo() {

  sudo docker images|grep "${APPIDIN}"
  echo
  sudo gcloud alpha container images list-tags "${GCPCRURL}/${GCPPRJID}/${APPIDIN}"|grep -v TAGS|sort -nrk2
  echo
  sudo kubectl get deployments
  echo
  sudo kubectl get pods
  echo
  sudo kubectl get services "${APPIDIN}"
  echo
  sudo kubectl cluster-info
  echo
  sudo gcloud container clusters describe "${APPIDIN}"|grep -E 'user|password'
  echo

}

main() {

  parseArgs

  if $DLVRY
  then
    prepareCode
    prepareStgng
    createDckrImg
    pushDckrImg
    dumpInfo
  fi

  if $DPLOY
  then
    deployApp
  fi

  if $DUMP
  then
    dumpInfo
  fi

  if $ALL
  then
    prepareCode
    prepareStgng
    createDckrImg
    pushDckrImg
    deployApp
    dumpInfo
  fi

  if $CLEAN
  then
    cleanAll
    dumpInfo
  fi

}

main 2>&1|sudo tee "${PRGNME}.log"
