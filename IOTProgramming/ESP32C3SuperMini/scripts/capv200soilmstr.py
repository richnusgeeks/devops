from machine import Pin, ADC
from time import sleep

# Configure ADC pin (GPIO4 used as an example)
adc = ADC(4)
adc.atten(ADC.ATTN_11DB) # Full range: 3.3V

# Calibration values (replace with your own)
min_moisture = 1400  # Dry air
max_moisture = 3000  # Submerged in water

while True:
    # Read raw analog value
    raw_value = adc.read()
    
    # Map the value to 0-100%
    moisture = (max_moisture - raw_value) * 100 / (max_moisture - min_moisture)
    
    # Ensure it stays within 0-100
    moisture = max(0, min(100, moisture))
    
    print("Raw: {}, Moisture: {:.1f}%".format(raw_value, moisture))
    
    sleep(1)