from machine import Pin, reset, Signal
from os import uname
from random import randint
from time import sleep

pfrm = uname()[-1].split()[-1].replace('-','')
ahgh = True
bflag = False
tdly = 0.1

#pbtn = Pin(5, Pin.IN)
eleds = (
          Signal(Pin(0, Pin.OUT), invert=not(ahgh)),
          Signal(Pin(1, Pin.OUT), invert=not(ahgh)),
          Signal(Pin(2, Pin.OUT), invert=not(ahgh)),
          Signal(Pin(3, Pin.OUT), invert=not(ahgh)),
          Signal(Pin(4, Pin.OUT), invert=not(ahgh)),
        )

'''def mtnhdlr(pin):
  if pin.value():
    print('Pressed!')  
    bflag = True
       
pbtn.irq(trigger=Pin.IRQ_RISING, handler=mtnhdlr)'''

def aledoff(eleds):
  eleds[0].off()
  eleds[1].off()
  eleds[2].off()
  eleds[3].off()
  eleds[4].off()
  
def rledon(eleds):
  eleds[0].on()
  eleds[1].off()
  eleds[2].off()
  eleds[3].off()
  eleds[4].off()
  
def yledon(eleds):
  eleds[0].off()
  eleds[1].on()
  eleds[2].off()
  eleds[3].off()
  eleds[4].off()
  
def gledon(eleds):
  eleds[0].off()
  eleds[1].off()
  eleds[2].on()
  eleds[3].off()
  eleds[4].off()
  
def bledon(eleds):
  eleds[0].off()
  eleds[1].off()
  eleds[2].off()
  eleds[3].on()
  eleds[4].off()
  
def wledon(eleds):
  eleds[0].off()
  eleds[1].off()
  eleds[2].off()
  eleds[3].off()
  eleds[4].on() 

aledoff(eleds)

def chaserlin():

  i = 0
  try:
    while True:
      if i > 4:
        i = 0
      
      if i == 0:
        rledon(eleds)
      elif i == 1:
        yledon(eleds)
      elif i == 2:
        gledon(eleds)
      elif i == 3:
        bledon(eleds)
      elif i == 4:
        wledon(eleds)
      
      i += 1
      sleep(0.1)
  except:
    aledoff(eleds)
    # due to reset the board got stuck in running
    # after copying main.py to it.
    #reset()
    
def chaserand(tdly):
  
  try:
    while True:
      i = randint(0,4)
      
      if i == 0:
        rledon(eleds)
      elif i == 1:
        yledon(eleds)
      elif i == 2:
        gledon(eleds)
      elif i == 3:
        bledon(eleds)
      elif i == 4:
        wledon(eleds)
      
      if bflag:
        tdly += 0.5

      sleep(tdly)
  except:
    aledoff(eleds)
    # due to reset the board got stuck in running
    # after copying main.py to it.
    #reset()
    
chaserand(tdly)  