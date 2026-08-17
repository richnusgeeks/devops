from machine import Pin, soft_reset, Signal
from os import uname
from random import randint
from time import sleep, ticks_ms, ticks_diff

pfrm = uname()[-1].split()[-1].replace('-','')
ahgh = True
tdly = 0.1
tsrt = 0
tmds = 0

eleds = (
          Signal(Pin(0, Pin.OUT), invert=not(ahgh)),
          Signal(Pin(1, Pin.OUT), invert=not(ahgh)),
          Signal(Pin(2, Pin.OUT), invert=not(ahgh)),
          Signal(Pin(3, Pin.OUT), invert=not(ahgh)),
          Signal(Pin(4, Pin.OUT), invert=not(ahgh)),
        )

mdbtn = Pin(14, Pin.IN, Pin.PULL_UP)
btnpc = 0

def aledoff():
  eleds[0].off()
  eleds[1].off()
  eleds[2].off()
  eleds[3].off()
  eleds[4].off()
  
def aledon():
  eleds[0].on()
  eleds[1].on()
  eleds[2].on()
  eleds[3].on()
  eleds[4].on()
  
def rledon():
  eleds[0].on()
  eleds[1].off()
  eleds[2].off()
  eleds[3].off()
  eleds[4].off()
  
def yledon():
  eleds[0].off()
  eleds[1].on()
  eleds[2].off()
  eleds[3].off()
  eleds[4].off()
  
def gledon():
  eleds[0].off()
  eleds[1].off()
  eleds[2].on()
  eleds[3].off()
  eleds[4].off()
  
def bledon():
  eleds[0].off()
  eleds[1].off()
  eleds[2].off()
  eleds[3].on()
  eleds[4].off()
  
def wledon():
  eleds[0].off()
  eleds[1].off()
  eleds[2].off()
  eleds[3].off()
  eleds[4].on() 

def chsrlinf(onet = False):
    
  i = 0
  try:
    while True:
      if i > 4:
        if onet:
          aledoff()
          break
        else: 
          i = 0
      
      if i == 0:
        rledon()
      elif i == 1:
        yledon()
      elif i == 2:
        gledon()
      elif i == 3:
        bledon()
      elif i == 4:
        wledon()
      
      i += 1
      sleep(tdly)
  except:
    aledoff()
    if -1 == pfrm.find('ESP32C3'):
      soft_reset()
    
def chsrlinb(onet = False):
    
  i = 0
  try:
    while True:
      if i > 4:
        if onet:
          aledoff()
          break
        else: 
          i = 0
      
      if i == 0:
        wledon()
      elif i == 1:
        bledon()
      elif i == 2:
        gledon()
      elif i == 3:
        yledon()
      elif i == 4:
        rledon()
      
      i += 1
      sleep(tdly)
  except:
    aledoff()
    if -1 == pfrm.find('ESP32C3'):
      soft_reset()

def chsrlinfb(onet = False):
    
  try:
    while True:    
      chsrlinf(True)
      sleep(tdly)
      chsrlinb(True)
      
      if onet:
        aledoff()
        break
  except:
    aledoff()
    if -1 == pfrm.find('ESP32C3'):
      soft_reset()

def chsrand():
  
  try:
    while True:
      i = randint(0,4)
      
      if i == 0:
        rledon()
      elif i == 1:
        yledon()
      elif i == 2:
        gledon()
      elif i == 3:
        bledon()
      elif i == 4:
        wledon()

      if onet:
        aledoff()
        break

      sleep(tdly)
  except:
    aledoff()
    if -1 == pfrm.find('ESP32C3'):
      soft_reset()

def randice(onet = False):
  
  try:
    while True:
      i = 0  
      while i < 2:  
        chsrlinf(True)
        sleep(tdly)
        chsrlinb(True)
        i += 1
  
      i = randint(1,6)
      sleep(2 * tdly)
      
      if i == 1:
        rledon()
      elif i == 2:
        yledon()
      elif i == 3:
        gledon()
      elif i == 4:
        bledon()
      elif i == 5:
        wledon()
      elif i == 6:
        aledon()  
      
      sleep(50 * tdly)
      
      if onet:
        aledoff()
        break
  except:
    aledoff()
    if -1 == pfrm.find('ESP32C3'):
      soft_reset()
  
#randice()
bnpc = 0
bnpf = False
aledoff()
tsrt = ticks_ms()

while True:
  try:  
    if 0 == mdbtn.value():
      bnpf = True  
      if bnpc > 4:
        bnpc = 0
      else:
        bnpc += 1
    else:
      tmds = ticks_diff(ticks_ms(), tsrt)
      if not bnpf and tmds > 10000:
        tmds = 0  
        bnpc = randint(1, 4)
        print(" ranint bnpc : %d" %bnpc)

    print(" bnpc : %d" %bnpc)
    
    if 1 == bnpc:
      chsrlinf(True)
    elif 2 == bnpc:
      chsrlinb(True)
    elif 3 == bnpc:
      chsrlinfb(True)
    elif 4 == bnpc:
      randice(True) 
    
    sleep(tdly)
      
  except Exception as e:
    print(e)  
    aledoff()
    if -1 == pfrm.find('ESP32C3'):
      soft_reset()        