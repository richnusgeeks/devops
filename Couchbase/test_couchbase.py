#! /usr/bin/env python
############################################################################
# File name : test_couchbase.py
# Purpose : External scan for Couchbase
# Usages : python test_couchbase.py <Couchbase backend(s)>
# Start date : 05/07/2014
# End date : mm/dd/2014
# Author : Ankur Kumar <richnusgeeks@gmail.com>
# Download link : www.richnusgeeks.me
# License : RichNusGeeks
# Version : 0.0.1
# Modification history : 
# Notes : 
############################################################################

import requests as rest
from colorama import Fore, Back, Style, init, deinit
from sys import argv

if len(argv) == 1:
    print(" Usage: %s <couchbase server hosname(s)>" %argv[0])
    exit(1) 
if '-n' == argv[1]:
  colored = False
  srvr = argv[2:]
else:
  colored = True
  srvr = argv[1:]
port = 8091
user = '<Admin user>'
pswrd = '<Admin password>'
nodes = '/pools/nodes'
bckts = '/pools/defaults/buckets'
failover='/settings/autoFailover'
zcbver = '2.1.1'
numnodes = 2
numrplca = 1
buckets = {
           'bucket1' : {'password' : 'password1'},
           'bucket2' : {'password' : 'password2'},
           'bucket3' : {'password' : 'password3'},
           'bucket4' : {'password' : 'password4'},
          } 
colors = ('RED', 'GREEN', 'YELLOW',)

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

init(autoreset=True)
print

for s in srvr:
    print(" Couchbase server : %s" %s)

    try:
	r = rest.get("http://%s:%d%s" %(s, port, nodes), auth=(user, pswrd))
        if 200 == r.status_code:
            d = r.json()
            #print d['storageTotals']['ram']['total']
            #print d['storageTotals']['ram']['quotaTotal']

	    if numnodes > len(d['nodes']):
                colorPrnt("  Nodes in cluster %d (expected >= %d nodes) [FAIL]" %(len(d['nodes']), numnodes), colored=colored)
	        for i in d['nodes']:
                    colorPrnt("   %s" %i['hostname'], colored=colored)
	            
		    if not i['version'].startswith(zcbver):
                        colorPrnt("    Couchbase version %s (expected %s) [FAIL]" %(i['version'], zcbver), colored=colored)
                    else:
                        colorPrnt("    Couchbase version %s [PASS]" %(i['version']), color="GREEN", colored=colored)
                                       			 
            else:
                colorPrnt("  Nodes in cluster %d [PASS]" %len(d['nodes']), color="GREEN", colored=colored)
	        for i in d['nodes']:
                    colorPrnt("   %s" %i['hostname'], color="GREEN", colored=colored)

		    if not i['version'].startswith(zcbver):
                        colorPrnt("    Couchbase version %s (expected %s) [FAIL]" %(i['version'], zcbver), colored=colored)
                    else:
                        colorPrnt("    Couchbase version %s [PASS]" %(i['version']), color="GREEN", colored=colored)
		print
        else:
            colorPrnt("  Cluster seems not initialized [FAIL] %s %s" %(r, r.json()), colored=colored)
	    		
    except Exception, e:
        colorPrnt(" %s" %str(e), colored=colored)
        print
            		
    try:
	r = rest.get("http://%s:%d%s" %(s, port, bckts), auth=(user, pswrd))
        if 200 == r.status_code:
            d = r.json()
            b = {}

            for i in d:
                b[(i['name'])] = (i['replicaNumber'], i['saslPassword'])

            for j in buckets:
                if j in b: 
                    colorPrnt("  Bucket %s exists [PASS]" %j, color="GREEN", colored=colored)
                    if numrplca != b[j][0]:
                      colorPrnt("   Number of replica(s) %d (expected %d) [FAIL]" %(b[j][0], numrplca), colored=colored)
                    else:  
                      colorPrnt("   Number of replica(s) %d [PASS]" %numrplca, color="GREEN", colored=colored)
                    
                    if not b[j][1]: 
                      colorPrnt("   No password set on the bucket [WARN]", color="YELLOW", colored=colored)
                    else:
                      colorPrnt("   Password set on the bucket [PASS]", color="GREEN", colored=colored)
                      
                    print
                else:
                    colorPrnt("  Bucket %s doesn't exist [FAIL]" %j, colored=colored)
            print 
    except Exception, e:
        colorPrnt(" %s" %str(e), colored=colored)
        print

    try:
        r = rest.get("http://%s:%d%s" %(s, port, failover), auth=(user, pswrd))
        if 200 == r.status_code:
            d = r.json()
            
            if not d['enabled']:
                colorPrnt("  Auto failover not enabled [FAIL]", colored=colored)
            else:
                colorPrnt("  Auto failover enabled [PASS] timeout:%s" %d['timeout'], color="GREEN", colored=colored)
                if 0 != int(d['count']):
                  colorPrnt("   Failover quota needs reset [WARN] count:%s" %d['count'], color="YELLOW", colored=colored)
                else:
                  colorPrnt("   Failover quota [PASS] count:%s" %d['count'], color="GREEN", colored=colored)
            print

    except Exception, e:
        colorPrnt(" %s" %str(e), colored=colored)
        print

print
deinit()

# <start of include section>

# <end of include section>


# <start of global section>

# <end of global section>


# <start of helper section>

# <end of helper section>


# <start of test section>

# <end of test section>


# <start of init section>

# <end of init section>


# <start of cleanup section>

# <end of cleanup section>


# <start of main section>

# <end of main section>


