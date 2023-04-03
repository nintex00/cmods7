---------------------------------------------------------
--
-- File:         clocks_and_resets.vhd
-- Author:       funsten1
-- Description:  Clocks and resets module for handling clocks and resets.
-- Limitation:   
-- Copyright ©:  Lawrence Livermore National Laboratory
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

library UNISIM;
use UNISIM.VCOMPONENTS.ALL;

entity clocks_and_resets is
    port ( 
        -- Inputs
        clk_i    : in std_logic; -- System clock.
        rst_i    : in std_logic; -- Active-high push-button reset.
        
        -- Outputs
        clk_o    : out std_logic; -- Output system clock.
        rst_o    : out std_logic  -- Active-high system reset.
    );
end clocks_and_resets;

architecture Behavioral of clocks_and_resets is


begin

   -- Clock buffer for system clock.
   BUFG_inst : BUFG
   port map (
      I => clk_i,  -- Clock input
      O => clk_o   -- Clock output
   );

   -- Handling reset
   rst_o <= rst_i;
   
end Behavioral;
