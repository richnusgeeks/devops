#! /usr/bin/env python
############################################################################
# File name : trigger_jenkins_jobs.py 
# Purpose   : A Python utility to trigger Jenkins jobs.
# Usages    : python trigger_jenkins_jobs.py
# Start date : 02/20/2014                                                  
# End date   : 02/20/2014                                                  
# Author     : Ankur Kumar <richnusgeeks@gmail.com>                           
# Download link : http://www.richnusgeeks.me                              
# License       : RichNusGeeks                                                  
# Version       : 0.0.1                                                    
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
    from jenkinsapi import jenkins 
except Exception, e:
    serr = '%s, %s' %('from jenkinsapi import jenkins', str(e))
    prntErrWarnInfo(serr)

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
class TriggerToolchainJobs:

    def __init__(self):
        self.sclsnme = self.__class__.__name__	    
        self.opygenericroutines = PyGenericRoutines(self.sclsnme)
        self.opygenericroutines.setupLogging()
        self.bcnfgfloprtn = self.opygenericroutines.setupConfigFlOprtn()
        self.senv = ''	
        self.snodes = ''
        self.sloginuser = ''	
        self.sloginpswd = ''
        self.djobs = {
                      '' : {
                                                      '' : '',
						      '' : '',
						      },
                     }		      

    def cacheValsFromCnfgFl(self):
        ssection = os.path.basename(sys.argv[0]).split('.')[0]
        sreturn = ''

        try:
            sreturn = self.opygenericroutines.getValFromConfigFl(\
                      ssection, 'ENV')
            if sreturn:
                self.senv = sreturn.strip()
        except Exception, e:
            serr = ('%s::cacheValsFromCnfgFl(...):\
                     getValFromConfigFile(\'LOGINPSWD\'), %s'
                     %(self.sclsnme, str(e)))
            self.opygenericroutines.prntLogErrWarnInfo(serr,\
                                                       smsgtype = 'err',\
                                                       bresume = True)
            return False

        try:
            sreturn = self.opygenericroutines.getValFromConfigFl(\
                      ssection, 'LOGINUSR')
            if sreturn:
                self.sloginusr = sreturn.strip()
        except Exception, e:
            serr = ('%s::cacheValsFromCnfgFl(...):\
                     getValFromConfigFile(\'LOGINUSR\'), %s'
                     %(self.sclsnme, str(e)))
            self.opygenericroutines.prntLogErrWarnInfo(serr,\
                                                       smsgtype = 'err',\
                                                       bresume = True)
            return False

        try:
            sreturn = self.opygenericroutines.getValFromConfigFl(\
                      ssection, 'LOGINPSWD')
            if sreturn:
                self.sloginpswd = sreturn.strip()
        except Exception, e:
            serr = ('%s::cacheValsFromCnfgFl(...):\
                     getValFromConfigFile(\'LOGINPSWD\'), %s'
                     %(self.sclsnme, str(e)))
            self.opygenericroutines.prntLogErrWarnInfo(serr,\
                                                       smsgtype = 'err',\
                                                       bresume = True)
            return False

        try:
            sreturn = self.opygenericroutines.getValFromConfigFl(\
                      ssection, 'NODES')
            if sreturn:
                self.snodes = sreturn.strip()
        except Exception, e:
            serr = ('%s::cacheValsFromCnfgFl(...):\
                     getValFromConfigFile(\'NODES\'), %s'
                     %(self.sclsnme, str(e)))
            self.opygenericroutines.prntLogErrWarnInfo(serr,\
                                                       smsgtype = 'err',\
                                                       bresume = True)
            return False

        return True


    def preChecks(self):
	if not self.senv:
            serr = 'Empty ENV string in config.conf'
            self.opygenericroutines.prntLogErrWarnInfo(serr)

        if not self.snodes:
            serr = 'Empty NODES list in config.conf'		
            self.opygenericroutines.prntLogErrWarnInfo(serr)

	if not self.sloginusr:
            serr = 'Empty LOGINUSR string in config.conf'
            self.opygenericroutines.prntLogErrWarnInfo(serr)	    

        if not self.sloginpswd:
            serr = 'Empty LOGINPSWD string in config.conf'
            self.opygenericroutines.prntLogErrWarnInfo(serr)


    def trgrTlchnJbs(self):
        url = 'http://%s-' %(self.senv.lower())

        try:
            j = jenkins.Jenkins(url, self.sloginusr, self.sloginpswd)
        except Exception, e:
            serr = ('%s::trgrTlchnJbs():\
                     Jenkins(%s, %s, %s), %s'
                     %(self.sclsnme, url, self.sloginusr, self.sloginpswd, str(e)))			 		
            self.opygenericroutines.prntLogErrWarnInfo(serr)

        try:
            if not j.has_job(self.djobs.keys()[0]):
	        serr = "No %s job in %s toolchain" %(self.djobs.keys()[0], self.senv)
                self.opygenericroutines.prntLogErrWarnInfo(serr)
	except Exception, e:
            serr = ('%s::trgrTlchnJbs():\
                     has_job(%s), %s'
                     %(self.sclsnme, self.djobs.keys()[0], str(e)))			 		
            self.opygenericroutines.prntLogErrWarnInfo(serr)

	self.djobs[self.djobs.keys()[0]]['FQDN'] = self.snodes
        #self.djobs[self.djobs.keys()[0]]['Environment'] = self.senv

	try:
            sinfo = 'Triggering job %s in %s toolchain' %(self.djobs.keys()[0], self.senv)
	    self.opygenericroutines.prntLogErrWarnInfo(sinfo, smsgtype='info', bresume=True)
	    
            j.build_job(self.djobs.keys()[0], self.djobs[self.djobs.keys()[0]])
	except Exception, e:
            serr = ('%s::trgrTlchnJbs():\
                     build_job(%s, %s), %s'
                     %(self.sclsnme, self.djobs.keys()[0], str(self.djobs[self.djobs.keys()[0]]), str(e)))			 		
            self.opygenericroutines.prntLogErrWarnInfo(serr)
	    

def main(otrgrtlchnjbs):
    if otrgrtlchnjbs.cacheValsFromCnfgFl():
        otrgrtlchnjbs.preChecks()
        otrgrtlchnjbs.trgrTlchnJbs()


if '__main__' == __name__:
    otrgrtlchnjbs = TriggerToolchainJobs()
    main(otrgrtlchnjbs)

