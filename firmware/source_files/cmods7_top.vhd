---------------------------------------------------------
--
-- File:         cmods7_top.vhd
-- Author:       funsten1
-- Description:  Top level firmware for cmods7.
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
use IEEE.NUMERIC_STD.all;

library UNISIM;
use UNISIM.VCOMPONENTS.ALL;

entity cmods7_top is
    generic (
        sys_clk_freq : integer := 12_000_000; -- System clock frequency
        baud_rate    : integer := 1_000_000;  -- Baud rate in bits per second
        uart_d_width : integer := 8           -- UART Data bus width
    );
    port ( 
        -- Clock
        sys_clk_12mhz_i : in std_logic; -- System clock of single-ended 12 MHz from on-board crystal oscillator.
        
        -- Push-buttons
        sys_rst_i       : in std_logic; -- System Active-high push-button reset.
        gpio_i          : in std_logic; -- Active-high push-button.
        
        -- LEDs
        led_o           : out std_logic_vector(3 downto 0); -- Active-high Four general purpose LEDs.
        led_blue_n_o    : out std_logic;                    -- Active-low Blue LED of RGB LED.
        led_green_n_o   : out std_logic;                    -- Active-low Green LED of RGB LED.
        led_red_n_o     : out std_logic;                    -- Active-low Red LED of RGB LED.
        
        -- USB UART
        usb_uart_rx_i   : in  std_logic; -- Receive pin of USB UART.
        usb_uart_tx_o   : out std_logic; -- Transmit pin of USB UART.
        
        -- RS422 UART
        rs422_uart_rx_i : in  std_logic; -- Receive pin of USB UART.
        rs422_uart_tx_o : out std_logic; -- Receive pin of USB UART.
        
        -- XADC
        vaux5p_i        : in std_logic;  -- XADC positive pin for VAUX5
        vaux5n_i        : in std_logic;  -- XADC negative pin for VAUX5
        vaux12p_i       : in std_logic;  -- XADC positive pin for VAUX12
        vaux12n_i       : in std_logic;  -- XADC negative pin for VAUX12
        
        -- x2 DACs from PMOD D2A board, MFPN: DAC121S101/-Q1.
        dac_dina_o      : out std_logic; -- Serial data input for DAC A (IC1).
        dac_dinb_o      : out std_logic; -- Serial data input for DAC B (IC2).
        dac_sclk_o      : out std_logic; -- For the two DACs. Serial clock input clocked on falling edges of this pin.
        dac_sync_n_o    : out std_logic  -- For the two DACs. Active-low frame synchronization input for data input. When '0', the input shift register is enabled to transfer data on falling edge of dac_sclk_o.                 
         );
end cmods7_top;

architecture Behavioral of cmods7_top is

    -- Clocks and reset signals
    signal sys_clk_12mhz : std_logic := '0'; -- Buffered 12 MHz from crystal oscillator.
    signal sys_rst       : std_logic;        -- Active-high reset.
    
begin
   
     -- Clocks and resets module for handling clocks and resets.
     clocks_and_resets_inst : entity work.clocks_and_resets
     port map(
     -- Inputs
     clk_i => sys_clk_12mhz_i,
     rst_i => sys_rst_i,
     
     -- Outputs
     clk_o => sys_clk_12mhz,
     rst_o => sys_rst
     ); 
   
   -- Blinks leds at 1 Hz. For this board, the RGB led toggles for 2 seconds
   blink_leds_inst : entity work.blink_leds
     generic map(
        sys_clk_freq => sys_clk_freq
     )
     port map(
     -- Inputs
     clk_i  => sys_clk_12mhz,
     rst_i  => sys_rst,
     duty_i => x"EE",
     
     -- Outputs
     led_o           => led_o,
     led_blue_n_o    => led_blue_n_o,
     led_green_n_o   => led_green_n_o,
     led_red_n_o     => led_red_n_o
     ); 
     
   -- Communication interface to handle both UART and Packet Encode/Decode.
   comms_interface_inst : entity work.comms_interface
     generic map(
        sys_clk_freq => sys_clk_freq,
        baud_rate    => baud_rate,
        uart_d_width => uart_d_width
     )
     port map(
        -- Clocks and reset
        clk_i  => sys_clk_12mhz,
        rst_i  => sys_rst,
     
        -- USB UART
        uart_rx_i => rs422_uart_rx_i, --usb_uart_rx_i,
        uart_tx_o => rs422_uart_tx_o  --usb_uart_tx_o
     ); 

   -- XADC Interface
   xadc_top_inst : entity work.xadc_top
     port map(
        -- Clocks and reset
        clk_i  => sys_clk_12mhz,
        rst_i  => sys_rst,
     
        -- XADC
        vaux5p_i  => vaux5p_i,
        vaux5n_i  => vaux5n_i,
        vaux12p_i => vaux12p_i,
        vaux12n_i => vaux12n_i
     );
    
  -- PMOD D2A: Two DAC 12-bit Interface
   dac_driver_inst : entity work.dac_driver
     port map(
        -- Clocks and reset
        clk_i  => sys_clk_12mhz,
        rst_i  => sys_rst,
        gpio_i => gpio_i,
     
        -- DAC pins
        dac_seta_i   => x"321",
        dac_setb_i   => x"FFF",
        dac_dina_o   => dac_dina_o,
        dac_dinb_o   => dac_dinb_o,
        dac_sclk_o   => dac_sclk_o,
        dac_sync_n_o => dac_sync_n_o  
     ); 
        
       
end Behavioral;
