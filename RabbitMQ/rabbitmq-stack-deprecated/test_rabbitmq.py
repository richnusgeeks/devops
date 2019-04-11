#! /usr/bin/env python
############################################################################
# File name : test_rabbitmq.py
# Purpose : External scan for RabbitMQ
# Usages : python test_rabbitmq.py <vip or actual backend(s)>
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
    print(" Usage: %s <rabbitmq server hosname(s)>" %argv[0])
    exit(1) 
if '-n' == argv[1]:
  colored = False
  srvr = argv[2:]
else:
  colored = True
  srvr = argv[1:]
port = 15672
user = 'guest'
pswrd = 'guest'
nodes = '/api/nodes'
alive = '/api/aliveness-test/%2f'
overview = '/api/overview'
msgver = '3.0.2'
numnodes = 2
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

def basicTest(server):
    try:
	r = rest.get("http://%s:%d%s" %(server, port, overview), auth=(user, pswrd))
        if 200 == r.status_code:
            d = r.json()

	    if msgver != d['rabbitmq_version']:
                colorPrnt("  rabbitmq_version %s (expected %s) [FAIL]" %(d['rabbitmq_version'], msgver), colored=colored)
            else:
                colorPrnt("  rabbitmq_version %s (expected %s) [PASS]" %(d['rabbitmq_version'], msgver), color="GREEN", colored=colored)
            print		
    except Exception, e:
        colorPrnt(" %s" %str(e), colored=colored)
        print	
            		
    try:
	r = rest.get("http://%s:%d%s" %(server, port, nodes), auth=(user, pswrd))
        if 200 == r.status_code:
            n = r.json()

            if numnodes > len(n):
                colorPrnt("  Nodes in cluster %d (expected >= %d nodes) [FAIL]" %(len(n), numnodes), colored=colored)
	        for i in n:
                    colorPrnt("   %s" %i['name'], colored=colored)
            else:
                colorPrnt("  Nodes in cluster %d [PASS]" %len(n), color="GREEN", colored=colored)
	        for i in n:
                    colorPrnt("   %s" %i['name'], color="GREEN", colored=colored)
		print    
    except Exception, e:
        colorPrnt(" %s" %str(e), colored=colored)
        print

    try:
	r = rest.get("http://%s:%d%s" %(server, port, alive), auth=(user, pswrd))
        if 200 == r.status_code:
            d = r.json()

	    if 'ok' != d['status']:
                colorPrnt("  Aliveness test for vhost / [FAIL]", colored=colored)
	    else:
                colorPrnt("  Aliveness test for vhost / [PASS]", color="GREEN", colored=colored)
            print		
    except Exception, e:
        colorPrnt(" %s" %str(e), colored=colored)
        print	

def main():
  init(autoreset=True)
  print

  for s in srvr:
    print(" RabbitMQ server : %s" %s)
    basicTest(s)

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
if '__main__' == __name__:
  main()
# <end of main section>

