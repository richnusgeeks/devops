#! /usr/bin/env python

from sys import argv
from time import sleep
import random
import hazelcast

if len(argv) != 5:
    print(" Usage: %s <ConnectionString e.g. hzhost1:port,hzhost2:port,...> <GroupName> <GroupPswrd> <NumOfKeys e.g. 100000>" %argv[0])
    exit(1)

connstr = argv[1]
grpname = argv[2]
grppswd = argv[3]
numkeys = int(argv[4])

config = hazelcast.ClientConfig()
config.group_config.name = grpname
config.group_config.password = grppswd
for hp in connstr.split(','):
  config.network_config.addresses.append(hp)
client = hazelcast.HazelcastClient(config)

if numkeys > 0:
  m = client.get_map("smoketest")
  for k in xrange(1, numkeys+1):
    m.put("%s" %k, random.randint(1,numkeys))

  for c in xrange(10):
    lock = client.get_lock("smoketestlock").blocking()
    lock.lock()
    try:
      print(" locking %d time" %(int(c)+1))
      sleep(1)
    finally:
      lock.unlock()

client.shutdown()
