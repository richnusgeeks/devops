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
    msg = "%s <num secrets> <plaintext1> ... <plaintextN>"  %argv[0]
    prntErrWarnInfo(msg, "info")

  if argv[1] <= 0:
    msg = "num secrets sould be greater than 0"
    prntErrWarnInfo(msg)

def main():
  preChecks()

  with open(scrtfl, "wb") as outfile:
    try:
      key = Fernet.generate_key()
      outfile.write("%s\n" %key)
    except Exception, e:
      msg = "generate_key(),write(...), %s" %e
      prntErrWarnInfo(msg)

    try:
      f = Fernet(key)
    except Exception, e:
      msg = "Fernet(...), %s" %e
      prntErrWarnInfo(msg)

    try:
      outfile.write("%s\n" %(f.encrypt(argv[2])))
    except Exception, e:
      msg = "encrypt(...),write(...), %s" %e
      prntErrWarnInfo(msg)

    for e in argv[2:]:
      try:
        outfile.write("%s\n" %(f.encrypt(e)))
      except Exception, e:
        msg = "encrypt(...),write(...), %s" %e
        prntErrWarnInfo(msg)

if "__main__" == __name__:
  main()
