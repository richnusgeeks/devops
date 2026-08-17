from machine import Pin, soft_reset, Signal, ADC
from os import uname
from time import sleep

pfrm = uname()[-1].split()[-1].replace('-','')
if -1 == pfrm.find('ESP32C3'):
  ahgh = True
else:
  import esp32   
  ahgh = False
  
pled = "LED"
if -1 != pfrm.find('ESP32C3'):
  # onboard LED is invert logic based on ESP32C3 Super Mini
  pled = 8

iled = Signal(Pin(pled, Pin.OUT), invert=not(ahgh))

if -1 == pfrm.find('ESP32C3'):
  isnsr = ADC(4)
else:
  isnsr = None

tglf = True
while True:
  try:
    if tglf:
      iled.on()
    else:
      iled.off()
    
    if isnsr:
      conversion_factor = 3.3 / 65535
      reading = isnsr.read_u16() * conversion_factor
      # The temperature sensor measures the Vbe voltage of a biased bipolar diode, connected to the fifth ADC channel
      # Typically, Vbe = 0.706V at 27 degrees C, with a slope of -1.721mV (0.001721) per degree.
      itemp = 27 - (reading - 0.706)/0.001721
    else:
      itemp = esp32.mcu_temperature()
    print(" itemp : %.2f C" %itemp)

    sleep(1)
    tglf = not(tglf)
  except:
    iled.off()
    # due to reset the ESP32C3 board got stuck in running
    # after copying main.py to it.
    if -1 == pfrm.find('ESP32C3'):
      soft_reset()