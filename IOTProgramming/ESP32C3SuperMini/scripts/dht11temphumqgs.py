import dht
from machine import Pin, ADC, Signal, soft_reset
from os import uname
import time

pfrm = uname()[-1].split()[-1].replace('-','')
if -1 != pfrm.find('ESP32C3'):
  import esp32
  iahgh = True
else:
  iahgh = False

pild = "LED"
if -1 != pfrm.find('ESP32C3'):
  # onboard LED is invert logic based on ESP32C3 Super Mini
  pild = 8
  
iled = Signal(Pin(pild, Pin.OUT), invert=iahgh)

ahgh = False
eleds = (
          Signal(Pin(0, Pin.OUT), invert=ahgh),
          Signal(Pin(1, Pin.OUT), invert=ahgh),
          Signal(Pin(3, Pin.OUT), invert=ahgh),
        )

if -1 == pfrm.find('ESP32C3'):
  isnsr = ADC(4)
else:
  isnsr = None  

esnsr = Pin(5)
esnsr = dht.DHT11(esnsr)

mq2ao = ADC(2)
if -1 != pfrm.find('ESP32C3'):
  mq2ao.atten(ADC.ATTN_11DB)

def aledoff():
  iled.off()
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

def getietemphdt():
  iled.on()  
  time.sleep(2)
  iled.off()
  
  if isnsr:
    conversion_factor = 3.3 / 65535
    reading = isnsr.read_u16() * conversion_factor
    # The temperature sensor measures the Vbe voltage of a biased bipolar diode, connected to the fifth ADC channel
    # Typically, Vbe = 0.706V at 27 degrees C, with a slope of -1.721mV (0.001721) per degree.
    itemp = 27 - (reading - 0.706)/0.001721
  else:
    itemp = esp32.mcu_temperature()  
  
  try:
    esnsr.measure()
  except Exception as e:
    print("%s" %e)
    iled.off()
    
  etemp = esnsr.temperature()
  hum   = esnsr.humidity()
  if -1 != pfrm.find('ESP32C3'):
    gsra  = mq2ao.read()
    gsrv  = (mq2ao.read_uv())/1000000
  else:
    gsra  = mq2ao.read_u16()
    gsrv  = gsra * (3.3 / 65535)
  
  
  if etemp <= 30.00:
    gledon()
  elif etemp > 30.00 and etemp <= 35.00:
    bledon()
  elif etemp > 35.00:
    rledon()  
  
  print("%.2f, %.2f, %.2f, %d, %.2f" %(itemp,etemp,hum,gsra,gsrv))
#  return "%.2f, %.2f, %.2f, %d, %.2f" %(itemp,etemp,hum)

while True:
  try:
    getietemphdt()
  except:
    aledoff()
    if -1 == pfrm.find('ESP32C3'):
      soft_reset()
