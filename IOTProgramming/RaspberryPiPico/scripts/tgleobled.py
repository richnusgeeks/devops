from machine import Pin, reset
from time import sleep

pled = Pin("LED", Pin.OUT)
pled.off()
while True:
  try:  
    pled.toggle()
    sleep(1)
  except KeyboardInterrupt as e:
    pled.off()
    reset()
