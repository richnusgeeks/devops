#! /usr/bin/env python
############################################################################
# File name : test_elasticsearch.py
# Purpose : External scan for Elasticsearch cluster
# Usages : python test_elasticsearch.py <http port> <node with http enabled>
# Start date : 05/07/2014
# End date : mm/dd/2014
# Author : Ankur Kumar <richnusgeeks@gmail.com>
# Download link : www.richnusgeeks.me
# License : RichNusGeeks
# Version : 0.0.1
# Modification history : addition of best practices checks,Ankur 10/23/2015
#                        refarctored for v5.4,Ankur 06/12/2017
# Notes : 
############################################################################

# <start of include section>
import requests as rest
from colorama import Fore, Back, Style, init, deinit
from sys import argv
from os.path import basename
# <end of include section>

# <start of global section>
if len(argv) == 1:
    print(" Usage: %s <elasticsearch master(s)> <http port>" %basename(argv[0]))
    exit(1) 

if '-n' == argv[1]:
  colored = False
  port = argv[-1]
  clnts = argv[2:-1]
else:
  colored = True
  port = argv[-1]
  clnts = argv[1:-1]
port = port
health = '/_cluster/health'
state = '/_cluster/state'
nodes = '/_nodes'
ndstts = '/_nodes/stats'
elsver = '5.5'
minmstrs = 2
mindatas = 2
minnodes = minmstrs + mindatas
shrdsunasgn = 0
numcores = 2
fldscrptrs = 64*1024
timeout = 10
colors = ('RED', 'GREEN', 'YELLOW',)
elsdata = {
  "cluster": {},
  "nodes": {},
}
memtolerance = 1
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

def gatherData(client):
  try:
    r = rest.get("http://%s:%s%s" %(client, port, health), timeout=timeout)
    if 200 == r.status_code:
      h = r.json()
      elsdata["cluster"]["cluster_name"] = h["cluster_name"]
      elsdata["cluster"]["status"] = h["status"]
      elsdata["cluster"]["number_of_nodes"] = h["number_of_nodes"]
      elsdata["cluster"]["number_of_data_nodes"] = h["number_of_data_nodes"]
      elsdata["cluster"]["unassigned_shards"] = h["unassigned_shards"]

    r = rest.get("http://%s:%s%s" %(client, port, nodes), timeout=timeout)
    if 200 == r.status_code:
      h = r.json()
      for n in h['nodes']:
        if not h['nodes'][n]['roles']:
          continue
        hstnme = h['nodes'][n]['host']
        hstname = h['nodes'][n]['name']
        elsdata["nodes"][h["nodes"][n]["name"]] = {}
        elsdata["nodes"][h["nodes"][n]["name"]]["host"] = h["nodes"][n]["host"]
        elsdata["nodes"][h["nodes"][n]["name"]]["version"] = h["nodes"][n]["version"]
        elsdata["nodes"][h["nodes"][n]["name"]]["available_processors"] = h["nodes"][n]["os"]["available_processors"]
        elsdata["nodes"][h["nodes"][n]["name"]]["roles"] = h["nodes"][n]["roles"]
        elsdata["nodes"][h["nodes"][n]["name"]]["mlockall"] = h["nodes"][n]["process"]["mlockall"]
        elsdata["nodes"][h["nodes"][n]["name"]]["using_compressed_ordinary_object_pointers"] = h["nodes"][n]["jvm"]["using_compressed_ordinary_object_pointers"]

    r = rest.get("http://%s:%s%s" %(client, port, ndstts), timeout=timeout)
    if 200 == r.status_code:
      h = r.json()
      for n in h['nodes']:
        if not h['nodes'][n]['roles']:
          continue
        elsdata["nodes"][h["nodes"][n]["name"]]["max_file_descriptors"] = h["nodes"][n]["process"]["max_file_descriptors"]
        elsdata["nodes"][h["nodes"][n]["name"]]["heap_max_in_bytes"] = h["nodes"][n]["jvm"]["mem"]["heap_max_in_bytes"]
        elsdata["nodes"][h["nodes"][n]["name"]]["mem_total_in_bytes"] = h['nodes'][n]['os']['mem']['total_in_bytes']
        elsdata["nodes"][h["nodes"][n]["name"]]["swap_total_in_bytes"] = h["nodes"][n]["os"]["swap"]["total_in_bytes"]
  except Exception, e:
    colorPrnt(" %s" %str(e), colored=colored)
    print

def basicTest(client):
    try:
      if "red" == elsdata["cluster"]["status"]:
        colorPrnt("  %s state %s (expected %s) [FAIL]" %(elsdata["cluster"]["cluster_name"], "red", "green"), colored=colored)
      elif "green" == elsdata["cluster"]["status"]:
        colorPrnt("  %s cluster state green [PASS]" %elsdata["cluster"]["cluster_name"], color="GREEN", colored=colored)
      elif "yellow" == elsdata["cluster"]["status"]:
        colorPrnt("  %s cluster state %s (expected %s) [WARN]" %(elsdata["cluster"]["cluster_name"], "yellow", "green"), color="YELLOW", colored=colored)

      if minnodes > elsdata["cluster"]["number_of_nodes"]:
        colorPrnt("  %s total nodes %d (expected >= %d) [FAIL]" %(elsdata["cluster"]["cluster_name"], elsdata["cluster"]["number_of_nodes"], minnodes), colored=colored)
      else:
        colorPrnt("  %s total nodes %d [PASS]" %(elsdata["cluster"]["cluster_name"], elsdata["cluster"]["number_of_nodes"]), color="GREEN", colored=colored)

      if mindatas > elsdata["cluster"]["number_of_data_nodes"]:
        colorPrnt("  %s data nodes %d (expected >= %d) [FAIL]" %(elsdata["cluster"]["cluster_name"], elsdata["cluster"]["number_of_data_nodes"], mindatas), colored=colored)
      else:
        colorPrnt("  %s data nodes %d [PASS]" %(elsdata["cluster"]["cluster_name"], elsdata["cluster"]["number_of_data_nodes"]), color="GREEN", colored=colored)

      if shrdsunasgn < elsdata["cluster"]["unassigned_shards"]:
        colorPrnt("  %s unassigned_shards %d (expected %d) [FAIL]" %(elsdata["cluster"]["cluster_name"], elsdata["cluster"]["unassigned_shards"], shrdsunasgn), colored=colored)
      else:
        colorPrnt("  %s unassigned_shards %d [PASS]" %(elsdata["cluster"]["cluster_name"], shrdsunasgn), color="GREEN", colored=colored)

      print
    except Exception, e:
        colorPrnt(" %s" %str(e), colored=colored)
        print

def extendedTest(client):
  try:
     for n in elsdata["nodes"]:
       if not elsdata["nodes"][n]["version"].startswith(elsver):
         colorPrnt("  version %s on %s(%s) (recommended %s) [WARN]"
           %(elsdata["nodes"][n]["version"], n, elsdata["nodes"][n]["host"], elsver), color="YELLOW", colored=colored)

       if numcores > int(elsdata["nodes"][n]["available_processors"]):
         colorPrnt("  total_cores %s on %s(%s) (recommended >= %s) [WARN]"
           %(elsdata["nodes"][n]["available_processors"], n, elsdata["nodes"][n]["host"], numcores), color="YELLOW", colored=colored)

       if 0 != int(elsdata["nodes"][n]["swap_total_in_bytes"]):
         if not elsdata["nodes"][n]["mlockall"]:
           colorPrnt("  mlockall %s on %s(%s) (required true if swap is on) [FAIL]"
             %(str(elsdata["nodes"][n]["mlockall"]).lower(), n, elsdata["nodes"][n]["host"]), color="RED", colored=colored)

       if fldscrptrs > int(elsdata["nodes"][n]["max_file_descriptors"]):
         colorPrnt("  max_file_descriptors %s on %s(%s) (required ~ %s) [FAIL]"
           %(elsdata["nodes"][n]["max_file_descriptors"], n, elsdata["nodes"][n]["host"], fldscrptrs), color="RED", colored=colored)

       heapmax = int(elsdata["nodes"][n]["heap_max_in_bytes"])
       totalmem = int(elsdata["nodes"][n]["mem_total_in_bytes"])
       if heapmax < totalmem/2:
         colorPrnt("  heap_max_in_bytes %s on %s(%s) (recommended ~ %s) [WARN]"
           %(heapmax, n, elsdata["nodes"][n]["host"], totalmem/2), color="YELLOW", colored=colored)

       if not elsdata["nodes"][n]["using_compressed_ordinary_object_pointers"]:
         colorPrnt("  using_compressed_ordinary_object_pointers %s on %s(%s) (required true) [FAIL]"
           %(str(elsdata["nodes"][n]["using_compressed_ordinary_object_pointers"]).lower(), n, elsdata["nodes"][n]["host"]), colored=colored)

       if 0 != int(elsdata["nodes"][n]["swap_total_in_bytes"]):
         colorPrnt("  swap_total_in_bytes %s on %s(%s) (required swap off) [FAIL]"
           %(elsdata["nodes"][n]["swap_total_in_bytes"], n, elsdata["nodes"][n]["host"]), color="RED", colored=colored)

       print
  except Exception, e:
    colorPrnt(" %s" %str(e), colored=colored)
  print

def internalTest():
  pass

def main():
  init(autoreset=True)
  print
    
  for c in clnts:
    print(" ELS HTTP Node: %s" %c)
    gatherData(c)
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
