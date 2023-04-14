# -*- coding: utf-8 -*-
'''
File:         xadc_monitor.py
Author:       funsten1
Description:  Tests XADC of Digilent CMODS7 Xilinx FPGA Board.
UART is used to pull temperature, VAUX5, and VAUX12 data and write to a csv
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
import numpy as np

ser = serial.Serial(
                    port = "COM3",     # COM port for serial link
                    baudrate = 1e6, # baud rate in bits per second 
                    parity = 'O',      # Parity: either odd, 'O', or even, 'E'
                    stopbits = serial.STOPBITS_ONE, # One stop bit
                    timeout = 10, 
                    bytesize = serial.EIGHTBITS) # byte size is eight bits

ser.flushInput()
ser.isOpen()

      
writeFileName = 'xadc_dump' + '.csv'
CSVheader = ['Sample Number', 'Delay (sec)', 'dt (sec)','Temperature (degrees C)', 'VAUX5 (V)', 'VAUX12 (V)']


with open(os.path.join(os.getcwd(), writeFileName), 'w',newline='') as f:
    writer = csv.writer(f)
    writer.writerow(CSVheader)


# Sample driver
start = 0
stop = 60

num_of_samples = 120
dt = (stop-start) / num_of_samples

i = 1
for delay in np.arange(start, stop, dt):
      
    # Temperature addr = x"00", VAUX5 addr = x"15", VAUX12 addr = x"1C"
    ser.write(binascii.a2b_hex('00')) # write a hex value in string format				
    estring = str(binascii.b2a_hex(ser.read(2)))[2:-2] # string
    temp = (int(estring,16)/2**12)*503.975 - 273.15
    
    ser.write(binascii.a2b_hex('15')) # write a hex value in string format				
    estring = str(binascii.b2a_hex(ser.read(2)))[2:-2] # strin
    vaux5 = (int(estring,16)/2**12)*1*(1e3+2.32e3)/(1e3)
    
    ser.write(binascii.a2b_hex('1c')) # write a hex value in string format				
    estring = str(binascii.b2a_hex(ser.read(2)))[2:-2] # strin
    vaux12 = (int(estring,16)/2**12)*1*(1e3+2.32e3)/(1e3)
    
    try:
        with open(os.path.join(os.getcwd(), writeFileName), 'a',newline='') as f:
            writer = csv.writer(f)  
            writer.writerow( [i, delay, dt, temp, vaux5, vaux12])
    except:
        pass

    print("Iteration = " + str(i))

        
    i = i + 1	
    time.sleep(dt)

ser.close() # close serial link
