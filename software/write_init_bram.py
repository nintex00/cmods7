# -*- coding: utf-8 -*-
'''
File:         write_init_bram.py
Author:       funsten1
Description:  Creates an initial block ram csv file whereby a text editor can
be opened to copy the contents to a coe file for Vivado's block memory generator
IP core for example.
file.
---------------------------------------------------------
---------------------------------------------------------

REVISION HISTORY

Date:         4/7/2023
Author:       funsten1
Description:  
Purpose:      

'''
import numpy as np
import csv
import time
import os
import itertools
import matplotlib.pyplot as plt

AdcSamplingFreq = 125e6

readFileName = 'dump1_20230106_edited_for_csv'

file = open(readFileName + '.csv')
csvreader = csv.reader(file)

rows = []
for row in csvreader:
      rows.append(row)
      

parsedRow = []
parsedRows = []
for i in range(len(rows)):
      parsedRow = rows[i][5:-1]
      parsedRows.append(parsedRow)
      
flatList = list(itertools.chain(*parsedRows))


# flatList = flatList[1:-1]


# Extract all hex string samples (2 bytes) in a list
hexStrList = []
j = 0
for i in range(int(len(flatList)/2)):
      hexStrList.append(flatList[j]+flatList[j+1])
      j = j + 2

# Convert to decimal from hex
decimalList = []
for i in range(len(hexStrList)):
      decimalList.append(int(hexStrList[i],16))

# Convert to voltage from decimal
voltList = []
for i in range(len(decimalList)):
      voltList.append((2/(2**14)*(decimalList[i]-2**13)))

# Create time list
timeList = []
for i in range(len(decimalList)):
      timeList.append(i*1/(AdcSamplingFreq))
      
# Write to a csv file

writeFileName = 'init_bram' + '.csv'
# CSVheader = ['Sample Number', 'Decimal Code', 'Time (sec)', 'ADC Out (V)']

j = 0
hexStrBram = hexStrList[0:65536]
with open(os.path.join(os.getcwd(), writeFileName), 'w',newline='') as f:
    writer = csv.writer(f, delimiter = ' ')
    # writer.writerow(CSVheader)

try:
    with open(os.path.join(os.getcwd(), writeFileName), 'a',newline='') as f:
        # writer = csv.writer(f)
        # writer.writerow(hexStrList)
        f.write(" ".join(hexStrBram))
        # for i in range(len(decimalList)):
            # for i in range(64)
        # for i in range(64):
        #       writer.writerow( [hexStrList[i*j], hexStrList[j*i+1], hexStrList[j*i+2], hexStrList[j*i+3],
        #                         hexStrList[i*j+4], hexStrList[i*j+5], hexStrList[i*j+6], hexStrList[i*j+7],
        #                         hexStrList[i*j+8], hexStrList[i*j+9], hexStrList[i*j+10], hexStrList[i*j+11],
        #                         hexStrList[i*j+12], hexStrList[i*j+13], hexStrList[i*j+14], hexStrList[i*j+15], ''])
        #       j += 16
              
except:
    pass

# Check fake ADC data samples are counting starting with sample 1
# count = 1
# for i in range(len(decimalList)):
      
#       # print("Count = " + str(count))
#       if (decimalList[i] == 1):
#             count = 1
#             if (count != decimalList[i]):
#                   print("Error at sample location: " + str(decimalList[i]))
#       count += 1
      
# Plot Data 
plt.plot(timeList,voltList)
plt.title('ADC Out (V) vs. Time (Sec)')
plt.xlabel('Time (Sec)')
plt.ylabel('ADC Out (V)')
plt.grid(True)
plt.show()
