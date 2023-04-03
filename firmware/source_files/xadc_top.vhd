---------------------------------------------------------
--
-- File:         xadc_top.vhd
-- Author:       funsten1
-- Description:  Top xadc interface for 1 MSps 10-bit internal ADC to FPGA.
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

entity xadc_top is
    port ( 
        -- Clock and reset
        clk_i    : in std_logic;  -- System clock.
        rst_i    : in std_logic;  -- Active-high push-button reset.
        
        -- XADC
        vaux5p_i   : in std_logic; -- XADC positive pin for VAUX5
        vaux5n_i   : in std_logic; -- XADC negative pin for VAUX5
        vaux12p_i  : in std_logic; -- XADC positive pin for VAUX12
        vaux12n_i  : in std_logic  -- XADC negative pin for VAUX12
    );
end xadc_top;

architecture Behavioral of xadc_top is

    COMPONENT xadc_wiz_0
      PORT (
        di_in : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
        daddr_in : IN STD_LOGIC_VECTOR(6 DOWNTO 0);
        den_in : IN STD_LOGIC;
        dwe_in : IN STD_LOGIC;
        drdy_out : OUT STD_LOGIC;
        do_out : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
        dclk_in : IN STD_LOGIC;
        reset_in : IN STD_LOGIC;
        vp_in : IN STD_LOGIC;
        vn_in : IN STD_LOGIC;
        vauxp5 : IN STD_LOGIC;
        vauxn5 : IN STD_LOGIC;
        vauxp12 : IN STD_LOGIC;
        vauxn12 : IN STD_LOGIC;
        user_temp_alarm_out : OUT STD_LOGIC;
        vccint_alarm_out : OUT STD_LOGIC;
        vccaux_alarm_out : OUT STD_LOGIC;
        ot_out : OUT STD_LOGIC;
        channel_out : OUT STD_LOGIC_VECTOR(4 DOWNTO 0);
        eoc_out : OUT STD_LOGIC;
        vbram_alarm_out : OUT STD_LOGIC;
        alarm_out : OUT STD_LOGIC;
        eos_out : OUT STD_LOGIC;
        busy_out : OUT STD_LOGIC
      );
    END COMPONENT;

begin

    xadc_inst : xadc_wiz_0
      PORT MAP (
        di_in => (others => '0'),
        daddr_in => (others => '0'),
        den_in => '0',
        dwe_in => '0',
        drdy_out => OPEN,
        do_out => OPEN,
        dclk_in => clk_i,
        reset_in => rst_i,
        vp_in => '0',
        vn_in => '0',
        vauxp5 => vaux5p_i,
        vauxn5 => vaux5n_i,
        vauxp12 => vaux12p_i,
        vauxn12 => vaux12n_i,
        user_temp_alarm_out => OPEN,
        vccint_alarm_out => OPEN,
        vccaux_alarm_out => OPEN,
        ot_out => OPEN,
        channel_out => OPEN,
        eoc_out => OPEN,
        vbram_alarm_out => OPEN,
        alarm_out => OPEN,
        eos_out => OPEN,
        busy_out => OPEN
      );
   
end Behavioral;
