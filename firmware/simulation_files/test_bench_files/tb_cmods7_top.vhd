---------------------------------------------------------
--
-- File:         tb_cmods7_top.vhd
-- Author:       funsten1
-- Description:  Test bench for top level firmware for cmods7.
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
use ieee.numeric_std.all;

library UNISIM;
use UNISIM.VCOMPONENTS.ALL;

entity tb_cmods7_top is
end tb_cmods7_top;

architecture Behavioral of tb_cmods7_top is

    signal clk_12mhz  : std_logic := '0'; -- Single-ended 12 MHz clock.
    signal sys_rst    : std_logic := '0'; -- System reset.
    signal gpio       : std_logic := '0'; -- Push-button GPIO
    
    
begin

    clk_12mhz     <= not clk_12mhz  after  41.66 ns;
    sys_rst       <= '0';
    
    -- Initiate TOA trigger to search for an interrupt event
	gpio_button_proc : process
	begin
		gpio <= '0';
		wait for 100 ns;
		gpio <= '1';
		wait for 50 ns;
		gpio <= '0';
		wait until (sys_rst = '1');
		
    end process gpio_button_proc;
		
    

    -- Top level wrapper for Ultrasonic IP core and AdcCapture modules.
	cmods7_top_inst : entity work.cmods7_top
    generic map (
        sys_clk_freq  => 12_000_000,
        baud_rate     => 115_200,
        uart_d_width  => 8     
    )
	port map( 
        -- Clock
        sys_clk_12mhz_i   => clk_12mhz,
        
        -- Push-buttons
        sys_rst_i         => sys_rst,
        gpio_i            => gpio,
        
        -- LEDs
        led_o           => OPEN,
        led_blue_n_o    => OPEN,
        led_green_n_o   => OPEN,
        led_red_n_o     => OPEN,
        
        -- USB UART
        usb_uart_rx_i   => '1', -- If '1', then uart module will not expect bytes received.
        usb_uart_tx_o   => OPEN,
        
        -- XADC
        vaux5p_i        => '1',
        vaux5n_i        => '0',
        
        -- x2 DACs from PMOD D2A board, MFPN: DAC121S101/-Q1.
        dac_dina_o      => OPEN,
        dac_dinb_o      => OPEN,
        dac_sclk_o      => OPEN,
        dac_sync_n_o    => OPEN
	); 

end Behavioral;
