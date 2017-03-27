#! /usr/bin/env python

from sys import argv
from cryptography.fernet import Fernet

if len(argv) != 4:
  print(" Usage: %s <aws access key> <aws private key> <gmail smtp password>"  %argv[0])
  exit()

scrtfl = "secrets.cfg"
with open(scrtfl, "wb") as outfile:
  try:
    key = Fernet.generate_key()
    outfile.write(key+"\n")
  except Exception, e:
    print(" Error: generate_key(),write(...), %s" %e)
    exit(-1)

  try:
    f = Fernet(key)
  except Exception, e:
    print(" Error: Fernet(...), %s" %e)
    exit(-1)

  for e in argv[1:]:
    outfile.write(f.encrypt(e)+"\n")

#with open(scrtfl, "rb") as infile:
#  try:
#    c = infile.readlines()
#  except Exception, e:
#
#try:
#  f = Fernet(c[0].strip())
#except Exception, e:
#
#try:
#  awsaky = f.decrypt(c[1].strip())
#except Exception, e:
#
#try:
#  awspky = f.decrypt(c[2].strip())
#except Exception, e:
#
