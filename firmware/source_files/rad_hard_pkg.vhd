---------------------------------------------------------
--
-- File:         rad_hard_pkg.vhd
-- Author:       funsten1
-- Description:  Package for radiation hardened tools for the FPGA.
--
---------------------------------------------------------
---------------------------------------------------------
-- 
-- REVISION HISTORY

-- Date:         3/28/2023
-- Author:       funsten1
-- Description:  
-- Purpose:      
--
---------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

package rad_hard_pkg is

    -- Triple Modular Redundancy (TMR)
    component tmr is
    generic (
        reg_depth : integer
    );
    port (
        clk_i : in std_logic;
        rst_i : in std_logic;
        
        data_i : in  std_logic_vector(reg_depth downto 0);
        data_o : out std_logic_vector(reg_depth downto 0)
    );
    end component tmr;
   
end rad_hard_pkg;
