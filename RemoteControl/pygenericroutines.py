#! /usr/bin/env python
############################################################################
# File name : pygenericroutines.py                                         #
# Purpose   : A Python class to expose some generic routines for other     #
#             python automation tools.                                     #
# Usages    : add "from pygenericroutines import PyGenericRoutines" in the #
#             python file(s) and use class.                                #
# Start date : 13/10/2010                                                  #
# End date   : 13/10/2010                                                  #
# Author     : Ankur Kumar Sharma <richnusgeeks@gmail.com>                 #
# Download link : http://www.richnusgeeks.com                              #
# License       : GNU GPL v3 http://www.gnu.org/licenses/gpl.html          #
# Version       : 0.0.8                                                    #
# Modification history : 1. addition of ssh methods, more config file      #
#                           methods, command execution method and some     #
#                           internal routines in 0.0.6 by Ankur            #
#                        2. code cleanup through __isInstance and few other#
#                           implementaion changes in 0.0.7 by Ankur        #
#                        3. addition of nargs case in parseCmdLine(...) in #
#                           0.0.8 by Ankur                                 #
#                        4. many small fixes in 0.0.8 by Ankur             # 
############################################################################


def prntErrWarnInfo(smsg, smsgtype = 'err', bresume = False):
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
    import socket
except Exception, e:
    serr = 'import socket, %s' %(str(e))
    prntErrWarnInfo(serr)


try:
    import re
except Exception, e:
    serr = 'import re, %s' %(str(e))
    prntErrWarnInfo(serr)


try:
    import time
except Exception, e:
    serr = 'import time, %s' %(str(e))
    prntErrWarnInfo(serr)


try:
    import shutil
except Exception, e:
    serr = 'import shutil, %s' %(str(e))
    prntErrWarnInfo(serr)


try:
    import sys
except Exception, e:
    serr = 'import sys, %s' %(str(e))
    prntErrWarnInfo(serr)


try:
    import os
except Exception, e:
    serr = 'import os, %s' %(str(e))
    prntErrWarnInfo(serr)


try:
    import os.path
except Exception, e:
    serr = 'import os.path, %s' %(str(e))
    prntErrWarnInfo(serr)


try:
    import posixpath
except Exception, e:
    serr = 'import posixpath, %s' %(str(e))
    prntErrWarnInfo(serr)


try:
    import ConfigParser
except Exception, e:
    serr = 'import ConfigParser, %s' %(str(e))
    prntErrWarnInfo(serr)


try:
    import logging
except Exception, e:
    serr = 'import logging, %s' %(str(e))
    prntErrWarnInfo(serr)


try:
    import subprocess
except Exception, e:
    serr = 'import subprocess, %s' %(str(e))
    prntErrWarnInfo(serr)


try:
    from optparse import OptionParser
except Exception, e:
    serr = 'from optparse import OptionParser, %s' %(str(e))
    prntErrWarnInfo(serr)


try:
    import shlex
except Exception, e:
    serr = 'import shlex, %s' %(str(e))
    prntErrWarnInfo(serr)


try:
    import paramiko
except Exception, e:
    swarn = 'import paramiko, %s' %(str(e))
    prntErrWarnInfo(swarn, smsgtype = 'warn', bresume = True)


class PyGenericRoutines:
    '''
        This python class provides methods for some functionalities required
        most of the time when creating python based automation tools.
    '''

    def __init__(self, smdlenme, slogflnme = 'activity.log', scnfgflnme = 'config.conf'):
        '''
            Class constructor to initialize required data structures.
        '''

        self.sclsnme = self.__class__.__name__

        self.sreptrntme = '\s+'
        self.sbkupflextn= '.bak'
        self.oreptrntme = None
        self.lsctme     = []
        self.sbkupflnme = ''

        self.osckt    = None
        self.taddrprt = ('www.python.org', 80)

        self.smdlenme  = smdlenme
        self.slogflnme = slogflnme
        self.ologfl    = None
        self.blgngenbld= False
        self.dmsgtype  = {
                          'err' : 'ERROR',
                          'warn': 'WARNING',
                          'info': 'INFO',
                         }
        self.smsgseprtr = '-'

        self.scnfgflnme = scnfgflnme
        self.ocnfgfl    = None

        self.ossh       = None
	self.oscp       = None


    def __del__(self):
        '''
            Class destructor to cleanup/finalize various operations.
        '''

        if self.osckt:
            self.osckt.close()


    def __isInstance(self, sarg, sfuncnme, stype):
        '''
            Method to verify the proper type of an argument.
        '''

        serr = ''
        if(stype == 'integer'):
            if not isinstance(sarg, int):
                serr = ('%s :: %s(...) : %s should be of %s type.'
                        %(self.sclsnme, sfuncnme, sarg, stype))
            else:
                return True
        
        elif(stype == 'float'):
            if not isinstance(sarg, float):
                serr = ('%s :: %s(...) : %s should be of %s type.'
                        %(self.sclsnme, sfuncnme, sarg, stype))
            else:
                return True
      
        elif(stype == 'string'):
            if not isinstance(sarg, str):
                serr = ('%s :: %s(...) : %s should be of %s type.'
                        %(self.sclsnme, sfuncnme, sarg, stype))
            else:
                return True

        elif(stype == 'boolean'):
            if not isinstance(sarg, bool):
                serr = ('%s :: %s(...) : %s should be of %s type.'
                        %(self.sclsnme, sfuncnme, sarg, stype))
            else:
                return True

        elif(stype == 'list'):
            if not isinstance(sarg, list):
                serr = ('%s :: %s(...) : %s should be of %s type.'
                        %(self.sclsnme, sfuncnme, sarg, stype))
            else:
                return True

        elif(stype == 'tuple'):
            if not isinstance(sarg, tuple):
                serr = ('%s :: %s(...) : %s should be of %s type.'
                        %(self.sclsnme, sfuncnme, sarg, stype))
            else:
                return True
        
        elif(stype == 'dictionary'):
            if not isinstance(sarg, dict):
                serr = ('%s :: %s(...) : %s should be of %s type.'
                        %(self.sclsnme, sfuncnme, sarg, stype))
            else:
                return True

        else:
            serr = ('%s :: %s(...) : %s is of unknown type.'
                    %(self.sclsnme, sfuncnme, sarg))

        prntErrWarnInfo(serr, bresume = True)
        return False


    def backupFile(self, sfilenme, sfilepath):
        '''
            Method to backup file.
        '''

        if not self.__isInstance(sfilenme, 'backupFile', 'string'):
            return False;

        if not self.__isInstance(sfilepath, 'backupFile', 'string'):
            return False;    

        try:
            self.oreptrntme = re.compile(self.sreptrntme)
        except Exception, e:
            serr = (self.sclsnme + '::' + 'backupFile(...)' + ':'
                    + 're.compile(' + self.sreptrntme + '), ' + str(e))
            prntErrWarnInfo(serr, bresume = True)
            return False

        sasctme = ''
        try:
            sasctme = time.asctime()
        except Exception, e:
            serr = (self.sclsnme + '::' + 'backupFile(...)' + ':'
                    + 'time.asctime()' + ', ' + str(e))
            prntErrWarnInfo(serr, bresume = True)
            return False

        try:
            self.lasctme = re.split(self.oreptrntme, sasctme)
        except Exception, e:
            serr = (self.sclsnme + '::' + 'backupFile(...)' + ':'
                    + 're.split(' + str(self.oreptrntme) + ', ' 
                    +  sasctme + '), ' + str(e))
            prntErrWarnInfo(serr, bresume = True)
            return False

        sorigfl = ''
        try:
            sorigfl = os.path.join(sfilepath, sfilenme)
        except Exception, e:
            serr = (self.sclsnme + '::' + 'backupFile(...)' + ':'
                    + 'os.path.join(' + sfilepath + ', ' + sfilenme
                    + '), ' + str(e))
            prntErrWarnInfo(serr, bresume = True)
            return False

        sbkupfl = ('%s%s%s' 
              %(sfilenme,self.sbkupflextn,self.lasctme[3].replace(':', '')))
        try:
            sbkupfl = os.path.join(sfilepath, sbkupfl)
        except Exception, e:
            serr = (self.sclsnme + '::' + 'backupFile(...)' + ':'
                    + 'os.path.join(' + sfilepath + ', ' + sbkupfl
                    + '), ' + str(e))
            prntErrWarnInfo(serr, bresume = True)
            return False

        try:
            shutil.copy(sorigfl, sbkupfl)
        except Exception, e:
            serr = (self.sclsnme + '::' + 'backupFile(...)' + ':'
                    + 'shutil.copy(' + sorigfl + ', ' + sbkupfl
                    + '), ' + str(e))
            prntErrWarnInfo(serr, bresume = True)
            return False

        return True  


    def backupFiles(self, tfilenames, sfilepath):
        '''
            Method to backup files.
        '''

        if not self.__isInstance(tfilenames, 'backupFiles', 'tuple'):
            return False

        for ifl in tfilenames:
            if not self.backupFile(ifl, sfilepath):
                return False
        
        return True

    
    def doesFileExist(self, sfilename, sfilepath):
        '''
            Method to check the existance of a file.
        '''

        if not self.__isInstance(sfilename, 'doesFileExist', 'string'):
            return False

        if not self.__isInstance(sfilepath, 'doesFileExist', 'string'):
            return False
        
        sfilewithpath = ''
        try:
            sfilewithpath = os.path.join(sfilepath, sfilename)
        except Exception, e:
            serr = (self.sclsnme + '::' + 'doesFileExist(...)' + ':'
                    + 'os.path.join(' + sfilepath + ', ' + sfilename
                    +  '), ' + str(e))
            prntErrWarnInfo(serr, bresume = True)
            return False

        try:
            return os.path.isfile(sfilewithpath)
        except Exception, e:
            serr = (self.sclsnme + '::' + 'doesFileExist(...)' + ':'
                    + 'os.path.isfile(' + sfilewithpath + '), ' + str(e))  
            prntErrWarnInfo(serr, bresume = True)
            return False

        return True


    def doFilesExist(self, tfilenames, sfilepath):
        '''
            Method to check the existance of files.
        '''

        if not self.__isInstance(tfilenames, 'doFilesExist', 'tuple'):
            return False

        for ifl in tfilenames:
            if not self.doesFileExist(ifl, sfilepath):
                return False
        
        return True 


    def createDirIfNotThere(self, sdirname, sdirpath):
        '''
            Method to create directory in case does not exist.
        '''
        
        if not self.__isInstance(sdirname, 'createDirIfNotThere', 'string'):
            return False
           
        if not self.__isInstance(sdirpath, 'createDirIfNotThere', 'string'):
            return False

        sdirwithpath = ''
        try:
            sdirwithpath = os.path.join(sdirpath, sdirname)
        except Exception, e:
            serr = (self.sclsnme + '::' + 'createDirIfNotThere(...)' + ':'
                    + 'os.path.join(' + sdirpath + ', ' + sdirname
                    +  '), ' + str(e))
            prntErrWarnInfo(serr, bresume = True)
            return False

        if not os.path.isdir(sdirwithpath):
            try:
                os.mkdir(sdirwithpath)
            except Exception, e:
                serr = (self.sclsnme + '::' + 'createDirIfNotThere(...)' 
                        + ':' + 'os.mkdir(' + sdirwithpath + '), '
                        + str(e))
                prntErrWarnInfo(serr, bresume = True)
                return False

        return True 

 
    def createDirsIfNotThere(self, tdirsname, sdirpath):
        '''
            Method to create directories in case do not exist.
        '''
        
        if not self.__isInstance(tdirsname, 'createDirsIfNotThere', 'tuple'):
            return False

        for idir in tdirsname:
            if not self.createDirIfNotThere(idir, sdirpath):
                return False

        return True


    def isInternetAlive(self):
        '''
            Method to return status of internet in host machine.
        '''

        try:
            self.osckt = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        except Exception, e:
            serr = (self.sclsnme + '::' + 'isInternetAlive(...)' + ':' 
                    + 'socket(AF_INET, SOCK_STREAM)' + ', ' + str(e))
            prntErrWarnInfo(serr, bresume = True)
            return False

        try:
            self.osckt.connect(self.taddrprt)
        except Exception, e:
            serr = (self.sclsnme + '::' + 'isInternetAlive(...)' + ':'
                    + 'connect(' + str(self.taddrprt) + '), ' + str(e))
            prntErrWarnInfo(serr, bresume = True)
            return False

        return True


    def setupLogging(self):
        '''
            Method to setup logging operation.
        '''

        try:
            self.ologfl = logging.getLogger(self.smdlenme) 
        except Exception, e:
            serr = (self.sclsnme + '::' + 'setupLogging(...)' + ':'
                    + 'logging.getLogger(' + self.smdlenme + '), ' + str(e))
            prntErrWarnInfo(serr, bresume = True)
            return False

        try:
            self.ologfl.setLevel(logging.DEBUG)
        except Exception, e:
            serr = (self.sclsnme + '::' + 'setupLogging(...)' + ':'
                    + 'setLevel(logging.DEBUG)' + ', ' + str(e))
            prntErrWarnInfo(serr, bresume = True)
            return False
         
        ocnslhndlr = None
        try:    
            ocnslhndlr = logging.FileHandler(self.slogflnme)
            ocnslhndlr.setLevel(logging.DEBUG)
        except Exception, e:
            serr = (self.sclsnme + '::' + 'setupLogging(...)' + ':'
                    + 'logging.FileHandler()' + ', ' + str(e))
            prntErrWarnInfo(serr, bresume = True)
            return False

        ofrmtr = None
        sfrmt  = "%(asctime)s - %(name)s - %(levelname)s - %(message)s"
        try:
            ofrmtr = logging.Formatter(sfrmt)
        except Exception, e:
            serr = (self.sclsnme + '::' + 'setupLogging(...)' + ':'
                    + 'logging.Formatter(' + sfrmt + '), ' + str(e))
            prntErrWarnInfo(serr, bresume = True)
            return False

        try:
            ocnslhndlr.setFormatter(ofrmtr)
        except Exception, e:
            serr = (self.sclsnme + '::' + 'setupLogging(...)' + ':'
                    + 'setFormatter(' + str(ofrmtr) + '), ' + str(e))
            prntErrWarnInfo(serr, bresume = True)
            return False

        try:
            self.ologfl.addHandler(ocnslhndlr)
        except Exception, e:
            serr = (self.sclsnme + '::' + 'setupLogging(...)' + ':'
                    + 'addHandler(' + str(ocnslhndlr) + '), ' + str(e))
            prntErrWarnInfo(serr, bresume = True)
            return False

        self.blgngenbld = True
        return True


    def prntLogErrWarnInfo(self, smsg, smsgtype = 'err', bresume = False, blogging = True, bprint = True):
        '''
            Method to print/log error/warning/info messages.
        '''
        
        if not self.__isInstance(smsg, 'prntLogErrWarnInfo', 'string'):
            return False

        if not self.__isInstance(smsgtype, 'prntLogErrWarnInfo', 'string'):
            return False

        if not self.__isInstance(bresume, 'prntLogErrWarnInfo', 'boolean'):
            return False

        if not self.__isInstance(blogging, 'prntLogErrWarnInfo', 'boolean'):
            return False

        if not self.__isInstance(bprint, 'prntLogErrWarnInfo', 'boolean'):
            return False

        if smsgtype not in self.dmsgtype.keys():
            serr = (self.sclsnme + '::' + 'prntLogErrWarnInfo(...)' + ':'
                    + 'smsgtype should be \'err\', \'warn\' or \'info\'.') 
            prntErrWarnInfo(serr, bresume = True)
            return False
 
        if not self.blgngenbld:
            serr = (self.sclsnme + '::' + 'prntLogErrWarnInfo(...)' + ':'
                    + 'logging is not enabled so call setupLogging(...) first.')
            prntErrWarnInfo(serr, bresume = True)
            return False

        if blogging:
            if 'err' == smsgtype:
                self.ologfl.error(smsg)
            elif 'warn' == smsgtype:
                self.ologfl.warn(smsg)
            elif 'info' == smsgtype:
                self.ologfl.info(smsg)

        smsgtoshow = (time.asctime() + ' ' + self.smsgseprtr + ' '
                      + self.smdlenme + ' ' + self.smsgseprtr + ' '
                      + self.dmsgtype[smsgtype] + ' ' + self.smsgseprtr + ' '
                      + smsg)
        if bprint:	
            print smsgtoshow

        if not bresume:
            self.ologfl.info('not resuming, exiting ...')
            exit(-1)
        else:
            return True 


    def setupConfigFlOprtn(self):
        '''
            Method to setup config file operation.
        '''

        try:
            self.ocnfgfl = ConfigParser.SafeConfigParser()
        except Exception, e:
            serr = (self.sclsnme + '::' + 'setupConfigFlOprtn(...)' + ':' 
                    + 'ConfigParser.SafeConfigParser()' + ', ' + str(e))
            prntErrWarnInfo(serr, bresume = True)
            return False

        try:
            self.ocnfgfl.read(self.scnfgflnme)
        except Exception, e:
            serr = (self.sclsnme + '::' + 'setupConfigFlOprtn(...)' + ':'
                    + 'read(' + self.scnfgflnme + '), ' + str(e))
            prntErrWarnInfo(serr, bresume = True)
            return False

        return True


    def getSctnsFromConfigFl(self):
        '''
            Method to get a tuple of sections in config file.
        '''

        if not self.ocnfgfl:
            return (), False
        
        try:
            return tuple(self.ocnfgfl.sections()), True
        except Exception, e:
            serr = ('%s :: getSctnsFromConfigFl(...) : sections(...), '
                    '%s' %(self.sclsnme, str(e)))
            prntErrWarnInfo(serr, bresume = True)
            return (), False


    def getOptsFromConfigFl(self, ssection):
        '''
            Method to get a tuple of options under a section.
        '''

        if not self.ocnfgfl:
            return (), False
            
        if not self.__isInstance(ssection, 'getOptsFromConfigFl', 'string'):
            return (), False

        try:
            return tuple(self.ocnfgfl.options(ssection)), True
        except Exception, e:
            serr = ('%s :: getOptsFromConfigFl(...) : options(...), '
                    '%s' %(self.sclsnme, str(e)))
            prntErrWarnInfo(serr, bresume = True)
            return (), False


    def getItemsFromConfigFl(self, ssection):
        '''
            Method to get a tuple of option,value pairs under a section.
        '''

        if not self.ocnfgfl:
            return ((), False)
            
        if not self.__isInstance(ssection, 'getItemsFromConfigFl', 'string'):
            return ((), False)

        try:
            return (tuple(self.ocnfgfl.items(ssection)), True)
        except Exception, e:
            serr = ('%s :: getOptsFromConfigFl(...) : items(...), '
                    '%s' %(self.sclsnme, str(e)))
            prntErrWarnInfo(serr, bresume = True)
            return ((), False)


    def getValFromConfigFl(self, ssection, soption):
        '''
            Method to get value corresponding to a section and option.
        '''
        
        if not self.ocnfgfl:    
            return False

        if not self.__isInstance(ssection, 'getValFromConfigFl', 'string'):
            return False

        if not self.__isInstance(soption, 'getValFromConfigFl', 'string'):
            return False

        try:
            return self.ocnfgfl.get(ssection, soption)
        except Exception, e:
            serr = (self.sclsnme + '::' + 'getValFromConfigFl(...)' + ':'
                    + 'get(' + ssection + ', ' + soption + '), ' + str(e))
            prntErrWarnInfo(serr, bresume = True)
            return False


    def modifyConfigFile(self, scnfgfl, scnfgflpth, soldstng, snewstng):
        '''
            Method to modify old setting with new setting in config file.
        '''

        if not self.__isInstance(scnfgfl, 'modifyConfigFile', 'string'):
            return False

        if not self.__isInstance(scnfgflpth, 'modifyConfigFile', 'string'):
            return False

        if not self.__isInstance(soldstng, 'modifyConfigFile', 'string'):
            return False

        if not self.__isInstance(snewstng, 'modifyConfigFile', 'string'):
            return False
        
        return True


    def parseCmdLine(self, doptsargs, tposargs = (), susage = '', bminposargs = False, bexactposargs = True):
        '''
            Method to parse command line options and arguments.
        '''

        if not self.__isInstance(doptsargs, 'parseCmdLine', 'dictionary'):
            return False

        if not self.__isInstance(susage, 'parseCmdLine', 'string'):
            return False
        
        try:
            oparser = OptionParser(susage)
        except Exception, e:
            serr = (self.sclsnme + '::' + 'parseCmdLine(...)' + ':'
                    + 'OptionParser(), ' + str(e))
            prntErrWarnInfo(serr, bresume = True)
            return False 

        for ilngopt in doptsargs:
            try:
                if doptsargs[ilngopt]['action'] == 'store_true' \
                   or doptsargs[ilngopt]['action'] == 'store_false':
                       oparser.add_option(
                           doptsargs[ilngopt]['shortopt'],
                           doptsargs[ilngopt]['longopt'],
                           dest = doptsargs[ilngopt]['dest'],
                           action = doptsargs[ilngopt]['action'],
                           help = doptsargs[ilngopt]['help']
                          )
                else:
                    if doptsargs[ilngopt].has_key('nargs'):
                        oparser.add_option(
                            doptsargs[ilngopt]['shortopt'],
                            doptsargs[ilngopt]['longopt'],
                            type = doptsargs[ilngopt]['type'],
                            dest = doptsargs[ilngopt]['dest'],
                            nargs = doptsargs[ilngopt]['nargs'], 
                            action = doptsargs[ilngopt]['action'],
                            help = doptsargs[ilngopt]['help']
                           )
                    else: 
                        oparser.add_option(
                            doptsargs[ilngopt]['shortopt'],
                            doptsargs[ilngopt]['longopt'],
                            type = doptsargs[ilngopt]['type'],
                            dest = doptsargs[ilngopt]['dest'],
                            default = doptsargs[ilngopt]['default'],
                            action = doptsargs[ilngopt]['action'],
                            help = doptsargs[ilngopt]['help']
                        )
                      
            except Exception, e:
                serr = (self.sclsnme + '::' + 'parseCmdLine(...)' + ':'
                        + 'add_option(' + doptsargs[ilngopt]['shortopt']
                        + ', ' + doptsargs[ilngopt]['longopt'] + ', '
                        + doptsargs[ilngopt]['type'] + ', '
                        + doptsargs[ilngopt]['dest'] + ', '
                        + str(doptsargs[ilngopt]['default']) + ', '
                        + str(doptsargs[ilngopt]['action']) + ', '
                        + doptsargs[ilngopt]['help'] + ', ' + str(e)
                        + ')') 
                prntErrWarnInfo(serr, bresume = True)
                return False

        (options, args) = oparser.parse_args()          
        
        if bminposargs:
            if len(tposargs) > len(args):
                oparser.error(' incorrect number of minimum arguments.')

        if bexactposargs:
            if len(tposargs) != len(args):
                oparser.error(' incorrect number of exact arguments.')
        
        return (options, args)


    def sshConnect(self, sipadr, susrnme, spswrd, iport = 22):
        '''
            Method to connect to remote SSH server.
        '''

        if not self.__isInstance(sipadr, 'sshConnect', 'string'):
            return False 

        if not self.__isInstance(susrnme, 'sshConnect', 'string'):
            return False 

        if not self.__isInstance(spswrd, 'sshConnect', 'string'):
            return False

        if not self.__isInstance(iport, 'sshConnect', 'integer'):
            return False

        try:
            self.ossh = paramiko.SSHClient()
        except Exception, e:
            serr = ('%s :: sshConnect(...) : SSHClient(), %s' \
                     %(self.sclsnme, str(e)))
            prntErrWarnInfo(serr, bresume = True)
            return False

        try:
            if None != self.ossh:
                self.ossh.set_missing_host_key_policy( \
                    paramiko.AutoAddPolicy())
            else:
                return False
        except Exception, e:
            serr = ('%s :: sshConnect(...) : set_missing_host_key_policy \
                    (AutoAddPolicy()), %s' %(self.sclsnme, str(e)))
            prntErrWarnInfo(serr, bresume = True)
            return False

        try:
            self.ossh.connect(sipadr, username = susrnme, \
                              password = spswrd, port = iport)
        except Exception, e:
            serr = ('%s :: sshConnect(...) : connect(...), %s' \
                     %(self.sclsnme, str(e)))
            prntErrWarnInfo(serr, bresume = True)
            return False

        return True 
 

    def sshTrnsfrFile(self, sflnme, slclpth, srmtpth, bputget = True):
        '''
            Method to put file to or get from remote SSH server.
        '''

        if not self.__isInstance(sflnme, 'sshTrnsfrFile', 'string'):
            return False

        if not self.__isInstance(slclpth, 'sshTrnsfrFile', 'string'):
            return False
        
        if not self.__isInstance(srmtpth, 'sshTrnsfrFile', 'string'):
            return False

        if not self.__isInstance(bputget, 'sshTrnsfrFile', 'boolean'):
            return False
        
        slclflewthpth = ''
        srmtflewthpth = ''
        try:
            slclflewthpth = os.path.join(slclpth, sflnme)
        except Exception, e:
            serr = (self.sclsnme + '::' + 'sshTrnsfrFile(...)' + ':'
                    + 'os.path.join(' + slclpth + ', ' + sflnme
                    +  '), ' + str(e))
            prntErrWarnInfo(serr, bresume = True)
            return False
        
        if bputget: 
            if not os.path.isfile(slclflewthpth):
                serr = ('%s :: sshTrnsfrFile() : %s does not exist.'
                        %(self.sclsnme, slclflewthpth))
                prntErrWarnInfo(serr, bresume = True)
                return False
        try:
            srmtflewthpth = posixpath.join(srmtpth, sflnme)
        except Exception, e:
            serr = (self.sclsnme + '::' + 'sshTrnsfrFile(...)' + ':'
                    + 'posixpath.join(' + srmtpth + ', ' + sflnme
                    +  '), ' + str(e))
            prntErrWarnInfo(serr, bresume = True)
            return False
        
        try:
	    self.oscp = self.ossh.open_sftp()
        except Exception, e:
            serr = ('%s :: sshTrnsfrFile(...) : open_sftp(), %s' \
		     %(self.sclsnme, str(e)))	    
            prntErrWarnInfo(serr, bresume = True)
	    return False

        if bputget:
            try:
	        self.oscp.put(slclflewthpth, srmtflewthpth)
	    except Exception, e:
	        serr = ('%s :: sshTrnsfrFile(...) : put(%s, %s), %s' \
			%(self.sclsnme, slclflewthpth, srmtflewthpth,\
			  str(e)))
		prntErrWarnInfo(serr, bresume = True)
		return False
	else:
            try:
	        self.oscp.get(srmtflewthpth, slclflewthpth)
	    except Exception, e:
	        serr = ('%s :: sshTrnsfrFile(...) : get(%s, %s), %s' \
			%(self.sclsnme, srmtflewthpth, slclflewthpth,\
			  str(e)))
		prntErrWarnInfo(serr, bresume = True)
		return False

	self.oscp.close()

	return True


    def sshTrnsfrFiles(self, tflnmes, slclpth, srmtpth, bputget = True):
        '''
            Method to put files to or get from remote SSH server.
        '''

        if not self.__isInstance(tflnmes, 'sshTrnsfrFiles', 'tuple'):
            return False
        
        for i in tflnmes:
            self.sshTrnsfrFile(i, slclpth, srmtpth, bputget)

        return True


    def execCmnd(self, scmnd, bret = False, bshell = False):
        '''
            Method to execute command string.
        '''

        if not self.__isInstance(scmnd, 'execCmnd', 'string'):
            return ([], [], -1, False)

        if not self.__isInstance(scmnd, 'execCmnd', 'string'):
            return ([], [], -1, False)
        
        if not self.__isInstance(bret,  'execCmnd', 'boolean'):
            return ([], [], -1, False)

        if not self.__isInstance(bshell, 'execCmnd', 'boolean'):
            return ([], [], -1, False)

        l = []
        try:
            l = shlex.split(scmnd)
        except Exception, e:
            serr = ('%s :: execCmnd(...) : shlex(%s), %s'
                    %(self.sclsnme, scmnd, str(e)))
            prntErrWarnInfo(serr, bresume = True)
            return ([], [], -1, False)

        op = None
        try:
            op = subprocess.Popen(l, stdout = subprocess.PIPE,
                                     shell = bshell,
                                     stderr = subprocess.STDOUT
                                 )
        except Exception, e:
            serr = ('%s :: execCmnd(...) : Popen(...), %s'
                    %(self.sclsnme, str(e)))
            prntErrWarnInfo(serr, bresume = True)
            return ([], [], -1, False)

        if bret:
            return ([], [], 0, True)

        toe = ()
        try:
            toe = op.communicate()
            return (toe[0], toe[1], op.returncode, True)
        except Exception, e:
            serr = ('%s :: execCmnd(...) : communicate(), %s'
                    %(self.sclsnme, str(e)))
            prntErrWarnInfo(serr, bresume = True)
            return ([], [], -1, False)


    def psexecCmnd(self, scmnd, shost, suser, spswrd, bret = False, bshell = False):
        '''
            Method to execute command string on remote Win nodes.
        '''

        if not self.__isInstance(scmnd, 'psexecCmnd', 'string'):
            return ([], [], -1, False)

        if not self.__isInstance(shost, 'psexecCmnd', 'string'):
            return ([], [], -1, False)
        
        if not self.__isInstance(suser, 'psexecCmnd', 'string'):
            return ([], [], -1, False)

        if not self.__isInstance(spswrd, 'psexecCmnd', 'string'):
            return ([], [], -1, False)
        
        if not self.__isInstance(bret,  'psexecCmnd', 'boolean'):
            return ([], [], -1, False)

        if not self.__isInstance(bshell, 'psexecCmnd', 'boolean'):
            return ([], [], -1, False)

	if not sys.platform.upper().startswith("WIN"):
            serr = ('%s :: psexecCmnd(...) : only implemented for Windows'
                    %self.sclsnme)
            prntErrWarnInfo(serr, bresume = True)
            return ([], [], -1, False)

        scmnd = r"psexec \\%s -u %s -p %s %s" %(shost, suser, spswrd, scmnd)

        l = []
        try:
            l = shlex.split(scmnd, posix=False)
        except Exception, e:
            serr = ('%s :: psexecCmnd(...) : shlex(%s), %s'
                    %(self.sclsnme, scmnd, str(e)))
            prntErrWarnInfo(serr, bresume = True)
            return ([], [], -1, False)

        op = None
        try:
            op = subprocess.Popen(l, stdout = subprocess.PIPE,
                                     shell = bshell,
                                     stderr = subprocess.STDOUT
                                 )
        except Exception, e:
            serr = ('%s :: psexecCmnd(...) : Popen(...), %s'
                    %(self.sclsnme, str(e)))
            prntErrWarnInfo(serr, bresume = True)
            return ([], [], -1, False)

        if bret:
            return ([], [], 0, True)

        toe = ()
        try:
            toe = op.communicate()
            return (toe[0], toe[1], op.returncode, True)
        except Exception, e:
            serr = ('%s :: psexecCmnd(...) : communicate(), %s'
                    %(self.sclsnme, str(e)))
            prntErrWarnInfo(serr, bresume = True)
            return ([], [], -1, False)


    def psinfoCmnd(self, shost, suser, spswrd, bbasic = True, bshell = False):
        '''
            Method to dump info from remote Win nodes.
        '''

        if not self.__isInstance(shost, 'psinfoCmnd', 'string'):
            return ([], [], -1, False)
        
        if not self.__isInstance(suser, 'psinfoCmnd', 'string'):
            return ([], [], -1, False)

        if not self.__isInstance(spswrd, 'psinfoCmnd', 'string'):
            return ([], [], -1, False)
        
        if not self.__isInstance(bbasic,  'psinfoCmnd', 'boolean'):
            return ([], [], -1, False)

        if not self.__isInstance(bshell, 'psinfoCmnd', 'boolean'):
            return ([], [], -1, False)

        if bbasic:
          scmnd = r"psinfo \\%s -u %s -p %s -d" %(shost, suser, spswrd)
        else:	  
          scmnd = r"psinfo \\%s -u %s -p %s -d -h -s" %(shost, suser, spswrd)

        l = []
        try:
            l = shlex.split(scmnd, posix=False)
        except Exception, e:
            serr = ('%s :: psinfoCmnd(...) : shlex(%s), %s'
                    %(self.sclsnme, scmnd, str(e)))
            prntErrWarnInfo(serr, bresume = True)
            return ([], [], -1, False)

        op = None
        try:
            op = subprocess.Popen(l, stdout = subprocess.PIPE,
                                     shell = bshell,
                                     stderr = subprocess.STDOUT
                                 )
        except Exception, e:
            serr = ('%s :: psinfoCmnd(...) : Popen(...), %s'
                    %(self.sclsnme, str(e)))
            prntErrWarnInfo(serr, bresume = True)
            return ([], [], -1, False)

        toe = ()
        try:
            toe = op.communicate()
            return (toe[0], toe[1], op.returncode, True)
        except Exception, e:
            serr = ('%s :: psinfoCmnd(...) : communicate(), %s'
                    %(self.sclsnme, str(e)))
            prntErrWarnInfo(serr, bresume = True)
            return ([], [], -1, False)


    def sshExecCmnd(self, scmnds, ssupswd = ''):
        '''
            Method to execute commands string remotely.
        '''

        if not self.__isInstance(scmnds, 'sshExecCmnd', 'string'):
            return ([], [], False)

        if not self.__isInstance(ssupswd, 'sshExecCmnd', 'string'):
            return ([], [], False)

        try:
            oi, oo, oe = self.ossh.exec_command(scmnds)
            if 0 < len(ssupswd):
                si = '%s\n' %ssupswd
                oi.write(si)
                oi.flush()
            return oo.readlines(), oe.readlines(), True   
        except Exception, e:
            serr = ('%s :: sshExecCmnd(...) : exec_command(%s), %s' \
                    %(self.sclsnme, scmnds, str(e)))    
            prntErrWarnInfo(serr, bresume = True)
            return [], [], False


    def sshDisconnect(self):
        '''
            Method to disconnect from remote SSH server.
        '''

        if None != self.ossh:
            self.ossh.close()

        return True


def main(opygenericroutines):
    '''
        Main application driver routine.
    '''

    opygenericroutines.backupFile(opygenericroutines.slogflnme, '.')

    if opygenericroutines.setupLogging():
        sintrntstts = 'Internet status : '
        if opygenericroutines.isInternetAlive():
            sintrntstts = sintrntstts + 'Alive.'
        else:
            sintrntstts = sintrntstts + 'Dead.'
        opygenericroutines.prntLogErrWarnInfo(sintrntstts, smsgtype = 'info', bresume = True)
                

    if opygenericroutines.setupConfigFlOprtn():
        snamefirst = opygenericroutines.getValFromConfigFl('name', 'first')
        if snamefirst:
            opygenericroutines.prntLogErrWarnInfo(snamefirst, smsgtype = 'info')


if '__main__' == __name__:
    '''
        Routine to run in case file is not imported as a module.
    '''

    opygenericroutines = PyGenericRoutines('PyGenericRoutines')
    main(opygenericroutines)

