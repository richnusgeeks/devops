from machine import Pin, soft_reset, Signal
from os import uname
from random import randint
from time import sleep

pfrm = uname()[-1].split()[-1].replace('-','')
tdly = 0.05
gnd = (
        
      )
pns = (
        (0, 1, 2),
        (4, 5, 6),
        (8, 9, 10),
        (12, 13, 14),
        (16, 17, 18),
        (20, 21, 22),
      )
# tuple([tuple(range(3*i,3*(i+1))) for i in range(0,4)])

def aledoff():
  [Pin(p,Pin.OUT).off() for g in pns for p in g]     

aledoff()
while True:
  try:    
    for g in pns:
      r = randint(0,2)
      Pin(g[r],Pin.OUT).on()
      d = randint(1,3) 
      sleep(d * tdly)
      aledoff()
  except:
    aledoff()
    if -1 == pfrm.find('ESP32C3'):
      soft_reset()