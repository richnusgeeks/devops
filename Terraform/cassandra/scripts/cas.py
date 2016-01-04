from time import sleep
from fabric.api import env, sudo, run, get, put, local
from fabric.decorators import hosts, roles, parallel

env.user = "ubuntu"
env.key_filename = "<Private Key>"	       
env.warn_only = True
env.skip_bad_hosts = True
env.connection_attempts = 3
env.abort_on_prompts = True

def postCAS(dump=False):
  if not dump:
    sudo("service dse start")
#  run("while true; do if ! nc -vz ${self.private_ip} 9042 9160 2>/dev/null; then sleep 5; else break; fi; done")
    run("sleep 20")
  run("nodetool status; nodetool info; nodetool tpstats; echo")
  sudo("netstat -nlptu | grep -E '(9042|9160)'")

def rmveCASNds():
  run("for u in $(nodetool status|grep DN|awk '{print $7}'); do nodetool removenode $u; nodetool removenode force; done")
