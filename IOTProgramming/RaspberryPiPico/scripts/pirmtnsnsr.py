from machine import Pin, soft_reset, Signal
from os import uname
from time import sleep

pfrm = uname()[-1].split()[-1].replace('-','')
ahgh = True

if -1 == pfrm.find('ESP32C3'):
  pirs = Pin(3, Pin.IN, Pin.PULL_DOWN)
else:
  pirs = Pin(3, Pin.IN, Pin.PULL_UP)
  
rgbl = {
          'red' : Signal(Pin(6, Pin.OUT), invert=not(ahgh)),
          'grn' : Signal(Pin(7, Pin.OUT), invert=not(ahgh)),
          'blu' : Signal(Pin(9, Pin.OUT), invert=not(ahgh)),
        }

def rledon():
  rgbl['red'].on()
  rgbl['grn'].off()
  rgbl['blu'].off()  

def gledon():
  rgbl['red'].off()
  rgbl['grn'].on()
  rgbl['blu'].off()  

def bledon():
  rgbl['red'].off()
  rgbl['grn'].off()
  rgbl['blu'].on()  

def aledoff():
  rgbl['red'].off()
  rgbl['grn'].off()
  rgbl['blu'].off()  

dly = 5
pln = 0.5

def mtnhdlr(pin):
  if pin.value():
    rledon()
    sleep(dly)
    bledon()
    sleep(1)

pirs.irq(trigger=Pin.IRQ_RISING, handler=mtnhdlr)

aledoff()

while True:
  try:
    if not pirs.value():  
      gledon()
      
    sleep(pln)
    
  except:
    aledoff()
    if -1 == pfrm.find('ESP32C3'):
      soft_reset()