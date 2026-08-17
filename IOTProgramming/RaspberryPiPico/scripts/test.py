# docker run --device=/dev/ttyACM0:/dev/ttyACM0 pyboard -c 'from machine import Pin;Pin("LED", Pin.OUT).toggle()'
from machine import Pin

Pin("LED", Pin.OUT).toggle()

