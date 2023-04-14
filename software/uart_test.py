# -*- coding: utf-8 -*-
'''
File:         uart_test.py
Author:       funsten1
Description:  Tests UART assuming the FPGA accepts bytes in the form of 11 bits.
Pyserial is used to construct a serial interface assuming either communication standard
such as RS232 (max 115200 baud rate) or RS422 (max 3 Mbaud for small byte transfer and
1 Mbaud for large byte transfers).
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

ser = serial.Serial(
                    port = "COM3",     # COM port for serial link
                    baudrate = 1e6, # baud rate in bits per second 
                    parity = 'O',      # Parity: either odd, 'O', or even, 'E'
                    stopbits = serial.STOPBITS_ONE, # One stop bit
                    timeout = 10, 
                    bytesize = serial.EIGHTBITS) # byte size is eight bits

ser.flushInput()
ser.isOpen()

# while(1):
# ser.write(binascii.a2b_hex('41')) # write a hex value in string format				
# time.sleep(0.1)
# estring = str(binascii.b2a_hex(ser.read(1)))[2:-1] # string
ser.write(binascii.a2b_hex('20')) # write a hex value in string format				
# time.sleep(0.1)
estring = str(binascii.b2a_hex(ser.read(3)))[2:-1] # string
# byteStrOut = binascii.b2a_hex(ser.read(4194304)) # byte out in HEX
# estring = str(binascii.b2a_hex(ser.read(4194304)))[2:-1] # string
# lengthBytes = int(len(estring)/2)
# print(estring)
    
ser.close() # close serial link
