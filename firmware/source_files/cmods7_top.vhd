---------------------------------------------------------
--
-- File:         cmods7_top.vhd
-- Author:       funsten1
-- Description:  Top level firmware for cmods7. The firmware
-- exercises most if not all functionality on the cmods7 board
-- from Digilent. The Spartan 7 FPGA used is the XC7S25-1CSGA225C.
-- The purpose of this project is to showcase how to interface with 
-- a FPGA for projects at LLNL.
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
use work.rad_hard_pkg.ALL;

library UNISIM;
use UNISIM.VCOMPONENTS.ALL;

entity cmods7_top is
    generic (
        sys_clk_freq : integer := 12_000_000; -- System clock frequency
        
        fpga_rev     : std_logic_vector(23 downto 0) := x"230412"; -- Revision date.
        
        -- UART generics
        baud_rate    : integer := 1_000_000;  -- Baud rate in bits per second
        os_rate      : integer := 4;          -- Oversampling rate to find center of receive bits (in samples per baud period)
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
        dac_sync_n_o    : out std_logic; -- For the two DACs. Active-low frame synchronization input for data input. When '0', the input shift register is enabled to transfer data on falling edge of dac_sclk_o.                 
        
        -- Piezo buzzer to generate music
        tone_o          : out std_logic  -- Piezo buzzer tone for different frequencies.
         );
end cmods7_top;

architecture Behavioral of cmods7_top is

    -- Clocks and reset signals
    signal sys_clk_12mhz : std_logic := '0'; -- Buffered 12 MHz from crystal oscillator.
    signal sys_rst       : std_logic;        -- Active-high reset.
    
    signal tmr_test      : std_logic := '1'; -- TMR (Triple Modular Redundancy) test flag.
    
    -- Register pass through signals
    signal data_reg_in                 : std_logic_vector(31 downto 0)  := (others => '0'); -- Data register for writing to an instantiated list of generated registers.
    signal data_reg_out                : std_logic_vector(31 downto 0)  := (others => '0'); -- Data register for reading to an instantiated list of generated registers.
    
    -- XADC signals
    signal xadc_addr       : std_logic_vector(7 downto 0) := (others => '0'); -- XADC address to read from.
    signal xadc_out        : std_logic_vector(15 downto 0);                   -- XADC data out to write to UART.
    signal xadc_data_valid : std_logic;                                       -- XADC valid flag from XADC state machine.
    signal xadc_enable     : std_logic;                                       -- XADC enable flag from UART.
    
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
        fpga_rev     => fpga_rev,
        baud_rate    => baud_rate,
        os_rate      => os_rate,
        uart_d_width => uart_d_width
     )
     port map(
        -- Clocks and reset
        clk_i  => sys_clk_12mhz,
        rst_i  => sys_rst,
     
        -- XADC
        xadc_addr_o       => xadc_addr,
        xadc_out_i        => xadc_out,
        xadc_data_valid_i => xadc_data_valid,
        xadc_enable_o     => xadc_enable,
        
        -- USB UART
        uart_rx_i => rs422_uart_rx_i, --usb_uart_rx_i,
        uart_tx_o => rs422_uart_tx_o  --usb_uart_tx_o
     ); 

   -- XADC Interface for reading temperature, and two auxilary voltages: VAUX5 and VAUX12.
   xadc_top_inst : entity work.xadc_top
     port map(
        -- Clocks and reset
        clk_i  => sys_clk_12mhz,
        rst_i  => sys_rst,
        
        xadc_addr_i       => xadc_addr,
        xadc_o            => xadc_out,
        xadc_data_valid_o => xadc_data_valid,
        xadc_enable_i     => xadc_enable,
        
        -- XADC dedicated pins
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
     
  -- Piezo buzzer to generate music
   piezo_buzzer_inst : entity work.piezo_buzzer
     generic map(
        sys_clk_freq => sys_clk_freq
     )
     port map(
        -- Clocks and reset
        clk_i     => sys_clk_12mhz,
        rst_i     => sys_rst,
        gpio_i    => gpio_i,
        
        tone_o    => tone_o
     ); 
     
    -- Register passthrough FPGA fabric
    reg_array_inst : entity work.reg
    generic map(
      reg_width     => 32,
      reg_depth     => 10--1000--20000
    )
    port map (
        clk			=> sys_clk_12mhz,
        rst		    => sys_rst,
        data_in		=> data_reg_in,
        data_out    => data_reg_out
    );  
    
    -- Apply tmr to a test register 
    tmr_inst : tmr
    generic map(
        reg_depth => 0
    )
    port map (
        clk_i => sys_clk_12mhz,
        rst_i => sys_rst,
        
        data_i(0) => tmr_test,
        data_o => OPEN
    ); 
    
    
    -- Apply hamming encoding to a test register
    hamming_encoding_inst : entity work.hamming_encoding
    port map (
        data_i    => data_reg_in(4 downto 0),
        encoded_o => data_reg_out(7 downto 0)
    );   
end Behavioral;
