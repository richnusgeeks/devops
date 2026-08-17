from machine import Pin
import time

# Set the GPIO pin (e.g., Pin 3 for ESP32/Pico)
led = Pin(3, Pin.OUT)

# Turn it on - it will start cycling colors automatically
led.value(1) 

# Example: Run the cycle for 10 seconds, then turn off
time.sleep(10)
led.value(0)

# Example: Pulse the entire module on and off
while True:
    led.on()       # Module starts its internal color cycle
    time.sleep(5)  # Let it cycle for 5 seconds
    led.off()      # Turn off power to the module
    time.sleep(2)
