from machine import Pin, soft_reset
import os 
from time import sleep

tfl1 = {}
tfl1['rled'] = Pin(0, Pin.OUT)
tfl1['gled'] = Pin(1, Pin.OUT)
tfl1['yled'] = Pin(2, Pin.OUT)

tfl2 = {}
tfl2['rled'] = Pin(3, Pin.OUT)
tfl2['gled'] = Pin(4, Pin.OUT)
tfl2['yled'] = Pin(5, Pin.OUT)

def reset(tfl):
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
    gongrn(tfl2)
    sleep(5)
    readyonylw(tfl2)
    readybgrn(tfl1)
    sleep(2)
    stoponred(tfl2)
    gongrn(tfl1)
    sleep(5)
    readybgrn(tfl1)
    readybgrn(tfl2)
    sleep(2)
  except KeyboardInterrupt:
    reset(tfl1)
    reset(tfl2)
    soft_reset()