#! /usr/bin/env python
############################################################################
# File name : test_mongo.py
# Purpose : External scan for MG*
# Usages : python test_mongo.py <MG* backend(s)>
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
from pymongo import MongoClient
from colorama import Fore, Back, Style, init, deinit
from sys import argv
# <end of include section>

# <start of global section>
if len(argv) == 1:
    print(" Usage: %s <mongodb server hosname(s)>" %argv[0])
    exit(1) 
if '-n' == argv[1]:
  colored = False
  srvr = argv[2:]
else:
  colored = True
  srvr = argv[1:]
port = 27017
mngver = '2.4.6'
numnodes = 3
#rmsdepdbs = ('DomainData', 'admin',)
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
    c = None
    try:
        c = MongoClient('mongodb://%s:%d' %(server, port))
    except Exception, e:
        colorPrnt(" %s" %str(e), colored=colored)
        print
        
    d = {}
    try:
        if c:
            d = c.server_info()
    except Exception, e:
        colorPrnt(" %s" %str(e), colored=colored)
        print

    if d:
        if d['version'].startswith(mngver):
            colorPrnt("  MongoDB version %s [PASS] is_priamry %s" %(d['version'], str(c.is_primary)), color="GREEN", colored=colored)
        else: 
            colorPrnt("  MongoDB version %s (expected %s) [FAIL] is_primary %s" %(d['version'], mngver, str(c.is_primary)), colored=colored)

    #d = []
    #try:
    #    d = c.database_names()
    #    print d
    #except Exception, e:
    #    colorPrnt(" %s" %str(e))
    #    print

    #if d:
    #    for db in rmsdepdbs:
    #        if db in d:
    #            colorPrnt("  MongoDB deployment db %s present [PASS]" %db, color="GREEN")
    #        else:
    #            colorPrnt("  MongoDB deployment db %s not present [FAIL]" %db)
    
    try:
        if c:
            if c.admin.command('ping').has_key('ok'):
              colorPrnt("  Ping check [PASS]", color="GREEN", colored=colored)
            else:
              colorPrnt("  Ping check [FAIL]", colored=colored)
            print    
    except Exception, e:
        colorPrnt(" %s" %str(e), colored=colored)
        print

def main():
  init(autoreset=True)
  print

  for s in srvr:
    print(" MongoDB server : %s" %s)
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

