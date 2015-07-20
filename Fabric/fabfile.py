from time import sleep
from fabric.api import env, sudo, run, put
from fabric.decorators import hosts, roles, parallel

env.roledefs = {

}
	       
#env.user = 'ec2-user'
#env.key_filename = 'CIP_KEY_PAIR.pem'
env.warn_only = True
env.skip_bad_hosts = True
env.connection_attempts = 3

@roles(
      )
def dumpRDS():
    env.user = 'ec2-user'
    env.key_filename = 'CIP_KEY_PAIR.pem'
    sudo('netstat -nlptu | grep redis | sort')
    sudo('netstat -nlptu | grep redis | wc -l')
    sudo('service iptables status')
    run('chkconfig --list iptables')
    run('df -kh')
    run('/usr/local/bin/redis-server -v')	
    run('ls -lhrt /redis[1-9]*')
    run('ls -lhrt /etc/redis/redis[1-9]*')
    run('ls -lhrt /etc/redis/rds*')
    run('ls -lhrt /etc/cron.hourly')
    run('grep -E \'^#save\' /etc/redis/redis[1-9]*')
    run('grep -E \'^ *dir\' /etc/redis/redis[1-9]*')
    run('grep -E \'^ *port\' /etc/redis/redis[1-9]*')
    run('grep -E \'^ *tcp-keepalive\' /etc/redis/redis[1-9]*')
    run('grep -E \'^ *hash-max-ziplist-entries\' /etc/redis/redis[1-9]*')
    run('grep -E \'^ *hash-max-ziplist-value\' /etc/redis/redis[1-9]*')
    run('grep -E \'^ *logfile\' /etc/redis/redis[1-9]*')

@roles(
      )
def dumpMCB():
    sudo('service iptables status')
    run('chkconfig --list iptables')
    run('df -kh')
    run('rpm -qa \'*couchbase*\'')
    run('chkconfig --list couchbase-server')
    sudo("netstat -nlptu | grep -E '(4369|8091|8092)'")
    sudo("netstat -nlptu | grep '112[0-1][0-9]'")
    sudo("netstat -nlptu | grep '211[0-9][0-9]'")
    sudo("/opt/couchbase/bin/couchbase-cli server-info -c localhost -u Administrator -p 'd3vu$er'")
    sudo("/opt/couchbase/bin/couchbase-cli bucket-list -c localhost -u Administrator -p 'd3vu$er'")

@roles(
      )
def dumpHAP():
    sudo('service iptables status')
    run('chkconfig --list iptables')
    run('df -kh')
    run('status haproxy')
    run("cat /etc/haproxy/haproxy.cfg | grep -Ei 'timeout (connect|client|server)'")
    run("cat /etc/haproxy/haproxy.cfg | grep -Ei 'httpchk'")
    run("cat /etc/rsyslog.d/*haproxy*'")
    run("cat /etc/logrotate.d/*haproxy*'")

@roles(
      )
def dumpPGR():
    sudo('service postgresql-9.2 status')
    run('chkconfig --list postgresql-9.2')
    run('df -kh')
    run('rpm -qa \'*postgresql*-server*\'')

@roles(
      )
def dumpPGP():
    run('df -kh')

@roles(
      )
def dumpMSG():
    sudo('service iptables status')
    run('chkconfig --list iptables')
    run('df -kh')
    run('rpm -qa \'*rabbit*\'')
    run('chkconfig --list rabbitmq-server')
    sudo("netstat -nlptu | grep beam")
    sudo("netstat -nlptu | grep epmd")
    sudo('service rabbitmq-server status')
    sudo("/usr/sbin/rabbitmqctl cluster_status")
    #sudo("/usr/sbin/rabbitmqctl report")

@roles(
      )
def lgrtteHAP():
    sudo("echo '/var/log/haproxy*.log' > /etc/logrotate.d/haproxy")	
    sudo("echo '{' >> /etc/logrotate.d/haproxy")	
    sudo("echo '    rotate 4' >> /etc/logrotate.d/haproxy")	
    sudo("echo '    weekly' >> /etc/logrotate.d/haproxy")	
    sudo("echo '    missingok' >> /etc/logrotate.d/haproxy")	
    sudo("echo '    notifempty' >> /etc/logrotate.d/haproxy")	
    sudo("echo '    compress' >> /etc/logrotate.d/haproxy")	
    sudo("echo '    delaycompress' >> /etc/logrotate.d/haproxy")	
    sudo("echo '    sharedscripts' >> /etc/logrotate.d/haproxy")	
    sudo("echo '    postrotate' >> /etc/logrotate.d/haproxy")	
    sudo("echo '        reload rsyslog >/dev/null 2>&1 || true' >> /etc/logrotate.d/haproxy")	
    sudo("echo '    endscript' >> /etc/logrotate.d/haproxy")	
    sudo("echo '}' >> /etc/logrotate.d/haproxy")
    run('ls -lhrt /etc/logrotate.d/haproxy')
    run('cat /etc/logrotate.d/haproxy')

@roles(
      )		
def dumpRMQ():    
    sudo('/usr/sbin/rabbitmqctl list_vhosts')

def provMGF():
    put(r'instl-cnfgr-mgf.sh', '/tmp')
    run('sleep 5')
    sudo('cd /tmp && bash instl-cnfgr-mgf.sh -a')

def setupMGF(mgfip2, mgfip3, mgfip4):
    run("echo 'NODESIPS = %s %s %s' > /tmp/glusterfs.conf" %(mgfip2,mgfip3,mgfip4))    
    run('sleep 5')
    sudo('cd /tmp && bash instl-cnfgr-mgf.sh -e')

def setupMGFClnt(mgfip1):
    put(r'D:\Development\NGCommon\Main\AWSScripts\LinuxRolesSetupScripts\GlusterFS\instl-cnfgr-mgf-client.sh', '/tmp')
    run('sleep 5')
    sudo('cd /tmp && bash instl-cnfgr-mgf-client.sh -a')
    run("echo 'NODESIPS = %s' > /tmp/glusterfs.conf" %mgfip1)
    run('sleep 5')
    sudo('cd /tmp && bash instl-cnfgr-mgf-client.sh -e')

def provZCB():
    put(r'instl-cnfgr-couchbase-zcb.sh', '/tmp')
    run('sleep 5')
    sudo('cd /tmp && bash instl-cnfgr-couchbase-zcb.sh -a')

def clstrZCB(zcbip2, zcbip3):
    run("echo 'ZCB2.qaf3 %s' > /tmp/nodes2add.conf" %zcbip2)    
    run("echo 'ZCB3.qaf3 %s' >> /tmp/nodes2add.conf" %zcbip3)    
    run('sleep 5')
    sudo('cd /tmp && bash instl-cnfgr-couchbase-zcb.sh -r')

def cleanZCB():
    sudo('rpm -e couchbase-server-2.1.1-764.x86_64')
    run('sleep 5')
    sudo('rm -rf /opt/couchbase')
    sudo('rm -rf /tmp/instl-cnfgr-couchbase-zcb.sh')

def provRDR():
    put(r'D:\Development\NGCommon\Main\AWSScripts\LinuxRolesSetupScripts\Redis\SWLab\instl-cnfgr-rdr.sh', '/tmp')
    run('sleep 5')
    sudo('cd /tmp && bash instl-cnfgr-rdr.sh -a')

def clstrRDR(mstrip):
    run("echo 'MASTER = %s' > /tmp/slave.conf" %mstrip)
    run('sleep 5')
    sudo('cd /tmp && bash instl-cnfgr-rdr.sh -e')

def hapRDR():
    put(r'instl-cnfgr-haproxy.sh', '/tmp')
    run('sleep 5')
    put(r'haproxy.roles', '/tmp')
    run('sleep 5')
    sudo('cd /tmp && bash instl-cnfgr-haproxy.sh -a')
    run('sleep 5')
    sudo('cd /tmp && bash instl-cnfgr-haproxy.sh -e')

@roles(
)
def ipsVIP(vip = None):
    run('hostname')
    run("ifconfig | grep 'inet *addr' | awk -F \":\" '{print $2}' | grep -v '127.0.0.1'")
    run('service haproxy status')
    run("sed -n '/^ *virtual_ipaddress/,/}/p' /etc/keepalived/keepalived.conf")
    run("sed -n '/^ *backend/,/^ *$/p' /etc/haproxy/haproxy.cfg")
    if not vip:    
        run("sed -n '/^ *virtual_ipaddress/,/}/p' /etc/keepalived/keepalived.conf")
    else:	
        run("sed -n '/^ *virtual_ipaddress/,/}/p' /etc/keepalived/keepalived.conf | grep %s" %vip)

def provLPG():
    put(r'D:\Development\NGCommon\Main\AWSScripts\LinuxRolesSetupScripts\PgSqlGis\postgresql92-9.2.5-1PGDG.rhel6.x86_64.rpm', '/tmp')
    put(r'D:\Development\NGCommon\Main\AWSScripts\LinuxRolesSetupScripts\PgSqlGis\postgresql92-libs-9.2.5-1PGDG.rhel6.x86_64.rpm', '/tmp')
    put(r'D:\Development\NGCommon\Main\AWSScripts\LinuxRolesSetupScripts\PgSqlGis\postgresql92-server-9.2.5-1PGDG.rhel6.x86_64.rpm', '/tmp')
    run('sleep 5')
    put(r'D:\Development\NGCommon\Main\AWSScripts\LinuxRolesSetupScripts\PgSqlGis\SWLab\instl-cnfgr-lpg.sh', '/tmp')
    run('sleep 5')
    sudo('cd /tmp && bash instl-cnfgr-lpg.sh -a')

def provLPP():
    put(r'D:\Development\NGCommon\Main\AWSScripts\LinuxRolesSetupScripts\PgPool\SWLab\instl-cnfgr-pgpool.sh', '/tmp')
    run('sleep 5')
    sudo('cd /tmp && bash instl-cnfgr-pgpool.sh -a')    	

def recnfLPP(lpgip1, lpgip2 = None):
    run("echo 'LPG1 %s 5432 1' > /tmp/pgpool.nodes" %lpgip1)
    if lpgip2:
        run("echo 'LPG2 %s 5432 1' >> /tmp/pgpool.nodes" %lpgip2)
    run('sleep 5')
    sudo('cd /tmp && bash instl-cnfgr-pgpool.sh -e')

def provPGR():
    put(r'D:\Development\NGCommon\Main\AWSScripts\LinuxRolesSetupScripts\PgSqlGis\SWLab\instl-cnfgr-pgr.sh', '/tmp')
    run('sleep 5')
    sudo('cd /tmp && bash instl-cnfgr-pgr.sh -a')

def recnfPGR():
    put(r'D:\Development\NGGISData\Main\Postgres\postgis_central.sql', '/tmp')
    run('sleep 5')
    sudo('cd /tmp && bash instl-cnfgr-pgr.sh -e')

def provELS():
    put(r'jdk-7u45-linux-x64.rpm', '/tmp')
    put(r'instl-cnfgr-els.sh', '/tmp')
    run('sleep 5')
    sudo('cd /tmp && bash instl-cnfgr-els.sh -a')  	

def recnfELS():
    put(r'elasticsearch.conf', '/tmp')
    run('sleep 5')
    sudo('cd /tmp && bash instl-cnfgr-els.sh -e')

def provMAPL():
    put(r'instl-cnfgr-map.sh', '/tmp')
    run('sleep 5')
    put(r'postgismapniktest.py', '/tmp')
    run('sleep 5')
    sudo('cd /tmp && bash instl-cnfgr-map.sh -a')

def provMMS():
    put(r'mms-monitoring-agent.tar.gz', '/tmp')
    run('sleep 5')
    put(r'instl-cnfgr-mmsagent.sh', '/tmp')
    run('sleep 5')
    sudo('cd /tmp && bash instl-cnfgr-mmsagent.sh -a')

@roles(
)
#@with_settings(warn_only=True)	
def dumpRPLMG():
    run('df -kh')	
    sudo('service mongod status')

@roles(
)
def dumpHAP():
    run('df -kh')
    run("rpm -qa 'keepalive*'")
    sudo('service keepalived status')	
    sudo('service haproxy status')
    sudo('cat /etc/haproxy/haproxy.cfg')

@roles(
)
def dumpKAI():
    sudo("sed -n '/virtual_ipaddress/,/\}/p' /etc/keepalived/keepalived.conf")

@roles(
)
def raiseFileMax(revert=False, dump=False):
    if not dump:
        sudo("sed -i '/^ *fs\.file-max/d' /etc/sysctl.conf")	
        sudo("echo '' >> /etc/sysctl.conf")
        sudo("echo 'fs.file-max = 262144' >> /etc/sysctl.conf")
        sudo('sysctl -e -p')
        sudo("sed -i '/^ *\* soft nofile/d' /etc/security/limits.conf")	
        sudo("echo '' >> /etc/sysctl.conf")
        sudo("echo '* soft nofile 262144' >> /etc/security/limits.conf")	
        sudo("sed -i '/^ *\* hard nofile/d' /etc/security/limits.conf")	
        sudo("echo '' >> /etc/sysctl.conf")
        sudo("echo '* hard nofile 262144' >> /etc/security/limits.conf")
    run("grep -i '^ *fs.file-max' /etc/sysctl.conf")	    
    run("grep -i '^ *\* soft nofile' /etc/security/limits.conf")	    
    run("grep -i '^ *\* hard nofile' /etc/security/limits.conf")	    
    sudo('sysctl -e -a | grep file-max')
    run('ulimit -n')
    sudo("service elasticsearch status")
    if not dump:
        sudo('reboot')	

@roles(
)
def dumpELS():
    run("df -kh")
    sudo("service elasticsearch status")
    run("rpm -qa 'elastic*'")
    run('ulimit -n')
    run("grep '^ *node.data' /etc/elasticsearch/elasticsearch.yml")	
    run("grep '^ *node.master' /etc/elasticsearch/elasticsearch.yml")	
    run("grep '^ *node.client' /etc/elasticsearch/elasticsearch.yml")	
    run("grep 'multicast.enabled' /etc/elasticsearch/elasticsearch.yml")	
    run("grep 'multicast.group' /etc/elasticsearch/elasticsearch.yml")	
    run("grep 'zen.minimum' /etc/elasticsearch/elasticsearch.yml")
    run("grep 'discovery.zen.ping.unicast.hosts' /etc/elasticsearch/elasticsearch.yml")
    run("grep '9200: true' /etc/elasticsearch/elasticsearch.yml")
    #run("grep '^ *marvel.agent.exporter.es.hosts' /etc/elasticsearch/elasticsearch.yml")  
    #run("grep '^ *marvel.agent.enabled' /etc/elasticsearch/elasticsearch.yml")  
    run('grep cluster /etc/elasticsearch/elasticsearch.yml')
    run("grep '^ *threadpool.bulk.size' /etc/elasticsearch/elasticsearch.yml")	
    run("grep '^ *threadpool.bulk.queue_size' /etc/elasticsearch/elasticsearch.yml")	
    sudo('ls -lhrt /usr/share/elasticsearch/plugins/action-updatebyquery/')
    #sudo('md5sum /usr/share/elasticsearch/plugins/action-updatebyquery/*jar*')
    run('/usr/share/elasticsearch/bin/plugin -l')

    #run('grep multicast /etc/elasticsearch/elasticsearch.yml')

@roles(
)
def patchNGNX():
    run('service haproxy status')	
    run('service keepalived status')	
    run('service nginx status')	
    run("sed -n '/^ *proxy_.\{1,\}_timeout/p' /etc/nginx/nginx.conf")

@roles(
)
def dumpMONGO():
    run('df -kh')
    run('cat /etc/fstab')
    sudo('fdisk -l')

@roles(
)
def dumpMongo():
    #sudo('mongod --fork --dbpath /mnt/data --logpath /var/log/mongodb/mongodb.log')	
    run('df -kh')
    run('ps aux | grep mongo')
    sudo('service mongod status')
    run("mongo --eval 'printjson(rs.status())'")
    run("mongo --eval 'printjson(db.hostInfo())'")
    #sudo('du -sh /mnt/data/*rdb*')

@roles(
)
def patchELS4Unicast():
    sudo("sed -i '/^ *discovery.zen.ping.multicast.enabled: *true/s/true/false/' /etc/elasticsearch/elasticsearch.yml")
    sudo("sed -i '/^ *discovery.zen.ping.multicast.group/d' /etc/elasticsearch/elasticsearch.yml")
    sudo("sed -i '/^ *discovery.zen.minimum_master_nodes/d' /etc/elasticsearch/elasticsearch.yml")
    sudo("sed -i '/^ *discovery.zen.ping.unicast.hosts/d' /etc/elasticsearch/elasticsearch.yml")
    sudo("echo '' >> /etc/elasticsearch/elasticsearch.yml")
    sudo("echo 'discovery.zen.minimum_master_nodes: 2' >> /etc/elasticsearch/elasticsearch.yml")
    sudo("echo '' >> /etc/elasticsearch/elasticsearch.yml")
    sudo("echo 'discovery.zen.ping.unicast.hosts: [\"\",\"\",\"\"]' >> /etc/elasticsearch/elasticsearch.yml")
    run("grep '^ *node.data' /etc/elasticsearch/elasticsearch.yml")	
    run("grep '^ *node.master' /etc/elasticsearch/elasticsearch.yml")	
    run("grep '^ *node.client' /etc/elasticsearch/elasticsearch.yml")	
    run("grep 'multicast.enabled' /etc/elasticsearch/elasticsearch.yml")	
    run("grep 'multicast.group' /etc/elasticsearch/elasticsearch.yml")	
    run("grep 'zen.minimum' /etc/elasticsearch/elasticsearch.yml")	
    run("grep '^discovery.zen.ping.unicast.hosts' /etc/elasticsearch/elasticsearch.yml")
    sudo("service elasticsearch restart")

@roles(
)
def patchELS4Marvel(marvel=False, *mrvlclstr):
    #put(r'elasticsearch-0.90.11.noarch.rpm', '/tmp')
    #run('sleep 5')
    #sudo('cd /tmp && rpm -Uvh elasticsearch-0.90.11.noarch.rpm')    
    #run('sleep 10')
    #run("rpm -qa 'elasticsearch*'")

    if marvel:
        put(r'marvel-latest.zip', '/tmp')
        run('sleep 5')
        sudo(r'/usr/share/elasticsearch/bin/plugin -i marvel -u file://localhost/tmp/marvel-latest.zip')

        if len(mrvlclstr):
            sudo("sed -i '/^ *marvel.agent.exporter.es.hosts/d' /etc/elasticsearch/elasticsearch.yml")
            sudo("echo '' >> /etc/elasticsearch/elasticsearch.yml")
            sudo("echo 'marvel.agent.exporter.es.hosts: [\"%s:9200\"]' >> /etc/elasticsearch/elasticsearch.yml" %mrvlclstr)
            run("grep '^ *marvel.agent.exporter.es.hosts' /etc/elasticsearch/elasticsearch.yml")
            sudo('service elasticsearch restart')	

@roles(
)
def patchELS4NewStngs():
    sudo("sed -i '/^ *action.disable_delete_all_indices:/d' /etc/elasticsearch/elasticsearch.yml")
    sudo("echo '' >> /etc/elasticsearch/elasticsearch.yml")
    sudo("echo 'action.disable_delete_all_indices: true' >> /etc/elasticsearch/elasticsearch.yml")
    sudo("sed -i '/^ index.fielddata.cache:*/d' /etc/elasticsearch/elasticsearch.yml")
    sudo("echo '' >> /etc/elasticsearch/elasticsearch.yml")
    sudo("echo 'index.fielddata.cache: soft' >> /etc/elasticsearch/elasticsearch.yml")
    sudo('service elasticsearch restart')

@roles(
)
def restartELS():
    sudo('service elasticsearch restart')

@roles(
)
def tuneJVMHeap():
    sudo('sed -i "/^ *export ES_JAVA_OPTS/s/ES_JAVA_OPTS/ES_JAVA_OPTS=\'-Xms40G -Xmx40G\'/" /etc/init.d/elasticsearch') 	
    sudo('service elasticsearch restart')

@roles(
)
def loginTest():
    sudo('echo $HOME')

@roles(
)
def patch4ELSPlgn141():
    sudo('/usr/share/elasticsearch/bin/plugin -r action-updatebyquery')
    run('sleep 5')
    sudo('/usr/share/elasticsearch/bin/plugin -i com.yakaz.elasticsearch.plugins/elasticsearch-action-updatebyquery/1.4.1')
    run('sleep 5')
    sudo('service elasticsearch restart')

@roles(
)		
def createMarvelClstr():
    pass	

@roles(
)
def patchLPP():
    #run('df -kh')
    #sudo('service pgpool-II-92 status')
    #sudo('service pgpool-II-92 stop')
    #sudo("sed -i '/^ *num_init_children *=/d' /etc/pgpool-II-92/pgpool.conf")
    #sudo("echo 'num_init_children = 300' >> /etc/pgpool-II-92/pgpool.conf")
    #sudo("sed -i '/^ *client_idle_limit *=/d' /etc/pgpool-II-92/pgpool.conf")
    #sudo("echo 'client_idle_limit = 600' >> /etc/pgpool-II-92/pgpool.conf")
    #sudo('service pgpool-II-92 start')
    #run('sleep 15')
    #sudo('service pgpool-II-92 status')
    sudo("sed -i '/^ *load_balance_mode *=/d' /etc/pgpool-II-92/pgpool.conf")
    sudo("echo 'load_balance_mode = on' >> /etc/pgpool-II-92/pgpool.conf")
    sudo('service pgpool-II-92 stop')
    run('sleep 15')
    sudo('service pgpool-II-92 start')
    run('sleep 15')
    sudo('service pgpool-II-92 status')
    sudo("grep -Ew '(^ *num_init_children|^ *client_idle_limit)' /etc/pgpool-II-92/pgpool.conf")    
    sudo("grep -Ew '^ *load_balance_mode' /etc/pgpool-II-92/pgpool.conf")

@roles(
)
def patch4ELSPlgnRead():
    #sudo('service elasticsearch stop')
    #sudo('sleep 10')
    sudo('chmod a+rx /usr/share/elasticsearch/plugins/action-updatebyquery')	
    sudo('ls -lhrtd /usr/share/elasticsearch/plugins/action-updatebyquery')	
    sudo('service elasticsearch restart')

@roles(
)		
def test4Reach():
    run('df -kh')
    sudo('fdisk -l')

def stopLPP(tries=3, delay=5):
    for i in xrange(0, tries):
        if sudo('service pgpool-II-92 stop').failed:
            sleep(delay)
        else:
            break    
    run('sleep 10')
    
def startLPP(tries=3, delay=5):
    for i in xrange(0, tries):
        if sudo('service pgpool-II-92 start').failed:
            sleep(delay)
        else:
            break    

def dumpLPP():
    sudo('service pgpool-II-92 status')

def stopLPG(tries=3, delay=5):
    for i in xrange(0, tries):
        if sudo('service postgresql-9.2 stop').failed:
            sleep(delay)
        else:
            break    

    run('sleep 10')

def startLPG(tries=3, delay=5):
    for i in xrange(0, tries):
        if sudo('service postgresql-9.2 start').failed:
            sleep(delay)
        else:
            break    

def dumpLPG():
    sudo('service postgresql-9.2 status')

@roles(
)
def dumpVHW():
    run("df -kh")	
    run("grep -i '^ *memtotal' /proc/meminfo")
    #run("grep -i '^ *processor' /proc/cpuinfo")
    run('nproc')
    #run("grep -Ei '(ES_JAVA_OPTS|ES_HEAP_SIZE)' /etc/sysconfig/elasticsearch")
    sudo("fdisk -l")

@roles(
)
def raiseJVMHeap(heapmb):
    sudo("sed -i '/^ *ES_HEAP_SIZE/s/[0-9]\{1,\}/%s/' /etc/sysconfig/elasticsearch" %heapmb)
    sudo("sed -i '/^ *ES_JAVA_OPTS/s/[0-9]\{1,\}/%s/g' /etc/sysconfig/elasticsearch" %heapmb)
    sudo("service elasticsearch restart")
    run("grep -Ei '(ES_JAVA_OPTS|ES_HEAP_SIZE)' /etc/sysconfig/elasticsearch")

@roles(
)
def dumpHAA():
    sudo("grep timeout '/etc/haproxy/haproxy.cfg'")

@roles(
)
def patch4MongoDBPath():
  sudo("sed -i '/--dbpath/s/\/var\/lib\/mongodb/\/mnt\/data\/mongodb/' /etc/sysconfig/mongod")
  sudo("sed -i '/dbpath/s/\/var\/lib\/mongodb/\/mnt\/data\/mongodb/' /etc/mongod.conf")
  sudo("mkdir -p /mnt/data/mongodb")
  sudo("chown mongod:mongod /mnt/data/mongodb")
  sleep(5)
  sudo("service mongod restart")
  sleep(5)
  run("df -kh") 
  run("ls -lhrt /mnt/data")
  run("ps aux | grep mongo | grep -v grep")

@roles(
)
def patch4CouchbaseInit():
  put('/tmp/instl-cnfgr-couchbase-cipod.sh', '/tmp')
  put('/tmp/couchbase-server-community_x86_64_2.1.1.rpm', '/tmp')
  sudo("rpm -e couchbase-server-2.1.1-764.x86_64 kexec-tools-2.0.0-273.el6.x86_64")
  sleep(5)
  sudo("cd /tmp && sh instl-cnfgr-couchbase-cipod.sh -n")
  sleep(5)
  sudo("cd /tmp && sh instl-cnfgr-couchbase-cipod.sh -a")

@roles(
)
def rtrvChbPswrd():
  run('df -kh')
  sudo('/opt/couchbase/bin/erl -noinput -eval \'case file:read_file\("/opt/couchbase/var/lib/couchbase/config/config.dat"\) of {ok, B} -> io:format\("~p~n", [binary_to_term\(B\)]\) end.\' -run init stop | $GREP cred | $GREP pass")

@roles(
)
def getLPGs():
  sudo("grep '^ *backend_hostname' /var/lib/pgsql/9.2/data/postgresql.conf")
  sudo("grep '^ *backend_hostname' /etc/pgpool-II-92/pgpool.conf")

@roles(
)
def patchLPG4NewStngs():
  stngs = {
           "checkpoint_segments" : "50",
           "checkpoint_completion_target" : "0.9",
           "log_checkpoints" : "on",
           "log_connections" : "on",
           "log_disconnections" : "on",
           "log_lock_waits" : "on",
	   "log_line_prefix" : "%m %u@%d %p %r",
           "wal_level" : "archive",
           "max_wal_senders" : "5",
           "wal_keep_segments" : "200",		  
          }		  
  for k in stngs:
    sudo("sed -i '/^ *%s/d' /mnt/data/9.2/postgresql.conf" %k)
    if k == "log_line_prefix":
      sudo("echo \"%s = '%s'\" >> /mnt/data/9.2/postgresql.conf" %(k, stngs[k]))
    else:
      sudo("echo '%s = %s' >> /mnt/data/9.2/postgresql.conf" %(k, stngs[k]))
    sudo("grep -E '^ *%s' /mnt/data/9.2/postgresql.conf" %k)

  sudo("service postgresql-9.2 restart")
  run("sleep 5")
  sudo("service postgresql-9.2 status")

