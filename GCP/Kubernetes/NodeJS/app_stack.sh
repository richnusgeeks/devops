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
APPUIDIN='<App GKE ID>'
APPCNFG='app.yaml'
ZONE='us-east1-b'
declare -A ADNLZNE
ADNLZNE[us-east1-b]='us-east1-c'
declare -A ZONENME
ZONENME[dev]='gcp-dev'
ZONENME[test]='gcp-test'
ZONENME[prvw]='gcp-pre'
ZONENME[prod]='gcp-prod'
DMNNME='richnusgeeks.com'
ENV='prod'
APPUIPRT=8080
OATHPTH='https://auth.richnusgeeks.com/oauth'
APIPTH='https://api.richnusgeeks.com/richnusgeeks/api'
APPPTH='http://api-dot-rng.appspot.com'
CLNTID='richnusgeeks_ui'
CLNTSCRT=$(echo -n rng | base64)
NUMRPLCS=2
IMGSTOKP=3
MINNDS=2
MAXNDS=6
CPUPER=50
GCPAPPEN=false
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
    echo "        -r|--dlvry Create+Deliver docker image,"
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

preChecks() {

  if [ ! -f "${PRGNME}.yaml" ]
  then
    exitOnErr "required config ${PRGNME}.yaml not found"
  fi

  local prjlst=$(sudo gcloud config configurations list)

  local prfl=$(echo "$prjlst"|awk '$2 == "False"'|awk -v gpi="${GCPPRJID}" '$4 == gpi'|awk '{print $1}')
  if [ ! -z "$prfl" ]
  then
    if ! sudo gcloud config configurations activate "$prfl"
    then
      exitOnErr "gcloud config configurations activate $prfl failed"
    fi
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
  
  for d in $(grep richnusgeeks "$(echo ${APPREPO}|awk -F"." '{print $1}')"/package.json|awk -F":" '{print $1}'|sed 's/^ *//'|sed 's/"//g')
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

  mkdir -p ${HOME}/${STGNDIR}
  pushd ${HOME}/${STGNDIR}
  mkdir -p $(echo ${APPREPO}|awk -F"." '{print $1}'|sed 's/-//')
  rm -rf $(echo ${APPREPO}|awk -F"." '{print $1}'|sed 's/-//')/*
  pushd $(echo ${APPREPO}|awk -F"." '{print $1}'|sed 's/-//')

  tee Dockerfile <<EOF
FROM node:6.4-slim
EXPOSE ${APPUIPRT}
WORKDIR $(echo ${APPREPO}|awk -F"." '{print $1}')
COPY ./$(echo ${APPREPO}|awk -F"." '{print $1}') .
CMD npm run production
EOF

  cp -r /opt/$(echo ${APPREPO}|awk -F"." '{print $1}') .
  pushd $(echo ${APPREPO}|awk -F"." '{print $1}')
  sed -i -e '/richnusgeeks/s/.git#[.0-9]\{1,\}//g' \
         -e '/richnusgeeks/s/git@bitbucket.org:richnusgeeks-ondemand/\/opt/' \
         package.json
#         -e '/SET NODE_ENV/s/SET/export/' \
  npm install
  popd
  popd
  popd

}

createDckrImg() {

  TAG=$(date +%s)

  if ! sudo docker images|grep "${GCPCRURL}/${GCPPRJID}/${APPUIDIN}:${TAG}" > /dev/null 2>&1
  then
    pushd ${HOME}/${STGNDIR}/$(echo ${APPREPO}|awk -F"." '{print $1}'|sed 's/-//')
    docker build -t "${GCPCRURL}/${GCPPRJID}/${APPUIDIN}:${TAG}" .
    popd  
  fi

}

pushDckrImg() {

  if ! sudo gcloud alpha container images list-tags "${GCPCRURL}/${GCPPRJID}/${APPUIDIN}"| \
       grep -v TAGS|grep "${TAG}" > /dev/null 2>&1
  then
    sudo gcloud docker -- push "${GCPCRURL}/${GCPPRJID}/${APPUIDIN}:${TAG}"
  fi

}

updateDNS() {

  local SIP="$1"

  if sudo gcloud dns managed-zones list|grep "${ZONENME[${GCPPRJID}]}.${DMNNME}" > /dev/null 2>&1
  then
    local ip=$(sudo gcloud dns record-sets list -z="${ZONENME[${GCPPRJID}]}"|grep "appui.${ZONENME[${GCPPRJID}]}.${DMNNME}."|awk '{print $NF}')
    if [[ ! -z "$ip" ]] && [[ "$SIP" != "$ip" ]]
    then
      if sudo gcloud dns record-sets transaction start -z="${ZONENME[${GCPPRJID}]}"
      then
        if sudo gcloud dns record-sets transaction remove -z="${ZONENME[${GCPPRJID}]}" \
           --name="appui.${ZONENME[${GCPPRJID}]}.${DMNNME}." \
           --type=A --ttl=300 "${ip}"
        then
          sudo gcloud dns record-sets transaction execute -z="${ZONENME[${GCPPRJID}]}"
          sleep 5
        fi
      fi
    fi

    if [[ "$SIP" != "$ip" ]]
    then
      if sudo gcloud dns record-sets transaction start -z="${ZONENME[${GCPPRJID}]}"
      then
        if sudo gcloud dns record-sets transaction add -z="${ZONENME[${GCPPRJID}]}" \
           --name="appui.${ZONENME[${GCPPRJID}]}.${DMNNME}." \
           --type=A --ttl=300 "${SIP}"
        then
          sudo gcloud dns record-sets transaction execute -z="${ZONENME[${GCPPRJID}]}"
        fi
      fi
    fi

  fi

}

deployAppUI() {

  if $GCPAPPEN
  then
    sudo tee ${APPCNFG} <<EOF
runtime: nodejs
vm: true
service: ${APPUIDIN}
EOF

    sudo gcloud app deploy -q --image-url "${GCPCRURL}/${GCPPRJID}/${APPUIDIN}:${TAG}"

  else

    if ! sudo gcloud container clusters list --zone=${ZONE}|grep "${APPUIDIN}" > /dev/null 2>&1
    then
      sudo gcloud container clusters create "${APPUIDIN}" --num-nodes=${MINNDS} \
         --machine-type n1-standard-2 \
         --enable-autoscaling --min-nodes=${MINNDS} --max-nodes=${MAXNDS} \
         --network=app --subnetwork=ui --zone=${ZONE} --additional-zones=${ADNLZNE[${ZONE}]}

      sleep 10

      sudo gcloud container clusters get-credentials --zone=${ZONE} "${APPUIDIN}"

      if ! sudo kubectl get deployments|grep "${APPUIDIN}" > /dev/null 2>&1
      then
        sudo cp "${PRGNME}.yaml" "/tmp/${PRGNME}.temp.yaml"
        if sudo sed -i -e "s|<NUMRPLCS>|${NUMRPLCS}|" \
                       -e "s|<APPUIDIN>|${APPUIDIN}|" \
                       -e "s|<APPUIPRT>|${APPUIPRT}|" \
                       -e "s|<GCPCRURL>|${GCPCRURL}|" \
                       -e "s|<GCPPRJID>|${GCPPRJID}|" \
                       -e "s|<TAG>|${TAG}|" \
                       -e "s|<ENV>|${ENV}|" \
                       -e "s|<OATHPTH>|${OATHPTH}|" \
                       -e "s|<APIPTH>|${APIPTH}|" \
                       -e "s|<APPPTH>|${APPPTH}|" \
                       -e "s|<CLNTID>|${CLNTID}|" \
                       -e "s|<CLNTSCRT>|${CLNTSCRT}|" \
                       "/tmp/${PRGNME}.temp.yaml"
        then
          if sudo kubectl create --validate -f "/tmp/${PRGNME}.temp.yaml"
          then
            sleep 10
            sudo kubectl autoscale deployment "${APPUIDIN}" \
              --min=${MINNDS} --max=${MAXNDS} --cpu-percent=${CPUPER}

            while true
            do
              if sudo kubectl get services "${APPUIDIN}"|grep '<pending>' > /dev/null 2>&1
              then
                sleep 5
              else
                sudo rm -f transaction.yaml
                SIP=$(sudo kubectl get services "${APPUIDIN}"| \
                           grep -E '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+'| \
                           awk '{print $3}')
                updateDNS "${SIP}"
                sudo rm -f transaction.yaml
                break
              fi
            done
          fi
        fi
      fi  
    else
      sudo gcloud container clusters get-credentials --zone=${ZONE} "${APPUIDIN}"
      sudo kubectl set image "deployment/${APPUIDIN}" "${APPUIDIN}=${GCPCRURL}/${GCPPRJID}/${APPUIDIN}:${TAG}"
      sudo rm -f transaction.yaml
      SIP=$(sudo kubectl get services "${APPUIDIN}"| \
                         grep -E '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+'| \
                         awk '{print $3}')
      updateDNS "${SIP}"
      sudo rm -f transaction.yaml
    fi

  fi

}

cleanAll() {

  if ! $GCPAPPEN
  then
    sudo kubectl delete -f "/tmp/${PRGNME}.temp.yaml"
    sudo rm -f "/tmp/${PRGNME}.temp.yaml"

    local ip=$(sudo gcloud dns record-sets list -z="${ZONENME[${GCPPRJID}]}"|grep "appui.${ZONENME[${GCPPRJID}]}.${DMNNME}."|awk '{print $NF}')
    if [[ ! -z "$ip" ]]
    then
      if sudo gcloud dns record-sets transaction start -z="${ZONENME[${GCPPRJID}]}"
      then
        if sudo gcloud dns record-sets transaction remove -z="${ZONENME[${GCPPRJID}]}" \
           --name="appui.${ZONENME[${GCPPRJID}]}.${DMNNME}." \
           --type=A --ttl=300 "${ip}"
        then
          sudo gcloud dns record-sets transaction execute -z="${ZONENME[${GCPPRJID}]}"
          sleep 5
        fi
      fi
    fi

    sudo gcloud container clusters delete --zone=${ZONE} "${APPUIDIN}" -q

  else
    sudo gcloud -q app services delete "${APPUIDIN}"
  fi

#  for i in $(sudo gcloud alpha container images list-tags "${GCPCRURL}/${GCPPRJID}/${APPUIDIN}"|grep -v TAGS|sort -nrk2|awk '{print $2}'|tail -n +$((IMGSTOKP+1)))
#  do
#    sudo gcloud alpha container images
#  done

  for d in $(grep richnusgeeks "$(echo ${APPREPO}|awk -F"." '{print $1}')"/package.json|awk -F":" '{print $1}'|sed 's/^ *//'|sed 's/"//g')
  do
    sudo rm -rf "${d}"
  done

  sudo rm -rf "$(echo ${APPREPO}|awk -F"." '{print $1}')"
  rm -rfv "${HOME}/${STGNDIR}"

  sudo docker rmi $(sudo docker images "${GCPCRURL}/${GCPPRJID}/${APPUIDIN}"|grep -v TAG|sort -nrk2|tail -n +$((IMGSTOKP+1))|awk '{print $3}')

}

dumpInfo() {

  sudo docker images|grep "${APPUIDIN}"
  echo
  sudo gcloud alpha container images list-tags "${GCPCRURL}/${GCPPRJID}/${APPUIDIN}"|grep -v TAGS|sort -nrk2
  echo

  if ! $GCPAPPEN
  then
    sudo gcloud container clusters get-credentials --zone=${ZONE} "${APPUIDIN}"
    sudo kubectl get deployments
    echo
    sudo kubectl get pods
    echo
    sudo kubectl get services "${APPUIDIN}"
    echo
    sudo kubectl cluster-info
    echo
    sudo gcloud container clusters describe --zone=${ZONE} "${APPUIDIN}"|grep -E 'user|password'
  else
    sudo gcloud app services list
    echo
    sudo gcloud app versions list
  fi

  echo

}

main() {

  parseArgs
  preChecks

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
    deployAppUI
    dumpInfo
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
    deployAppUI
    dumpInfo
  fi

  if $CLEAN
  then
    cleanAll
    dumpInfo
  fi

}

main 2>&1|sudo tee "${PRGNME}.log"
