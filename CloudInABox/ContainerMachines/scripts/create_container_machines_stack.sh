#! /bin/bash

OPTN=${1}
OPTNTST=${2}
NUMOPTNMX=3
DLYTOMSTL=5
CMPSFLDIR='.'
ANSBLEDIR='../ansible'
ANSBLEHIN='hosts'
FTLSCTDIR='/var/lib/footloose'
FTLSCTRKY='cluster-key'
FTLSNTWRK='cldinabox-demo'
ASBLCMTEST='ansible_test.yml'
ASBLCMCSRV='ansible_cnslsrvr.yml'
ASBLCMCLNT='ansible_cnslclnt.yml'
ASBLCMCTPL='ansible_cnsltmplt.yml'
ASBLCMHSUI='ansible_hashiui.yml'
ASBLCMCESM='ansible_cnslesm.yml'
ASBLCMDGOS='ansible_goss.yml'
ASBLCMDCKR='ansible_docker.yml'
ASBLCMDCAS='ansible_cassandra.yml'
ASBLCMDELS='ansible_elasticsearch.yml'
ASBLCMDKAF='ansible_kafka.yml'
ASBLCMDSPR='ansible_spark.yml'
ASBLCMPMTR='ansible_monitoror.yml'
ASBLCMPVGL='ansible_vigil.yml'
DCKRCMPMTR='monitoror.yml'
DCKRCMPTIR='testinfra.yml'
SRVCNFGMTR='../configs/monitoror/config.json'
SRVCNFGVGL='../configs/vigil/config.cfg'
DCKRCMPVGL='vigil.yml'
FTLSCMPSCT='footloose_create.yml'
FTLSCMPSST='footloose_start.yml'
FTLSCMPSSP='footloose_stop.yml'
FTLSCMPSDL='footloose_delete.yml'
FTLSCNFGFL='footloose.yaml'
RQRDCMNDS="awk
           cat
           chmod
           date
           docker
           docker-compose
           grep
           pwd
	   rm
           sort
           uname
           tee
           wc"

preReq() {

  for c in ${RQRDCMNDS}
  do
    if ! command -v "${c}" > /dev/null 2>&1
    then
      echo " Error: required command ${c} not found, exiting ..."
      exit -1
    fi
  done

  if ! docker network ls | grep "${FTLSNTWRK}" 2>&1 > /dev/null
  then
    if ! docker network create "${FTLSNTWRK}"
    then
      echo " Error: docker network create ${FTLSNTWRK} failed, exiting ..."
      exit -1
    fi
  fi

  export COMPOSE_IGNORE_ORPHANS=1

}

exitOnErr() {

  echo " Error: <$(date)> $1, exiting ..."
  exit 1

}

printUsage() {

  cat <<EOF
 Usage: $(basename $0) < create|buildcreate|start|stop|show|
                         test [ping|goss|consulserver|consulclient|
                               consulesm|hashiui|consultemplate|docker|
                               cassandra|elasticsearch|kafka|spark|
                               monitoror|testinfra|vigil]
                        |delete|cleandelete|config >"
EOF
  exit 0

}

parseArgs() {

  if [[ $# -gt ${NUMOPTNMX} ]]
  then
    printUsage
  fi

  if [[ "${OPTN}" != "create" ]] && \
     [[ "${OPTN}" != "buildcreate" ]] && \
     [[ "${OPTN}" != "start" ]] && \
     [[ "${OPTN}" != "stop" ]] && \
     [[ "${OPTN}" != "show" ]] && \
     [[ "${OPTN}" != "test" ]] && \
     [[ "${OPTN}" != "delete" ]] && \
     [[ "${OPTN}" != "cleandelete" ]] && \
     [[ "${OPTN}" != "config" ]]

  then
    printUsage
  fi

}

showFTLStack() {

  if ! docker run -it --rm -v /var/run/docker.sock:/var/run/docker.sock:ro \
                           -v $(pwd)/footloose.cfg:/etc/footloose.cfg:ro \
            footloose show
  then
    exitOnErr 'docker run footloose show failed'
  fi

}

createASBLInv() {

  local ftlshw=$(docker run -it --rm -v /var/run/docker.sock:/var/run/docker.sock:ro -v $(pwd)/footloose.cfg:/etc/footloose.cfg:ro footloose show|grep '^cluster\-')
#       grep -v NAME | awk -F '  +' '{ if ( $4~"^ubuntu" ) {print $2,"ansible_python_interpreter=/usr/bin/python3"} else {print $2} }'> "${ANSBLEDIR}/${ANSBLEHIN}"
  for h in $(echo "${ftlshw}" | grep -v NAME | awk -F '  +' '{print $2}'|sed 's/[0-9]\{1,\}//'|sort -u)
  do
    echo -e "[${h}]\n$(echo "${ftlshw}" | grep "${h}" \
       | awk -F '  +' '{print $2}')\n"
  done | tee "${ANSBLEDIR}/${ANSBLEHIN}"

}

renderVGLCnfg() {

  tee "${SRVCNFGVGL}" <<EOF
[server]

log_level = "debug"
inet = "0.0.0.0:8080"
workers = 4
reporter_token = "REPLACE_THIS_WITH_A_SECRET_KEY"

[assets]

path = "./res/assets/"

[branding]

page_title = "CloudInABox Status"
page_url = "https://richnusgeeks.com/"
company_name = "RNG"
icon_color = "#1972F5"
icon_url = "https://avatars0.githubusercontent.com/u/226598?s=60&v=4"
logo_color = "#1972F5"
logo_url = "https://avatars0.githubusercontent.com/u/226598?s=60&v=4"
website_url = "https://richnusgeeks.com/"
support_url = "mailto:richnusgeeks@gmail.com"
custom_html = ""

[metrics]

poll_interval = 10
poll_retry = 2

poll_http_status_healthy_above = 200
poll_http_status_healthy_below = 400

poll_delay_dead = 30
poll_delay_sick = 10

push_delay_dead = 20

push_system_cpu_sick_above = 0.90
push_system_ram_sick_above = 0.90

script_interval = 300

local_delay_dead = 40

[notify]

startup_notification = true
reminder_interval = 300

[notify.email]

from = "status@crisp.chat"
to = "status@crisp.chat"

smtp_host = "localhost"
smtp_port = 587
smtp_username = "user-access"
smtp_password = "user-password"
smtp_encrypt = false

[notify.slack]

hook_url = "https://hooks.slack.com/services/xxxx"
mention_channel = true


EOF

}

renderMTRCnfg() {

  true

}

copyPrivKey() {

  if ! docker cp "footloosecreate:${FTLSCTDIR}/${FTLSCTRKY}" "${ANSBLEDIR}"
  then
    exitOnErr "docker cp footloosecreate:${FTLSCTDIR}/${FTLSCTRKY} ${ANSBLEDIR} failed"
  else
    if uname | grep -i darwin 2>&1 > /dev/null
    then
      PRMSN='0400'
    else
      PRMSN='+r'
    fi

    if ! chmod "${PRMSN}" "${ANSBLEDIR}/${FTLSCTRKY}"
    then
      exitOnErr "chmod ${PRMSN} ${ANSBLEDIR}/${FTLSCTRKY} failed"
    fi
  fi

}

testASBLRun() {

  if [[ ! -z "${1}" ]] && \
     [[ "${1}" != "ping" ]] && \
     [[ "${1}" != "consulserver" ]] && \
     [[ "${1}" != "consulclient" ]] && \
     [[ "${1}" != "consultemplate" ]] && \
     [[ "${1}" != "consulesm" ]] && \
     [[ "${1}" != "hashiui" ]] && \
     [[ "${1}" != "goss" ]] && \
     [[ "${1}" != "docker" ]] && \
     [[ "${1}" != "cassandra" ]] && \
     [[ "${1}" != "elasticsearch" ]] && \
     [[ "${1}" != "kafka" ]] && \
     [[ "${1}" != "monitoror" ]] && \
     [[ "${1}" != "testinfra" ]] && \
     [[ "${1}" != "vigil" ]] && \
     [[ "${1}" != "spark" ]]

  then
    printUsage
  fi

  createASBLInv
  copyPrivKey

  if [[ -z "${1}" ]] || [[ "${1}" = "ping" ]]
  then
    if ! docker-compose -f "${CMPSFLDIR}/${ASBLCMTEST}" up --build
    then
      exitOnErr "docker-compose -f ${CMPSFLDIR}/${ASBLCMTEST} up --build failed"
    fi

  elif [[ "${1}" = "consulserver" ]]
  then
    if ! docker-compose -f "${CMPSFLDIR}/${ASBLCMCSRV}" up --build
    then
      exitOnErr "docker-compose -f ${CMPSFLDIR}/${ASBLCMCSRV} up --build failed"
    fi

  elif [[ "${1}" = "consulclient" ]]
  then
    if ! docker-compose -f "${CMPSFLDIR}/${ASBLCMCLNT}" up --build
    then
      exitOnErr "docker-compose -f ${CMPSFLDIR}/${ASBLCMCLNT} up --build failed"
    fi

  elif [[ "${1}" = "consulesm" ]]
  then
    if ! docker-compose -f "${CMPSFLDIR}/${ASBLCMCESM}" up --build
    then
      exitOnErr "docker-compose -f ${CMPSFLDIR}/${ASBLCMCESM} up --build failed"
    fi

  elif [[ "${1}" = "hashiui" ]]
  then
    if ! docker-compose -f "${CMPSFLDIR}/${ASBLCMHSUI}" up --build
    then
      exitOnErr "docker-compose -f ${CMPSFLDIR}/${ASBLCMHSUI} up --build failed"
    fi

  elif [[ "${1}" = "consultemplate" ]]
  then
    if ! docker-compose -f "${CMPSFLDIR}/${ASBLCMCTPL}" up --build
    then
      exitOnErr "docker-compose -f ${CMPSFLDIR}/${ASBLCMCTPL} up --build failed"
    fi

  elif [[ "${1}" = "goss" ]]
  then
    if ! docker-compose -f "${CMPSFLDIR}/${ASBLCMDGOS}" up --build
    then
      exitOnErr "docker-compose -f ${CMPSFLDIR}/${ASBLCMDGOS} up --build failed"
    fi

  elif [[ "${1}" = "docker" ]]
  then
    if ! docker-compose -f "${CMPSFLDIR}/${ASBLCMDCKR}" up --build
    then
      exitOnErr "docker-compose -f ${CMPSFLDIR}/${ASBLCMDCKR} up --build failed"
    fi

  elif [[ "${1}" = "cassandra" ]]
  then
    if ! docker-compose -f "${CMPSFLDIR}/${ASBLCMDCAS}" up --build
    then
      exitOnErr "docker-compose -f ${CMPSFLDIR}/${ASBLCMDCAS} up --build failed"
    fi
  elif [[ "${1}" = "elasticsearch" ]]
  then
    if ! docker-compose -f "${CMPSFLDIR}/${ASBLCMDELS}" up --build
    then
      exitOnErr "docker-compose -f ${CMPSFLDIR}/${ASBLCMDELS} up --build failed"
    fi
  elif [[ "${1}" = "kafka" ]]
  then
    if ! docker-compose -f "${CMPSFLDIR}/${ASBLCMDKAF}" up --build
    then
      exitOnErr "docker-compose -f ${CMPSFLDIR}/${ASBLCMDKAF} up --build failed"
    fi
  elif [[ "${1}" = "monitoror" ]]
  then
    renderMTRCnfg
    if ! docker-compose -f "${CMPSFLDIR}/${ASBLCMPMTR}" up --build
    then
      exitOnErr "docker-compose -f ${CMPSFLDIR}/${ASBLCMPMTR} up --build failed"
    fi
  elif [[ "${1}" = "testinfra" ]]
  then
    if ! docker-compose -f "${CMPSFLDIR}/${DCKRCMPTIR}" up --build -d
    then
      exitOnErr "docker-compose -f ${CMPSFLDIR}/${DCKRCMPTIR} up -d failed"
    else

      if uname | grep -i darwin 2>&1 > /dev/null
      then
        local nload=$(sysctl -a 2>&1|grep machdep.cpu.core_count|awk '{print $NF}')
      else
        local nload=$(grep -w core /proc/cpuinfo 2>&1|wc -l)
      fi

      if [[ -n ${nload} ]]
      then
        if [[ ${nload} -gt 4 ]]
        then
          nload=4
        fi
      else
        nload=2
      fi
      docker exec -it testinfra py.test -n ${nload} \
	          --force-ansible \
	          --hosts='ansible://all' \
		  test_myinfra.py
    fi
  elif [[ "${1}" = "vigil" ]]
  then
    renderVGLCnfg
    if ! docker-compose -f "${CMPSFLDIR}/${ASBLCMPVGL}" up --build
    then
      exitOnErr "docker-compose -f ${CMPSFLDIR}/${ASBLCMPVGL} up --build failed"
    fi
  elif [[ "${1}" = "spark" ]]
  then
    if ! docker-compose -f "${CMPSFLDIR}/${ASBLCMDSPR}" up --build
    then
      exitOnErr "docker-compose -f "${CMPSFLDIR}/${ASBLCMDSPR}" up --build failed"
    fi
  fi

}

showAndTest() {

  showFTLStack
  sleep "${DLYTOMSTL}"
  echo
  testASBLRun "${1}"

}

main() {

  parseArgs

  preReq

  if [[ "${OPTN}" = "create" ]]
  then
    docker-compose -f "${CMPSFLDIR}/${FTLSCMPSCT}" up -d
    showAndTest "${OPTNTST}"
  elif [[ "${OPTN}" = "buildcreate" ]]
  then
    docker-compose -f "${CMPSFLDIR}/${FTLSCMPSCT}" up --build -d
    showAndTest "${OPTNTST}"
  elif [[ "${OPTN}" = "start" ]]
  then
    docker-compose -f "${CMPSFLDIR}/${FTLSCMPSST}" up
    showAndTest "${OPTNTST}"
  elif [[ "${OPTN}" = "stop" ]]
  then
    docker-compose -f "${CMPSFLDIR}/${FTLSCMPSSP}" up
    showFTLStack
  elif [[ "${OPTN}" = "delete" ]]
  then
    docker-compose -f "${CMPSFLDIR}/${FTLSCMPSDL}" up
    docker-compose -f "${CMPSFLDIR}/${FTLSCMPSDL}" down
    docker-compose -f "${CMPSFLDIR}/${FTLSCMPSCT}" down
    docker-compose -f "${CMPSFLDIR}/${DCKRCMPMTR}" down
    docker-compose -f "${CMPSFLDIR}/${DCKRCMPTIR}" down
    docker-compose -f "${CMPSFLDIR}/${DCKRCMPVGL}" down
    docker network rm "${FTLSNTWRK}"
    rm -f "${FTLSCTRKY}" "${FTLSCNFGFL}" \
	  "${ANSBLEDIR}/${FTLSCTRKY}" "${ANSBLEDIR}/${ANSBLEHIN}"
    showFTLStack
  elif [[ "${OPTN}" = "cleandelete" ]]
  then
    docker-compose -f "${CMPSFLDIR}/${FTLSCMPSDL}" up
    docker-compose -f "${CMPSFLDIR}/${FTLSCMPSDL}" down -v
    docker-compose -f "${CMPSFLDIR}/${FTLSCMPSCT}" down
    docker-compose -f "${CMPSFLDIR}/${DCKRCMPMTR}" down
    docker-compose -f "${CMPSFLDIR}/${DCKRCMPTIR}" down
    docker-compose -f "${CMPSFLDIR}/${DCKRCMPVGL}" down
    docker network rm "${FTLSNTWRK}"
    rm -f "${FTLSCTRKY}" "${FTLSCNFGFL}" \
	  "${ANSBLEDIR}/${FTLSCTRKY}" "${ANSBLEDIR}/${ANSBLEHIN}"
    showFTLStack
  elif [[ "${OPTN}" = "test" ]]
  then
    showAndTest "${OPTNTST}"
  elif [[ "${OPTN}" = "show" ]]
  then
    showFTLStack
  elif [[ "${OPTN}" = "config" ]]
  then
    showFTLStack|sed -n '/^cluster:/,/^NAME/p'|grep -v NAME > "${FTLSCNFGFL}"
  fi

}

main 2>&1
# ./create_container_machines_stack.sh show|grep kafka|awk -F '{8080' '{print $2}'|awk -F '}' '{print $1}'|sed 's/ *//'|sort -n|xargs -I % nc -vz localhost %
# ./create_container_machines_stack.sh show|sed -n '/^cluster:/,/^NAME/p'|grep -v NAME > footloose.yaml
