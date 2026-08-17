from machine import Pin
from time import sleep

touch = Pin(5, Pin.IN)
rled = Pin(0, Pin.OUT)
gled = Pin(1, Pin.OUT)
bled = Pin(3, Pin.OUT)

i = 0

while True:
  try:  
    if i > 2:
      i = 0  
    
    if i == 0:
      rled.value(touch.value())
      gled.off()
      bled.off()
    elif i == 1:
      gled.value(touch.value())
      rled.off()
      bled.off()
    elif i == 2:
      bled.value(touch.value())
      rled.off()
      gled.off()
      
    i += 1    
    sleep(0.5)
    
  except:
    rled.off()
    gled.off()
    bled.off()
    machine.reset()
