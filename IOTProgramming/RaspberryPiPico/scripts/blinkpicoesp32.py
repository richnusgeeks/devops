from machine import Pin, soft_reset, Signal
from os import uname
from time import sleep

pfrm = uname()[-1].split()[-1].replace('-','')
if -1 == pfrm.find('ESP32C3'):
  ahgh = True
else:
  ahgh = False
  
pled = "LED"
if -1 != pfrm.find('ESP32C3'):
  # onboard LED is invert logic based on ESP32C3 Super Mini
  pled = 8

led = Signal(Pin(pled, Pin.OUT), invert=not(ahgh))

tglf = True
while True:
  try:
    if tglf:
      led.on()
    else:
      led.off()  
    sleep(0.195)
    tglf = not(tglf)
  except:
    led.off()
    # due to reset the ESP32C3 board got stuck in running
    # after copying main.py to it.
    if -1 == pfrm.find('ESP32C3'):
      soft_reset()
