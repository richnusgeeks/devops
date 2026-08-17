from machine import Pin, Signal, soft_reset
from os import uname
from time import sleep

pfrm = uname()[-1].split()[-1]
ahgh = True

eleds = (
          Signal(Pin(0, Pin.OUT), invert=not(ahgh)),
          Signal(Pin(1, Pin.OUT), invert=not(ahgh)),
        )

flms = Signal(Pin(4, Pin.IN), invert=ahgh)

def aledoff():
  eleds[0].off()
  eleds[1].off()
  
def rledon():
  eleds[0].on()
  eleds[1].off()
  
def gledon():
  eleds[0].off()
  eleds[1].on()

aledoff()

try:
  while True:
    if flms.value():
      rledon()
      sleep(5)
    else:
      gledon()  
      sleep(0.5)
    
except:
  aledoff()
  if -1 == pfrm.find('ESP32C3'):
    soft_reset()