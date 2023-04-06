import serial    # For pyserial class
import time      # For time delays
import binascii  # For handling ASCII, hex conversions

import matplotlib.pyplot as plt # For plotting 
import numpy as np # For matrix formalities
import csv # Write to a csv file
import time # Impose timing delays or time stamps
import os # Gather the path name of the operating system
import itertools
from create_tiffs import * # For saving tiff frames

ser = serial.Serial(
                    port = "COM3",     # COM port for serial link
                    baudrate = 1e6, # baud rate in bits per second 
                    parity = 'O',      # Parity: either odd, 'O', or even, 'E'
                    stopbits = serial.STOPBITS_ONE, # One stop bit
                    timeout = 60, 
                    bytesize = serial.EIGHTBITS) # byte size is eight bits

ser.flushInput()
ser.isOpen()

# Image Data
rowsOfPixels = 1024
colsOfPixels = 512
frames = 4
bytesPerPixel = 2
bytesToExtract = rowsOfPixels * colsOfPixels * frames * bytesPerPixel
# For four frames, that is 4194304 bytes, 8388608 nibbles


ser.write(binascii.a2b_hex('55')) # write a hex value in string format				
# time.sleep(0.1)
estring = str(binascii.b2a_hex(ser.read(bytesToExtract)))[2:-1] # string
ser.close() # close serial link

lengthBytes = int(len(estring)/2)


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
      
      
writeFileName = 'read_burst_dump' + '.csv'
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


# time.sleep(5)
# np.save(os.path.join(os.getcwd()), estring)



def str2nparray(valstring):
	"""
	Convert string into array of uint16s

	Args:
		valstring: string of hexadecimal characters

	Returns:
		numpy array of uint16
	"""
	output = [np.int(valstring[i : i + 4], 16) for i in range(0, len(valstring), 4)]
	return np.array(output, dtype=np.uint16)

# Parsing nibbles instead of bytes
frame1 = str2nparray(estring[0:2097152]) 
frame2 = str2nparray(estring[2097152:4194304])
frame3 = str2nparray(estring[4194304:6291456])
frame4 = str2nparray(estring[6291456:8388608])

frame1.shape = (1024,512)
frame2.shape = (1024,512)
frame3.shape = (1024,512)
frame4.shape = (1024,512)

n_bits = 16

# #frame1
plt.figure(1)
# implt = plt.imshow(frame1, cmap = 'gray')
implt = plt.imshow(frame1, cmap = 'gray', vmin = 0, vmax = (2**n_bits - 1)) 
plt.title("Image Frame 0")
plt.show()

# #frame2
plt.figure(2)
implt = plt.imshow(frame2, cmap = 'gray', vmin = 0, vmax = (2**n_bits - 1)) 
plt.title("Image Frame 1")
plt.show()

#frame3
plt.figure(3)
implt = plt.imshow(frame3, cmap = 'gray', vmin = 0, vmax = (2**n_bits - 1)) 
plt.title("Image Frame 2")
plt.show()

#frame4
plt.figure(4)
implt = plt.imshow(frame4, cmap = 'gray', vmin = 0, vmax = (2**n_bits - 1)) 
plt.title("Image Frame 3")
plt.show()


imsave(os.path.join(os.getcwd(), 'frame_0.tif'), frame1)
imsave(os.path.join(os.getcwd(), 'frame_1.tif'), frame2)
imsave(os.path.join(os.getcwd(), 'frame_3.tif'), frame3)
imsave(os.path.join(os.getcwd(), 'frame_4.tif'), frame4)

