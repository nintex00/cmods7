# -*- coding: utf-8 -*-
'''
File:         solve_system_of_equations.py
Author:       funsten1
Description:  Solves a system of equations.
file.
---------------------------------------------------------
---------------------------------------------------------

REVISION HISTORY

Date:         4/7/2023
Author:       funsten1
Description:  
Purpose:      

'''



# importing library sympy
from sympy import symbols, Eq, solve


'''
Example of solving multiple equations
'''
 
# defining symbols used in equations
# or unknown variables
x, y = symbols('x,y')
  
# defining equations
eq1 = Eq((x+y), 1)
print("Equation 1:")
print(eq1)
eq2 = Eq((x-y), 1)
print("Equation 2")
print(eq2)
  
# solving the equation
print("Values of 2 unknown variable are as follows:")
  
print(solve((eq1, eq2), (x, y)))


'''
Solving one equation, one unknown
'''

# For wheat stone bridge variation to solve for delta R assuming 7284A
# Edevco Accel:
# Vsense+ - Vsense- = 3.3 V x ((Rsense+ down / Rsense+ up + Rsense+ down) -
# (Rsense- down/ Rsense- up + Rsense- down))
# = 3.3 V x ((Rsense+ down + delta R / Rsense+ up - deltaR + Rsense+ down + delta R) -
# (Rsense- down - delta R/ Rsense- up + deltaR + Rsense- down - delta R))
# Vsense+ - Vsense- = 2 kg x 150 uV / g = 0.3 V
# Rsense+ = Rsense- = 6.5 kOhms

# syms deltaR
# eqn = 0.3 == 3.3 * (((6.5e3 + deltaR)/(6.5e3 + deltaR + 6.5e3 - deltaR) - ...
#     ((6.5e3 - deltaR)/(6.5e3 + deltaR + 6.5e3 - deltaR))));
# S = solve(eqn, deltaR)


# defining symbols used in equations
# or unknown variables
x = symbols('x')

eq1 = Eq((3.3 * (((6.5e3 + x)/(6.5e3 + x + 6.5e3 - x) - ((6.5e3 - x)/(6.5e3 + x + 6.5e3 - x))))), 0.3)
print("Equation 1:")
print(eq1)
  
# solving the equation
print("Values of 1 unknown variable are as follows:")
  
print(solve((eq1), (x)))