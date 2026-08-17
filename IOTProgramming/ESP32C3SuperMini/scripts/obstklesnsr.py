from machine import Pin, soft_reset, Signal
from os import uname
from time import sleep

pfrm = uname()[-1].split()[-1]
ahgh = True

eleds = (
          Signal(Pin(0, Pin.OUT), invert=not(ahgh)),
          Signal(Pin(1, Pin.OUT), invert=not(ahgh)),
          Signal(Pin(2, Pin.OUT), invert=not(ahgh)),
        )

esnsr = Signal(Pin(5, Pin.IN), invert=ahgh)

def aledoff():
  eleds[0].off()
  eleds[1].off()
  eleds[2].off()
  
def rledon():
  eleds[0].on()
  eleds[1].off()
  eleds[2].off()
  
def gledon():
  eleds[0].off()
  eleds[1].on()
  eleds[2].off()
  
def bledon():
  eleds[0].off()
  eleds[1].off()
  eleds[2].on()

aledoff()

try:
  while True:
    if esnsr.value():
      rledon()
      sleep(5)
    else:
      gledon()  
      sleep(0.5)
except:
    aledoff()
    if -1 == pfrm.find('ESP32C3'):
      soft_reset()