#! /usr/bin/env python
############################################################################
# File name : winrmtexec.py
# Purpose : Execute command(s) on remote Windows nodes using PsExec 
# Usages : python winrmtexec.py 
# Start date : 06/10/2014
# End date : mm/dd/2014
# Author : Ankur Kumar <richnusgeeks@gmail.com>
# Download link : http://www.richnusgeeks.me
# License : RichNusGeeks
# Version : 0.0.1
# Modification history : 
# Notes : 
############################################################################

# <start of global section>
def _prntErrWarnInfo(smsg, smsgtype = 'err', bresume = False):
  '''
      Global routine to print error/warning/info strings and resume/exit.
  '''

  derrwarninfo = {
                  'err'  : ' ERROR',
                  'warn' : ' WARNING',
                  'info' : ' INFO',
                 }  

  if not isinstance(smsg, str):

    print
    print (' Error : Invalid message type, '
             + 'please enter string.')
    print
    return False

  if smsgtype not in derrwarninfo.keys():
      
    print
    print (' Error : Invalid message type, '
           + 'please choose from \'err\', \'warn\', \'info\'.')
    print
    return False

  print
  print derrwarninfo[smsgtype] + ' : ' + smsg
  print

  if not bresume:
    print ' exiting ...'
    exit(-1)
  else:
    return True
# <end of global section>


# <start of include section>
try:
  from pygenericroutines import PyGenericRoutines, prntErrWarnInfo
except Exception, e:
  serr = ('%s, %s'
          %('from pygenericroutines import PyGenericRoutines', str(e)))
  _prntErrWarnInfo(serr)

try:
  import os
except Exception, e:
  serr = '%s, %s' %('import os', str(e))
  prntErrWarnInfo(serr)

try:
  import os.path
except Exception, e:
  serr = '%s, %s' %('import os.path', str(e))
  prntErrWarnInfo(serr)

try:
  import socket
except Exception, e:
  serr = '%s, %s' %('import socket', str(e))

try:
  import time
except Exception, e:
  serr = '%s, %s' %('import time', str(e))
  prntErrWarnInfo(serr)

try:
  import sys
except Exception, e:
  serr = '%s, %s' %('import sys', str(e))
  prntErrWarnInfo(serr)
# <end of include section>


# <start of helper section>
class WinRmtExec:

  def __init__(self):
    self.sclsnme = self.__class__.__name__	    
    self.opygenericroutines = PyGenericRoutines(self.sclsnme)
    self.opygenericroutines.setupLogging()
    self.bcnfgfloprtn = self.opygenericroutines.setupConfigFlOprtn()
    self.dopts = {
                  'prll' : {
                            'shortopt' : '-p',
                            'longopt'  : '--prll',
                            'dest'     : 'prllflag',
                            'action'   : 'store_true',
                            'help'     : 'use parallel mode',
                           },
                 }
    self.susage = 'usage: %prog [-p|--prll|-h|--help]'
    self.bprll = False
    self.twinnds = ()
    self.senv = ''
    self.twincmds = ()
    self.suser = ''
    self.spswrd = ''

  def parseOptsArgs(self):
    options = None
    args    = None
    try:
      (options, args) = self.opygenericroutines.parseCmdLine( \
                         self.dopts, susage = self.susage)
    except Exception, e:
      serr = (self.sclsnme + '::' + 'parseOptsArgs(...)' + ':'
              + 'parseCmdLine(...)' + ', ' + str(e))
      self.opygenericroutines.prntLogErrWarnInfo(serr, smsgtype = 'err', bresume = True)
      return False

    if options.prllflag:
      self.prll = options.prllflag	    

    return True

  def cacheValsFromCnfgFl(self):
    ssection = os.path.basename(sys.argv[0]).split('.')[0]
    sreturn = ''

    try:
      sreturn = self.opygenericroutines.getValFromConfigFl(\
                ssection, 'USER')
      if sreturn:
        self.suser = sreturn.strip()
    except Exception, e:
      serr = ('%s::cacheValsFromCnfgFl(...):\
               getValFromConfigFile(\'USER\'), %s'
               %(self.sclsnme, str(e)))
      self.opygenericroutines.prntLogErrWarnInfo(serr,\
                                                   smsgtype = 'err',\
                                                   bresume = True)
      return False

    try:
      sreturn = self.opygenericroutines.getValFromConfigFl(\
                ssection, 'HOSTS')
      if sreturn:
        self.twinnds = tuple(sreturn.split())
    except Exception, e:
      serr = ('%s::cacheValsFromCnfgFl(...):\
               getValFromConfigFile(\'HOSTS\'), %s'
               %(self.sclsnme, str(e)))
      self.opygenericroutines.prntLogErrWarnInfo(serr,\
                                                 smsgtype = 'err',\
                                                 bresume = True)
      return False

    try:
      sreturn = self.opygenericroutines.getValFromConfigFl(\
                ssection, 'ENV')
      if sreturn:
        self.senv = sreturn.strip()
    except Exception, e:
      serr = ('%s::cacheValsFromCnfgFl(...):\
               getValFromConfigFile(\'ENV\'), %s'
               %(self.sclsnme, str(e)))
      self.opygenericroutines.prntLogErrWarnInfo(serr,\
                                                 smsgtype = 'err',\
                                                 bresume = True)
      return False

    try:
      sreturn = self.opygenericroutines.getValFromConfigFl(\
                ssection, 'COMMANDS')
      if sreturn:
        if -1 != sreturn.find("'"):	      
          self.twincmds = tuple(sreturn.split("'"))
        elif -1 != sreturn.find('"'):	      
          self.twincmds = tuple(sreturn.split('"'))
        else:
          self.twincmds = tuple(sreturn.split())

    except Exception, e:
      serr = ('%s::cacheValsFromCnfgFl(...):\
               getValFromConfigFile(\'COMMANDS\'), %s'
               %(self.sclsnme, str(e)))
      self.opygenericroutines.prntLogErrWarnInfo(serr,\
                                                 smsgtype = 'err',\
                                                 bresume = True)
      return False

    try:
      sreturn = self.opygenericroutines.getValFromConfigFl(\
                ssection, 'PASSWORD')
      if sreturn:
        self.spswrd = sreturn.strip()
    except Exception, e:
      serr = ('%s::cacheValsFromCnfgFl(...):\
               getValFromConfigFile(\'PASSWORD\'), %s'
               %(self.sclsnme, str(e)))
      self.opygenericroutines.prntLogErrWarnInfo(serr,\
                                                 smsgtype = 'err',\
                                                 bresume = True)
      return False

  def preChecks(self):
    if not self.twinnds:
      serr = 'Empty HOSTS list in config.conf'
      self.opygenericroutines.prntLogErrWarnInfo(serr)

    if not self.senv:
      serr = 'Empty ENV string in config.conf'
      self.opygenericroutines.prntLogErrWarnInfo(serr)
    else:
      if self.senv.startswith('.'):
        serr = 'ENV string starting with .'	      
        self.opygenericroutines.prntLogErrWarnInfo(serr)
    
    if not self.twincmds:
      serr = 'Empty COMMANDS list in config.conf'
      self.opygenericroutines.prntLogErrWarnInfo(serr)

    if not self.suser:
      serr = 'Empty USER string in config.conf'
      self.opygenericroutines.prntLogErrWarnInfo(serr)
      
    if not self.spswrd:
      serr = 'Empty PASSWORD string in config.conf'
      self.opygenericroutines.prntLogErrWarnInfo(serr)

  def rmtExec(self):
    print self.twinnds
    print self.twincmds

    for h in self.twinnds:
      for c in self.twincmds:
        if len(c.strip()) > 0:	      
          t = self.opygenericroutines.psexecCmnd(c,\
              "%s.%s" %(h, self.senv), self.suser,\
	      self.spswrd)

	  if t[3]:
            c = t[0].split("\r\n")		
            for l in c:
              if not l.upper().startswith("PSEXEC") \
                and not l.upper().startswith("COPYRIGHT") \
		and not l.upper().startswith("SYSINTERNALS"):
                self.opygenericroutines.prntLogErrWarnInfo(\
	          l, smsgtype = 'info', bresume = True)		  

# <end of helper section>


# <start of test section>

# <end of test section>


# <start of init section>

# <end of init section>


# <start of cleanup section>

# <end of cleanup section>


# <start of main section>
def main(owinrmtexec):
  if owinrmtexec:
    owinrmtexec.parseOptsArgs()  	  
    owinrmtexec.cacheValsFromCnfgFl()  	  
    owinrmtexec.preChecks()
    owinrmtexec.rmtExec()
        

if '__main__' == __name__:
  owinrmtexec = WinRmtExec()
  main(owinrmtexec)  
# <end of main section>


