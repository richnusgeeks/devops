#! /usr/bin/env python
############################################################################
# File name : test_postgres.py
# Purpose : External scan for PostgreSQL
# Usages : python test_postgres.py <backend(s)>
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
import psycopg2 as pgsql
from colorama import Fore, Back, Style, init, deinit
from sys import argv
# <end of include section>

# <start of global section>
if len(argv) == 1:
    print(" Usage: %s <postgresql server hosname(s)>" %argv[0])
    exit(1) 
if '-n' == argv[1]:
  colored = False
  srvr = argv[2:]
else:
  colored = True
  srvr = argv[1:]
port = 5432
dbname = 'postgres'
user = 'postgres'
password = ''
pgsver = '9.2.5'
srvrsttngs = {
              'max_connections' : '600',
              'shared_buffers' : '4GB',
              'work_mem' : '16MB',
              'maintenance_work_mem' : '128MB',
              'checkpoint_segments' : '50',
              'checkpoint_completion_target' : '0.9',
              'effective_cache_size' : '8GB',
              'listen_addresses' : '*',
              'log_checkpoints' : 'on',
              'log_connections' : 'on',
              'log_disconnections' : 'on',
              'log_line_prefix' : r"%m %u@%d %p %r",
              'log_lock_waits' : 'on',
              'max_wal_senders' : '5',
              'wal_keep_segments' : '200',
              'wal_level' : 'archive',
             }
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
        c = pgsql.connect(host=server, dbname=dbname, user=user)
    except Exception, e:
        colorPrnt(" %s" %str(e), colored=colored)
        print
            		
    try:
        v = c.get_parameter_status('server_version')
    except Exception, e:
        colorPrnt(" %s" %str(e), colored=colored)
        print

    if v.startswith(pgsver):
        colorPrnt("  PostgreSQL version %s [PASS]" %v, color="GREEN", colored=colored)
    else: 
        colorPrnt("  PostgreSQL version %s (expected %s) [FAIL]" %(v, pgsver), colored=colored)
    print

    cur = None
    try:
      if c:
        cur = c.cursor()
    except Exception, e:
        colorPrnt(" %s" %str(e), colored=colored)
        print

    for f in srvrsttngs:
      SQL = "SELECT current_setting('%s');" %f
      try:
        if cur:
          cur.execute(SQL)
          v = cur.fetchone()[0]
          if v != srvrsttngs[f]:
              colorPrnt("  Config setting %s = %s (expected %s) [FAIL]" %(f, v, srvrsttngs[f]), colored=colored)
          else:
              colorPrnt("  Config setting %s = %s [PASS]" %(f, srvrsttngs[f]), color="GREEN", colored=colored)
      except Exception, e:
        colorPrnt(" %s" %str(e), colored=colored)
        print
    print

def main():

  init(autoreset=True)
  print

  for s in srvr:
    print(" PostgreSQL server : %s" %s)
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

