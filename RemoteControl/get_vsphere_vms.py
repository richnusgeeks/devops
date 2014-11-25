#! /usr/bin/env python
############################################################################
# File name : get_vsphere_vms.py
# Purpose : Get vSphere based VMs listing for different roles
# Usages : python get_vsphere_vms.py <ENV(s)>
# Start date : 05/07/2014
# End date : mm/dd/2014
# Author : Ankur Kumar <richnusgeeks@gmail.com>
# Download link : www.richnusgeeks.me
# License : RichNusGeeks
# Version : 0.0.1
# Modification history : 
# Notes : 
############################################################################

from pysphere import VIServer
from colorama import Fore, Back, Style, init, deinit
from sys import argv

if len(argv) == 1:
    print(" Usage: %s <ENV(s) name(s)>" %argv[0])
    exit(1)

envs = argv[1:]
urls = {
        '' : { 
                   'suffix' : '',
                   'user' : '',
                   'pswrd' : '',
                  },   
        '' : { 
                   'suffix' : '',
                   'user' : '',
                   'pswrd' : '',
                  },   
        '' : { 
                   'suffix' : '',
                   'user' : '',
                   'pswrd' : '',
                  },   
       }
lnxrls = {
          'Plain GNU/Linux' : {'role' : 'lnx',},
         }

init(autoreset=True)
print

for s in envs:
    try:
        print(" Env: %s, vSphere Server: %s" %(s.upper(), urls[s]['suffix']))
    except Exception, e:
        continue

    try:
        server = VIServer()
        server.connect(r"%s" %urls[s]['suffix'], urls[s]['user'], urls[s]['pswrd'])
    except Exception, e:
        print(Fore.RED + Style.BRIGHT + " %s" %str(e))
        print

    try:
        print(Fore.GREEN + Style.BRIGHT + "  Server Type: %s" %server.get_server_type())
        print(Fore.GREEN + Style.BRIGHT + "  API Version: %s" %server.get_api_version())
    except Exception, e:
        print(Fore.RED + Style.BRIGHT + " %s" %str(e))
        print

    try:
        lstvms = server.get_registered_vms()
    except Exception, e:
        print(Fore.RED + Style.BRIGHT + " %s" %str(e))
        print

    for k in lnxrls:
        hstlst = []
        for v in lstvms:
            hstnme = v.split()[1].split('/')[0].lower()
            if hstnme.startswith(lnxrls[k]['role']):
                if lnxrls[k]['role'] == 'mg' and hstnme.startswith('mgf'):
                    continue
                hstlst.append(hstnme)
        lnxrls[k]['hosts'] = hstlst

    for k in lnxrls:
        print("  %s" %lnxrls[k]['role'])
        for h in lnxrls[k]['hosts']:
            print("   %s" %h)
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


