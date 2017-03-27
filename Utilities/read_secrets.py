#! /usr/bin/env python
  
from sys import argv
from cryptography.fernet import Fernet

scrtfl = "secrets.cfg"
 
def prntErrWarnInfo(smsg, smsgtype = 'err', bresume = False):
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

def preChecks():
  if len(argv) < 2:
    msg = "%s <secret position>"  %argv[0]
    prntErrWarnInfo(msg, "info")
 
  if int(argv[1]) <= 0:
    msg = "position of secret sould be greater than 0"
    prntErrWarnInfo(msg)

def readSecret(pos):
  with open(scrtfl, "rb") as infile:
    try:
      c = infile.readlines()
    except Exception, e:
      msg = "readlines(), %s" %e
      prntErrWarnInfo(msg)
 
  try:
    f = Fernet(c[0].strip())
  except Exception, e:
    msg = "Fernet(...), %s" %e
    prntErrWarnInfo(msg)

  try:
    return f.decrypt(c[1+int(pos)].strip())
  except Exception, e:
    msg = "decrypt(...), %s" %e
    prntErrWarnInfo(msg)

def main():
  preChecks()
  print(readSecret(argv[1]))

if "__main__" == __name__:
  main()
