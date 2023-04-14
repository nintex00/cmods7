# -*- coding: utf-8 -*-
'''
File:         read_bram.py
Author:       funsten1
Description:  Reads the internal FPGA's block ram (BRAM) and saves the data
to a csv file and plots the data.
file.
Limitation:   
Copyright ©:  Lawrence Livermore National Laboratory
---------------------------------------------------------
---------------------------------------------------------

REVISION HISTORY

Date:         4/7/2023
Author:       funsten1
Description:  
Purpose:      

'''
import serial    # For pyserial class
import time      # For time delays
import binascii  # For handling ASCII, hex conversions
import os
import csv
import matplotlib.pyplot as plt # For plotting 

ser = serial.Serial(
                    port = "COM3",     # COM port for serial link
                    baudrate = 1e6, # baud rate in bits per second 
                    parity = 'O',      # Parity: either odd, 'O', or even, 'E'
                    stopbits = serial.STOPBITS_ONE, # One stop bit
                    timeout = 30, 
                    bytesize = serial.EIGHTBITS) # byte size is eight bits

ser.flushInput()
ser.isOpen()

# while(1):
# ser.write(binascii.a2b_hex('41')) # write a hex value in string format				
# time.sleep(0.1)
# estring = str(binascii.b2a_hex(ser.read(1)))[2:-1] # string
ser.write(binascii.a2b_hex('30')) # write a hex value in string format				
# time.sleep(0.1)
# estring = str(binascii.b2a_hex(ser.read(65536)))[2:-1] # string
estring = str(binascii.b2a_hex(ser.read(131072)))[2:-1] # string
# byteStrOut = binascii.b2a_hex(ser.read(4194304)) # byte out in HEX
# estring = str(binascii.b2a_hex(ser.read(4194304)))[2:-1] # string
# lengthBytes = int(len(estring)/2)
# print(estring)
    
ser.close() # close serial link

# Extract all hex string samples (2 bytes) in a list
hexStrList = []
j = 0
for i in range(int(len(estring)/4)):
      hexStrList.append(estring[j:j+4])
      j = j + 4
      

# Convert to decimal from hex
decimalList = []
for i in range(len(hexStrList)):
      decimalList.append(int(hexStrList[i],16))
      
      
writeFileName = 'read_bram_dump' + '.csv'
CSVheader = ['Sample Number', 'Hex Sample', 'Decimal Code']

      
with open(os.path.join(os.getcwd(), writeFileName), 'w',newline='') as f:
    writer = csv.writer(f)
    writer.writerow(CSVheader)

try:
    with open(os.path.join(os.getcwd(), writeFileName), 'a',newline='') as f:
        writer = csv.writer(f)
        for i in range(len(hexStrList)):
              writer.writerow( [i+1, hexStrList[i], decimalList[i]])
except:
    pass


# Plot Data 
plt.plot(decimalList)
plt.title('Sample Value in Decimal Code vs. Sample number')
plt.xlabel('Sample Number')
plt.ylabel('Sample Value in Decimal Code')
plt.grid(True)
plt.show()

