---------------------------------------------------------
--
-- File:         comms_interface.vhd
-- Author:       funsten1
-- Description:  Communication interface module that handles both UART and Packet Encode/Decode modules.
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

entity comms_interface is
    generic(
        sys_clk_freq : integer := 12_000_000; -- System clock frequency
        fpga_rev     : std_logic_vector(23 downto 0) := x"230404"; -- Revision date.
        baud_rate    : integer := 115_200;    -- Baud rate in bits per second
        os_rate      : integer := 4;          -- Oversampling rate to find center of receive bits (in samples per baud period)
        uart_d_width : integer := 8           -- UART Data bus width
    );
    port ( 
        -- Clock and reset
        clk_i    : in std_logic;  -- System clock.
        rst_i    : in std_logic;  -- Active-high push-button reset.
        
        -- UART
        uart_rx_i   : in std_logic; -- Receive pin of USB UART.
        uart_tx_o   : out std_logic -- Transmit pin of USB UART.
    );
end comms_interface;

architecture Behavioral of comms_interface is
    


    -- UART handling signals
    signal tx_ena        : std_logic;                                                     -- Initiate transmission
    signal tx_busy       : std_logic;                                                     -- Transmission in progress
    signal tx_data       : std_logic_vector(uart_d_width-1 downto 0) := (others => '0');  -- Data to transmit
    signal rx_busy       : std_logic;                                                     -- Data reception in progress
    signal rx_error      : std_logic;                                                     -- Start, parity, or stop bit error detected
    signal rx_data       : std_logic_vector(uart_d_width-1 downto 0);                     -- Data received
    signal uart_tx       : std_logic;                                                     -- UART Tx pin.
begin

    uart_tx_o <= uart_tx;
    
   -- UART module for transmitting and receiving at a particular baud rate with optional parity.
   uart_inst : entity work.uart
    generic map(
        clk_freq  => sys_clk_freq,  
        baud_rate => baud_rate,
        os_rate   => os_rate,
        d_width   => uart_d_width   
    )
    port map (
    -- Inputs
    clk_i                 => clk_i,
    rst_i                 => rst_i,
    tx_ena_i              => tx_ena,
    tx_data_i             => tx_data,
    rx_i                  => uart_rx_i,
    
    -- Outputs
    rx_busy_o             => rx_busy,
    rx_error_o            => rx_error,
    rx_data_o             => rx_data,
    tx_busy_o             => tx_busy,
    tx_o                  => uart_tx
   );
   
   -- Packet encode/decode module for handling bytes received and transmitted from UART.
   packet_encode_decode_inst : entity work.packet_encode_decode
    generic map(
        fpga_rev     => fpga_rev,
        uart_d_width => uart_d_width  
    )
    port map (
    -- Inputs
    clk_i        => clk_i,
    rst_i        => rst_i,

     rx_busy_i   => rx_busy,          
     rx_error_i  => rx_error,
     rx_data_i   => rx_data,
     tx_busy_i   => tx_busy,
    
     -- Outputs
     tx_ena_o    => tx_ena,
     tx_data_o   => tx_data
   );   
  
   
end Behavioral;
