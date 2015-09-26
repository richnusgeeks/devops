#! /usr/bin/env python
############################################################################
# File name : createawsstuff.py
# Purpose : Create/Delete various AWS resources 
# Usages : createawsstuff.py [-c|--create|-r|--remove|-d|--dryrun|
#                             -h|--help]
# Start date : 22/09/2014
# End date : dd/mm/2014
# Author : Ankur Kumar <richnusgeeks@gmail.com>
# Download link : 
# License : GNU GPL v3
# Version : 0.0.1
# Modification history : 
############################################################################

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

try:
    from pygenericroutines import PyGenericRoutines, prntErrWarnInfo
except Exception, e:
    serr = ('%s, %s'
            %('from pygenericroutines import PyGenericRoutines', str(e)))
    _prntErrWarnInfo(serr)

try:
    import boto
except Exception, e:
    serr = '%s, %s' %('import boto', str(e))
    prntErrWarnInfo(serr)

class CreateAwsStuff():
  '''
    This class provides the functionalities to create/remove various
    AWS resources.
  '''

  def __init__(self):
      '''
          Class constructor to initialize required data structures.
      '''
      
      self.opygenericroutines = PyGenericRoutines(self.__class__.__name__)
      self.opygenericroutines.setupLogging()
      self.bcnfgfloprtn = self.opygenericroutines.setupConfigFlOprtn()
      self.sclsnme     = self.__class__.__name__
      self.cflag = False
      self.rflag = False
      self.dflag = False
      self.lnewinstnc = []
      self.lremoveids = []
      self.lrebootids = []
      self.lstopids = []
      self.lkeypairs = []
      self.lservices = []
      self.limages = []
      self.lbuckets = []
      self.lactions = []
      self.dvldactns = {
                         'instances': (
                                        'create',
                                        'remove',
                                        'reboot',
                                        'stop',
                                        'start',
                                      ),
                         'keypairs': (
                                       'create',
                                       'remove',
                                     ),
                         'buckets': (
                                      'create',
                                      'remove',
                                    ),
                         'services': (
                                       'create',
                                       'remove',
                                     ),
                       }
      self.doptsargs = {
                         'create' : {
                                      'shortopt' : '-c',
                                      'longopt'  : '--create',
                                      'dest'     : 'cflag',
                                      'action'   : 'store_true',
                                      'help'     : 'Create AWS resources',
                                    },
                         'remove' : {
                                      'shortopt' : '-r',
                                      'longopt'  : '--remove',
                                      'dest'     : 'rflag',
                                      'action'   : 'store_true',
                                      'help'     : 'Delete AWS resources',
                                    },
                         'dryrun' : {
                                      'shortopt' : '-d',
                                      'longopt'  : '--dryrun',
                                      'dest'     : 'dflag',
                                      'action'   : 'store_true',
                                      'help'     : 'Dryrun AWS resources',
                                    },
                       }

      self.susage = 'usage: %prog [-c|--create|-r|--remove|-d|--dryrun|-h|--help]'

  def parseOptsArgs(self):
    '''
      Method to parse command line options and arguments.
    '''

    options = None
    args    = None
    try:
      (options, args) = self.opygenericroutines.parseCmdLine( \
                          self.doptsargs, \
                          susage = self.susage, \
                          bexactposargs = False)
    except Exception, e:
      serr = (self.sclsnme + '::' + 'parseOptsArgs(...)' + ':'
              + 'parseCmdLine(...)' + ', ' + str(e))
      self.opygenericroutines.prntLogErrWarnInfo(serr, bresume = True)
      return False

    if options.cflag:
      self.cflag = options.cflag

    if options.rflag:
      self.rflag = options.rflag

    if options.dflag:
      self.dflag = options.dflag

    return True

  def cacheValsFromCnfgFl(self):
    '''
      Method to cache various sections values from config file
      once.
    '''
    ssection = os.path.basename(sys.argv[0]).split('.')[0]
    sreturn = ''

    try:
      sreturn = self.opygenericroutines.getValFromConfigFl(\
                ssection, 'Actions')
      if sreturn:
        self.lActions = sreturn.split()
    except Exception, e:
      serr = ('%s::cacheValsFromCnfgFl(...):\
               getValFromConfigFile(\'Actions\'), %s'
               %(self.sclsnme, str(e)))
      self.opygenericroutines.prntLogErrWarnInfo(serr,\
                                   smsgtype = 'err',\
                                      bresume = True)
      return False

    if self.rflsg:
      try:
        sreturn = self.opygenericroutines.getValFromConfigFl(\
                  ssection, 'Removeids')
        if sreturn:
          self.lremoveids = sreturn.split()
      except Exception, e:
        serr = ('%s::cacheValsFromCnfgFl(...):\
                 getValFromConfigFile(\'Removeids\'), %s'
                 %(self.sclsnme, str(e)))
        self.opygenericroutines.prntLogErrWarnInfo(serr,\
                                     smsgtype = 'err',\
                                        bresume = True)
        return False
  
      try:
        sreturn = self.opygenericroutines.getValFromConfigFl(\
                  ssection, 'Rebootids')
        if sreturn:
          self.lrebootids = sreturn.split()
      except Exception, e:
        serr = ('%s::cacheValsFromCnfgFl(...):\
                 getValFromConfigFile(\'Rebootids\'), %s'
                 %(self.sclsnme, str(e)))
        self.opygenericroutines.prntLogErrWarnInfo(serr,\
                                     smsgtype = 'err',\
                                        bresume = True)
        return False
  
      try:
        sreturn = self.opygenericroutines.getValFromConfigFl(\
                  ssection, 'Stopids')
        if sreturn:
          self.lstopids = sreturn.split()
      except Exception, e:
        serr = ('%s::cacheValsFromCnfgFl(...):\
                 getValFromConfigFile(\'Stopids\'), %s'
                 %(self.sclsnme, str(e)))
        self.opygenericroutines.prntLogErrWarnInfo(serr,\
                                     smsgtype = 'err',\
                                        bresume = True)
        return False

    if self.cflag:
      try:
        sreturn = self.opygenericroutines.getValFromConfigFl(\
                  ssection, 'Bringupnew')
        if sreturn:
          self.lbringupnew = sreturn.split()
      except Exception, e:
        serr = ('%s::cacheValsFromCnfgFl(...):\
                 getValFromConfigFile(\'Bringupnew\'), %s'
                 %(self.sclsnme, str(e)))
        self.opygenericroutines.prntLogErrWarnInfo(serr,\
                                     smsgtype = 'err',\
                                        bresume = True)
        return False

      try:
        sreturn = self.opygenericroutines.getValFromConfigFl(\
                  ssection, 'Keypairs')
        if sreturn:
          self.lkeypairs = sreturn.split()
      except Exception, e:
        serr = ('%s::cacheValsFromCnfgFl(...):\
                 getValFromConfigFile(\'Keypairs\'), %s'
                 %(self.sclsnme, str(e)))
        self.opygenericroutines.prntLogErrWarnInfo(serr,\
                                     smsgtype = 'err',\
                                        bresume = True)
        return False

      try:
        sreturn = self.opygenericroutines.getValFromConfigFl(\
                  ssection, 'Images')
        if sreturn:
          self.limages = sreturn.split()
      except Exception, e:
        serr = ('%s::cacheValsFromCnfgFl(...):\
                 getValFromConfigFile(\'Images\'), %s'
                 %(self.sclsnme, str(e)))
        self.opygenericroutines.prntLogErrWarnInfo(serr,\
                                     smsgtype = 'err',\
                                        bresume = True)
        return False

      try:
        sreturn = self.opygenericroutines.getValFromConfigFl(\
                  ssection, 'Buckets')
        if sreturn:
          self.lbuckets = sreturn.split()
      except Exception, e:
        serr = ('%s::cacheValsFromCnfgFl(...):\
                 getValFromConfigFile(\'Buckets\'), %s'
                 %(self.sclsnme, str(e)))
        self.opygenericroutines.prntLogErrWarnInfo(serr,\
                                     smsgtype = 'err',\
                                        bresume = True)
        return False

      try:
        sreturn = self.opygenericroutines.getValFromConfigFl(\
                  ssection, 'Services')
        if sreturn:
          self.lservices = sreturn.split()
      except Exception, e:
        serr = ('%s::cacheValsFromCnfgFl(...):\
                 getValFromConfigFile(\'Services\'), %s'
                 %(self.sclsnme, str(e)))
        self.opygenericroutines.prntLogErrWarnInfo(serr,\
                                     smsgtype = 'err',\
                                        bresume = True)
        return False

    return True

  def preChecks(self):
    '''
      Method to verify all the required pieces.
    '''

    if self.cflag:
      try:
        for i in self.lactions:
          ap = i.split(':')
          if 2 != len(ap):
            serr = 'Invalid pair %s in Actions config field' %i
            self.opygenericroutines.prntLogErrWarnInfo(serr,\
                                           smsgtype = 'err',\
                                              bresume = True)
            return False
          else:
            if i in self.dvldactns:
              if ap[1] not in self.dvldactns[i]:
                serr = 'Invalid action %s in Actions config field' %ap
                self.opygenericroutines.prntLogErrWarnInfo(serr,\
                                               smsgtype = 'err',\
                                                  bresume = True)
                return False

    return True

  def createInstances(self):
    '''
      Method to create EC2/VPC instances.
    '''
    
    try:
      conn = boto.connect_ec2()
      if conn:
        print("\n<Start of Create EC2/VPC Instances>\n")
        for r in conn.get_all_reservations():
          for i in r.instances: 
            print(" ID: %s , ImageID: %s , Tags: %s , Type: %s , State: %s , Key: %s , GRPS: %s , IP: %s , PIP: %s, SNID: %s , VPCID: %s , Monitored: %s"
                   %(i.id,i.image_id,i.tags.get('Name',''),i.instance_type,i.state,i.key_name,i.groups,i.ip_address,i.private_ip_address,i.subnet_id,i.vpc_id,i.monitored))
        print("\n<End of Dump EC2/VPC Instances>\n")
    except Exception, e:
      serr = ('%s :: dumpInstances(...) : connect_ec2,get_all_reservations(...), '
              '%s' %(self.sclsnme, str(e)))
      self.opygenericroutines.prntLogErrWarnInfo(serr,\
                                     smsgtype = 'err',\
                                        bresume = True)
      return False
      

  def deleteInstances(self):
    '''
      Method to remove EC2/VPC instances.
    '''
    
    try:
      conn = boto.connect_ec2()
      if conn:
        print("\n<Start of Delete EC2/VPC Instances>\n")
        conn.terminate_instances(self.lremoveids, self.dflag)
        print("\n<End of Delete EC2/VPC Instances>\n")
    except Exception, e:
      serr = ('%s :: dumpInstances(...) : connect_ec2,terminate_instances(...), '
              '%s' %(self.sclsnme, str(e)))
      self.opygenericroutines.prntLogErrWarnInfo(serr,\
                                     smsgtype = 'err',\
                                        bresume = True)
      return False
   
  def stopInstances(self):
    '''
      Method to stop EC2/VPC instances.
    '''
    
    try:
      conn = boto.connect_ec2()
      if conn:
        print("\n<Start of Start EC2/VPC Instances>\n")
        conn.stop_instances(self.lstopids, self.dflag)
        print("\n<End of Start EC2/VPC Instances>\n")
    except Exception, e:
      serr = ('%s :: dumpInstances(...) : connect_ec2,stop_instances(...), '
              '%s' %(self.sclsnme, str(e)))
      self.opygenericroutines.prntLogErrWarnInfo(serr,\
                                     smsgtype = 'err',\
                                        bresume = True)
      return False

    return True

  def restartInstances(self):
    '''
      Method to restart EC2/VPC instances.
    '''
    
    try:
      conn = boto.connect_ec2()
      if conn:
        print("\n<Start of Restart EC2/VPC Instances>\n")
        conn.stop_instances(self.lrebootids, self.dflag):
        conn.start_instances(self.lrebootids, self.dflag):
        print("\n<End of Restart EC2/VPC Instances>\n")
    except Exception, e:
      serr = ('%s :: dumpInstances(...) : connect_ec2,stop/start_instances(...), '
              '%s' %(self.sclsnme, str(e)))
      self.opygenericroutines.prntLogErrWarnInfo(serr,\
                                     smsgtype = 'err',\
                                        bresume = True)
      return False

  def createStuff(self):
    
    
  def removeStuff(self):

  def createRemoveStuff(self):
    '''
      Method to Create/Remove the desired AWS stuff.
    '''

    if self.cflag:
      self.createStuff()

    if self.rflag:
      self.removeStuff()

def mainconsole(ocreateawsstuff):
  '''
      Main application driver routine for console mode.
  '''

  if ocreateawsstuff.parseOptsArgs():
    if ocreateawsstuff.cacheValsFromCnfgFl():
      if ocreateawsstuff.preChecks()
        ocreateawsstuff.createRemoveStuff()
      else:
        serr = 'mainconsole(...):preChecks(...) failed.'
        _prntErrWarnInfo(serr, 'err', bresume = True)
    else:
      serr = 'mainconsole(...):cacheValsFromCnfgFl(...) failed.'
      _prntErrWarnInfo(serr, 'err', bresume = True)

  else:
    serr = 'mainconsole(...):parseOptsArgs(...) failed.'
    _prntErrWarnInfo(serr, 'err', bresume = True)


if '__main__' == __name__:
  '''
    Routine to run in case file is not imported as a module.
  '''

  ocreateawsstuff = CreateAwsStuff()
  mainconsole(ocreateawsstuff)

