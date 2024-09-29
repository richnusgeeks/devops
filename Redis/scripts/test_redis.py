#! /usr/bin/env python
############################################################################
# File name : test_redis.py
# Purpose : External scan for Redis
# Usages : python test_redis.py <vip or actual Redis backened(s)>
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
import redis as rds
from colorama import Fore, Back, Style, init, deinit
from sys import argv
# <end of include section>

# <start of global section>
if len(argv) == 1:
    print(" Usage: %s <redis for signalr server hosname(s)>" %argv[0])
    exit(1) 
if '-n' == argv[1]:
  colored = False
  srvr = argv[2:]
else:
  colored = True
  srvr = argv[1:]
ports = 6379
porte = 6379
flds  = {
         'port' : '',
         'save' : '',
	 'dir'  : '',
	 'logfile' : '',
	}
rdsver = '2.6.10'
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

def testRDS(server):
    print(" Redis server : %s" %server)
    for p in xrange(ports, porte+1):
        try:
            r = rds.StrictRedis(server, port=p, socket_timeout=5)
	except Exception, e:
            colorPrnt(" %s" %str(e), colored=colored)
	    continue
    
        if r:
            for i in flds:
	            try:
        	        v = r.config_get("%s" %i)["%s" %i]
                    except Exception, e:
                        colorPrnt(" %s" %str(e), colored=colored)
			break
        	    if not flds[i]:
        	        if i == 'save':
        		    if v:
        		        colorPrnt("  port %s , %s [FAIL]" %(p, i), colored=colored)
                        else:			
                            if not v:
        		        colorPrnt("  port %s , %s [FAIL]" %(p, i), colored=colored)
        	    else:
        	        if v != flds[i]:
        		    colorPrnt("  port %s , %s : %s (expected %s) [FAIL]" %(p, i, v, flds[i]), colored=colored)
                    
            try:
                d = r.info()
		colorPrnt(" %s" %d['role'], color="GREEN", colored=colored)
                print
                if d['redis_version'] != rdsver:
		    colorPrnt(" port %s , redis_version : %s (expected %s) [FAIL]" %(p, d['redis_version'], rdsver), colored=colored)
		    print
            except Exception, e:
                colorPrnt(" %s" %str(e), colored=colored)
                print

    print

def main():
  init(autoreset=True)
  print

  for s in srvr:
    testRDS(s)

  deinit()
# <end of helper section>


# <start of test section>

# <end of test section>


# <start of init section>

# <end of init section>


# <start of cleanup section>

# <end of cleanup section>


# <start of main section>
if "__main__" == __name__:
  main()
# <end of main section>


