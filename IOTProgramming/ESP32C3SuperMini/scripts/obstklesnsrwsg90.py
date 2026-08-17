from machine import Pin, PWM, soft_reset, Signal
from os import uname
from time import sleep, sleep_ms

pfrm = uname()[-1].split()[-1]
ahgh = True

eleds = (
          Signal(Pin(0, Pin.OUT), invert=not(ahgh)),
          Signal(Pin(1, Pin.OUT), invert=not(ahgh)),
          #Signal(Pin(2, Pin.OUT), invert=not(ahgh)),
        )

esnsr = Signal(Pin(5, Pin.IN), invert=ahgh)

def aledoff():
  eleds[0].off()
  eleds[1].off()
  #eleds[2].off()
  
def rledon():
  eleds[0].on()
  eleds[1].off()
  #eleds[2].off()
  
def gledon():
  eleds[0].off()
  eleds[1].on()

servo = PWM(Pin(10))
servo.freq(50)  # Set PWM frequency to 50Hz, common for servo motors

# Function to calculate duty cycle for a specific angle
def set_angle(angle):
    # SG90 typically needs pulses between 0.5ms and 2.4ms depending on the brand.
    # We map 0-180 degrees to duty cycles (assuming a 20ms / 20000us period)
    # 0.5ms = 2.5% duty cycle = 500
    # 2.4ms = 12% duty cycle = 2400
    min_us = 500
    max_us = 2400
    
    pulse_width = min_us + (max_us - min_us) * angle / 180
    duty_u16 = int(pulse_width * 65535 / 20000)
    servo.duty_u16(duty_u16)

aledoff()

try:
  while True:
    if esnsr.value():
      rledon()
      set_angle(90)
      sleep(5)
    else:
      gledon()
      # Sweep the servo back from 180 to 0 degrees
      set_angle(0)
      sleep(0.5)
    
except:
    aledoff()
    set_angle(0)
    if -1 == pfrm.find('ESP32C3'):
      soft_reset()