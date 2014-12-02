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
# Modification history : 
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
elsver = '0.90.11'
minmstrs = 2
mindatas = 2
minnodes = minmstrs + mindatas
shrdsunasgn = 0
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

            winclnts = {
                        'Role1' : 0,
                        'Role2' : 0,
                        'Role3' : 0,
                        'Role4' : 0,
                        'Role5' : 0,
                       }

            for n in h['nodes']:
                for w in winclnts:
                    if h['nodes'][n]['hostname'].upper().startswith(w):
                        winclnts[w] += 1

                if elsver != h['nodes'][n]['version']:
                    colorPrnt("  ELS %s cluster version %s on %s (expected %s) [FAIL]"
                          %(h['cluster_name'], h['nodes'][n]['version'], h['nodes'][n]['hostname'], elsver))

            print

            for w in winclnts:
                if winclnts[w] > 0:
                    colorPrnt("  ELS %s cluster number of %s client(s) %d [PASS]" %(h['cluster_name'], w, winclnts[w]), color="GREEN", colored=colored)
                else:
                    colorPrnt("  ELS %s cluster number of %s client(s) %d (expected > 0) [FAIL]" %(h['cluster_name'], w, winclnts[w]), colored=colored)
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

