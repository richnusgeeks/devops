from machine import Pin, soft_reset
from os import uname 
from time import sleep

pfrm = uname()[-1].split()[-1]

tfl1 = {}
tfl1['rled'] = Pin(0, Pin.OUT)
tfl1['gled'] = Pin(2, Pin.OUT)
tfl1['yled'] = Pin(1, Pin.OUT)

def rstlds(tfl):
  tfl['rled'].off()
  tfl['gled'].off()
  tfl['yled'].off()      

def stoponred(tfl):
  tfl['rled'].on()
  tfl['gled'].off()
  tfl['yled'].off()
 
def gongrn(tfl):
  tfl['rled'].off()
  tfl['gled'].on()
  tfl['yled'].off()
 
def readyonylw(tfl):
  tfl['rled'].off()
  tfl['gled'].off()
  tfl['yled'].on()
  
def readybgrn(tfl):
  tfl['gled'].off()
  tfl['yled'].on()
 
while True:
  try:
    stoponred(tfl1)
    sleep(5)
    readybgrn(tfl1)
    sleep(2)
    gongrn(tfl1)
    sleep(5)
    readybgrn(tfl1)
    sleep(2)
  except KeyboardInterrupt as e:
    rstlds(tfl1)
    if -1 == pfrm.find('ESP32C3'):
      soft_reset()