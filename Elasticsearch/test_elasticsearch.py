#! /usr/bin/env python
############################################################################
# File name : test_elasticsearch.py
# Purpose : External scan for Elasticsearch cluster
# Usages : python test_elasticsearch.py <master with http enabled>
# Start date : 05/07/2014
# End date : mm/dd/2014
# Author : Ankur Kumar <richnusgeeks@gmail.com>
# Download link : www.richnusgeeks.me
# License : RichNusGeeks
# Version : 0.0.1
# Modification history : addition of best practices checks,Ankur 10/23/2015
# Notes : 
############################################################################

# <start of include section>
import requests as rest
from colorama import Fore, Back, Style, init, deinit
from sys import argv
# <end of include section>

# <start of global section>
if len(argv) == 1:
    print(" Usage: %s <elasticsearch client hosname(s)>" %argv[0])
    exit(1) 

if '-n' == argv[1]:
  colored = False
  clnts = argv[2:]
else:
  colored = True
  clnts = argv[1:]
port = 9200
health = '/_cluster/health'
state = '/_cluster/state'
nodes = '/_nodes'
elsver = '1.7.3'
minmstrs = 2
mindatas = 2
minnodes = minmstrs + mindatas
shrdsunasgn = 0
numrplcs = 1
numshrds = 5
numcores = 2
fldscrptrs = 64*1024 
colors = ('RED', 'GREEN', 'YELLOW',)
# <end of global section>

# <start of helper section>
def colorPrnt(msg, color="RED", colored=True):
    if colored and not color in colors:
        print(" Error: color is not among RED/GREEN/YELLOW !")
        return

    msgstr = ''
    if colored:
      if color.upper() == "RED":
        msgstr = Fore.RED + Style.BRIGHT + "%s"%msg
      elif color.upper() == "GREEN":
        msgstr = Fore.GREEN + Style.BRIGHT + "%s"%msg
      elif color.upper() == "YELLOW":
        msgstr = Fore.YELLOW + Style.BRIGHT + "%s"%msg
    else:
      msgstr = msg

    if msgstr:
      print msgstr
      if colored:
        print(Fore.RESET + Style.RESET_ALL),

def basicTest(client):

    try:
        r = rest.get("http://%s:%d%s" %(client, port, health))
        if 200 == r.status_code:
            h = r.json()

	    if 'red' == h['status']:
                colorPrnt("  ELS %s cluster state %s (expected %s) [FAIL]" %('red', h['cluster_name'],'green'), colored=colored)
            elif 'green' == h['status']:
                colorPrnt("  ELS %s cluster state green [PASS]" %h['cluster_name'], color="GREEN", colored=colored)
            elif 'yellow' == h['status']:
                colorPrnt("  ELS %s cluster state %s (expected %s) [WARN]" %(h['cluster_name'], 'yellow', 'green'), color="YELLOW", colored=colored)

            if minnodes > h['number_of_nodes']:
                colorPrnt("  ELS %s cluster total nodes %d (expected >= %d) [FAIL]" %(h['cluster_name'], h['number_of_nodes'], minnodes), colored=colored)
            else:
                colorPrnt("  ELS %s cluster total nodes %d [PASS]" %(h['cluster_name'], h['number_of_nodes']), color="GREEN", colored=colored)

            if mindatas > h['number_of_data_nodes']:
                colorPrnt("  ELS %s cluster data nodes %d (expected >= %d) [FAIL]" %(h['cluster_name'], h['number_of_data_nodes'], mindatas), colored=colored)
            else:
                colorPrnt("  ELS %s cluster data nodes %d [PASS]" %(h['cluster_name'], h['number_of_data_nodes']), color="GREEN", colored=colored)

            if shrdsunasgn < h['unassigned_shards']:
                colorPrnt("  ELS %s cluster unassigned_shards %d (expected %d) [FAIL]" %(h['cluster_name'], h['unassigned_shards'], shrdsunasgn), colored=colored)
            else:
                colorPrnt("  ELS %s cluster unassigned_shards %d [PASS]" %(h['cluster_name'], shrdsunasgn), color="GREEN", colored=colored)
     
            print    
    except Exception, e:
        colorPrnt(" %s" %str(e), colored=colored)
        print

def extendedTest(client):

    try:
        r = rest.get("http://%s:%d%s" %(client, port, nodes))
        if 200 == r.status_code:
          h = r.json()
          clstrnme = h['cluster_name']

        for n in h['nodes']:
          hstnme = h['nodes'][n]['host']

          if elsver != h['nodes'][n]['version']:
            colorPrnt("  ELS %s cluster version %s on %s (recommended %s) [WARN]"
              %(clstrnme, h['nodes'][n]['version'], hstnme, elsver), color="YELLOW", colored=colored)

          if numrplcs > int(h['nodes'][n]['settings']['index']['number_of_replicas']):
            colorPrnt("  ELS %s cluster number_of_replicas %s on %s (recommended >= %s) [WARN]"
              %(clstrnme, h['nodes'][n]['settings']['index']['number_of_replicas'], hstnme, numrplcs), color="YELLOW", colored=colored)
             
          if numshrds > int(h['nodes'][n]['settings']['index']['number_of_shards']):
            colorPrnt("  ELS %s cluster number_of_shards %s on %s (recommended >= %s) [WARN]"
              %(clstrnme, h['nodes'][n]['settings']['index']['number_of_shards'], hstnme, numshrds), color="YELLOW", colored=colored)

          if numcores > int(h['nodes'][n]['os']['cpu']['total_cores']):
            colorPrnt("  ELS %s cluster total_cores %s on %s (recommended >= %s) [WARN]"
              %(clstrnme, h['nodes'][n]['os']['cpu']['total_cores'], hstnme, numcores), color="YELLOW", colored=colored)

          heapmax = int(h['nodes'][n]['jvm']['mem']['heap_max_in_bytes'])
          totalmem = int(h['nodes'][n]['os']['mem']['total_in_bytes'])
          if heapmax != totalmem/2:
            colorPrnt("  ELS %s cluster heap_max_in_bytes %s on %s (recommended ~ %s) [WARN]"
              %(clstrnme, heapmax, hstnme, totalmem/2), color="YELLOW", colored=colored)

          if fldscrptrs != int(h['nodes'][n]['process']['max_file_descriptors']):
            colorPrnt("  ELS %s cluster max_file_descriptors %s on %s (recommended ~ %s) [WARN]"
              %(clstrnme, h['nodes'][n]['process']['max_file_descriptors'], hstnme, fldscrptrs), color="YELLOW", colored=colored)

          if not h['nodes'][n]['process']['mlockall']:
            colorPrnt("  ELS %s cluster mlockall %s on %s (recommended true) [WARN]"
              %(clstrnme, str(h['nodes'][n]['process']['mlockall']).lower(), hstnme), color="YELLOW", colored=colored)

          print
    except Exception, e:
        colorPrnt(" %s" %str(e), colored=colored)
        print

def main():

    init(autoreset=True)
    print
    
    for c in clnts:
        print(" ELS Client : %s" %c)

        basicTest(c)
        extendedTest(c)
    
    print
    deinit()
# <end of helper section>

# <start of test section>

# <end of test section>

# <start of init section>

# <end of init section>

# <start of cleanup section>

# <end of cleanup section>

# <start of main section>
if __name__ == '__main__':
    main()
# <end of main section>

