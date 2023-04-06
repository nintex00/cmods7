--------------------------------------------------------------------------------
--
--   FileName:         uart.vhd 
--   Dependencies:     none
--   Reference: https://forum.digikey.com/t/uart-vhdl/12670 
--   Design Software:  Quartus II 64-bit Version 13.1.0 Build 162 SJ Web Edition
--
--   HDL CODE IS PROVIDED "AS IS."  DIGI-KEY EXPRESSLY DISCLAIMS ANY
--   WARRANTY OF ANY KIND, WHETHER EXPRESS OR IMPLIED, INCLUDING BUT NOT
--   LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
--   PARTICULAR PURPOSE, OR NON-INFRINGEMENT. IN NO EVENT SHALL DIGI-KEY
--   BE LIABLE FOR ANY INCIDENTAL, SPECIAL, INDIRECT OR CONSEQUENTIAL
--   DAMAGES, LOST PROFITS OR LOST DATA, HARM TO YOUR EQUIPMENT, COST OF
--   PROCUREMENT OF SUBSTITUTE GOODS, TECHNOLOGY OR SERVICES, ANY CLAIMS
--   BY THIRD PARTIES (INCLUDING BUT NOT LIMITED TO ANY DEFENSE THEREOF),
--   ANY CLAIMS FOR INDEMNITY OR CONTRIBUTION, OR OTHER SIMILAR COSTS.
--
--   Version History
--   Version 1.0 5/26/2017 Scott Larson
--     Initial Public Release
--   Version 1.1 8/3/2021 Scott Larson
--     Corrected rx start bit error checking
--    
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity uart is
  generic (
    clk_freq  :  integer    := 12_000_000;  -- Frequency of system clock in Hertz
    baud_rate :  integer    := 19_200;      -- Data link baud rate in bits/second
    os_rate   :  integer    := 4;           -- Oversampling rate to find center of receive bits (in samples per baud period)
    d_width   :  integer    := 8;           -- Data bus width
    parity    :  integer    := 1;           -- 0 for no parity, 1 for parity
    parity_eo :  std_logic  := '1');        -- '0' for even, '1' for odd parity
  port (
    -- Inputs
    clk_i      :  in   std_logic;                             -- System clock
    rst_i      :  in   std_logic;                             -- Active-high reset
    tx_ena_i   :  in   std_logic;                             -- Initiate transmission
    tx_data_i  :  in   std_logic_vector(d_width-1 downto 0);  -- Data to transmit
    rx_i       :  in   std_logic;                             -- Receive pin
    
    -- Outputs
    rx_busy_o  :  out  std_logic := '0';                      -- Data reception in progress
    rx_error_o :  out  std_logic := '0';                      -- Start, parity, or stop bit error detected
    rx_data_o  :  out  std_logic_vector(d_width-1 downto 0);  -- Data received
    tx_busy_o  :  out  std_logic := '1';                      -- Transmission in progress
    tx_o       :  out  std_logic := '1'                       -- Transmit pin
    );
end uart;
    
architecture Behavioral of uart is
  type   tx_machine is (idle, transmit);                      --tranmit state machine data type
  type   rx_machine is (idle, receive);                       --receive state machine data type
  signal tx_state     :  tx_machine := idle;                          --transmit state machine
  signal rx_state     :  rx_machine := idle;                          --receive state machine
  signal baud_pulse   :  std_logic := '0';                    --periodic pulse that occurs at the baud rate
  signal os_pulse     :  std_logic := '0';                    --periodic pulse that occurs at the oversampling rate
  signal parity_error :  std_logic;                           --receive parity error flag
  signal rx_parity    :  std_logic_vector(d_width downto 0);  --calculation of receive parity
  signal tx_parity    :  std_logic_vector(d_width downto 0);  --calculation of transmit parity
  signal rx_buffer    :  std_logic_vector(parity+d_width downto 0)   := (others => '0'); --values received
  signal tx_buffer    :  std_logic_vector(parity+d_width+1 downto 0) := (others => '1'); --values to be transmitted

begin

  -- Generate clock enable pulses at the baud rate and the oversampling rate
  baud_rate_ctrl_proc : process(rst_i, clk_i, os_pulse)
    variable count_baud :  integer range 0 to clk_freq/baud_rate-1 := 0;         --counter to determine baud rate period
    variable count_os   :  integer range 0 to clk_freq/baud_rate/os_rate-1 := 0; --counter to determine oversampling period
  begin
    if (rst_i = '1') then                            -- reset asserted
      baud_pulse <= '0';                             --reset baud rate pulse
      os_pulse <= '0';                               --reset oversampling rate pulse
      count_baud := 0;                               --reset baud period counter
      count_os := 0;                                 --reset oversampling period counter
    elsif rising_edge(clk_i) then
      --create baud enable pulse
      if(count_baud < clk_freq/baud_rate-1) then        --baud period not reached
        count_baud := count_baud + 1;                   --increment baud period counter
        baud_pulse <= '0';                              --deassert baud rate pulse
      else                                              --baud period reached
        count_baud := 0;                                --reset baud period counter
        baud_pulse <= '1';                              --assert baud rate pulse
        count_os := 0;                                  --reset oversampling period counter to avoid cumulative error
      end if;
      --create oversampling enable pulse
      if (count_os < clk_freq/baud_rate/os_rate-1) then  --oversampling period not reached
        count_os := count_os + 1;                        --increment oversampling period counter
        os_pulse <= '0';                                 --deassert oversampling rate pulse    
      else                                               --oversampling period reached
        count_os := 0;                                   --reset oversampling period counter
        os_pulse <= '1';                                 --assert oversampling pulse
      end if;
    end if;
  end process baud_rate_ctrl_proc;

  --receive state machine
  receive_proc : process (rst_i, clk_i, os_pulse)
    variable rx_count :  integer range 0 to parity+d_width+2 := 0; --count the bits received
    variable os_count :  integer range 0 to os_rate-1 := 0;        --count the oversampling rate pulses
  begin
    if (rst_i = '1') then                                 -- reset asserted
      os_count := 0;                                      --clear oversampling pulse counter
      rx_count := 0;                                      --clear receive bit counter
      rx_busy_o <= '0';                                   --clear receive busy signal
      rx_error_o <= '0';                                  --clear receive errors
      rx_data_o <= (others => '0');                       --clear received data output
      rx_state <= idle;                                   --put in idle state
    elsif rising_edge(clk_i) and os_pulse = '1' then --enable clock at oversampling rate
      case rx_state is
        when idle =>                                           --idle state
          rx_busy_o <= '0';                                    --clear receive busy flag
          if (rx_i = '0') then                                 --start bit might be present
            if (os_count < os_rate/2) then                     --oversampling pulse counter is not at start bit center
              os_count := os_count + 1;                        --increment oversampling pulse counter
              rx_state <= idle;                                --remain in idle state
            else                                               --oversampling pulse counter is at bit center
              os_count := 0;                                   --clear oversampling pulse counter
              rx_count := 0;                                   --clear the bits received counter
              rx_busy_o <= '1';                                --assert busy flag
              rx_buffer <= rx_i & rx_buffer(parity+d_width downto 1);  --shift the start bit into receive buffer							
              rx_state <= receive;                                     --advance to receive state
            end if;
          else                                                   --start bit not present
            os_count := 0;                                       --clear oversampling pulse counter
            rx_state <= idle;                                    --remain in idle state
          end if;
        when receive =>                                        --receive state
          if (os_count < os_rate-1) THEN                       --not center of bit
            os_count := os_count + 1;                          --increment oversampling pulse counter
            rx_state <= receive;                               --remain in receive state
          elsif(rx_count < parity+d_width) then                --center of bit and not all bits received
            os_count := 0;                                     --reset oversampling pulse counter    
            rx_count := rx_count + 1;                          --increment number of bits received counter
            rx_buffer <= rx_i & rx_buffer(parity+d_width downto 1); --shift new received bit into receive buffer
            rx_state <= receive;                                    --remain in receive state
          else                                                      --center of stop bit
            rx_data_o <= rx_buffer(d_width downto 1);               --output data received to user logic
            rx_error_o <= rx_buffer(0) or parity_error or not rx_i; --output start, parity, and stop bit error flag
            rx_busy_o <= '0';                                       --deassert received busy flag
            rx_state <= idle;                                       --return to idle state
          end if;
      end case;
    end if;
  end process receive_proc;
    
  -- Receive parity calculation logic
  rx_parity(0) <= parity_eo;
  
  rx_parity_logic: for i in 0 to d_width-1 generate
    rx_parity(i+1) <= rx_parity(i) XOR rx_buffer(i+1);
  end generate;
  with parity select  --compare calculated parity bit with received parity bit to determine error
    parity_error <= rx_parity(d_width) XOR rx_buffer(parity+d_width) when 1,  --using parity
                    '0' when others;                                          --not using parity
    
  -- Transmit state machine
  transmit_proc : process(rst_i, clk_i)
    variable tx_count :  integer range 0 to parity+d_width+3 := 0;  --count bits transmitted
  begin
    if (rst_i = '1') then                                       --reset asserted
      tx_count := 0;                                            --clear transmit bit counter
      tx_o <= '1';                                              --set tx pin to idle value of high
      tx_busy_o <= '1';                                         --set transmit busy signal to indicate unavailable
      tx_state <= idle;                                         --set tx state machine to ready state
    elsif rising_edge(clk_i) then
      case tx_state is
        when idle =>                                                   --idle state
          if (tx_ena_i = '1') then                                     --new transaction latched in
            tx_buffer(d_width+1 downto 0) <=  tx_data_i & '0' & '1';   --latch in data for transmission and start/stop bits
            if (parity = 1) then                                       --if parity is used
              tx_buffer(parity+d_width+1) <= tx_parity(d_width);       --latch in parity bit from parity logic
            end if;
            tx_busy_o <= '1';                                          --assert transmit busy flag
            tx_count := 0;                                             --clear transmit bit count
            tx_state <= transmit;                                      --proceed to transmit state
          else                                                         --no new transaction initiated
            tx_busy_o <= '0';                                          --clear transmit busy flag
            tx_state <= idle;                                          --remain in idle state
          end if;
        when transmit =>                                               --transmit state
          if (baud_pulse = '1') then                                   --beginning of bit
            tx_count := tx_count + 1;                                  --increment transmit bit counter
            tx_buffer <= '1' & tx_buffer(parity+d_width+1 downto 1);   --shift transmit buffer to output next bit
          end if;
          if (tx_count < parity+d_width+3) then                        --not all bits transmitted
            tx_state <= transmit;                                      --remain in transmit state
          else                                                         --all bits transmitted
            tx_state <= idle;                                          --return to idle state
          end if;
      end case;
      tx_o <= tx_buffer(0);  -- Output last bit in transmit transaction buffer
    end if;
  end process transmit_proc;  
  
  -- Transmit parity calculation logic
  tx_parity(0) <= parity_eo;
  
  tx_parity_logic: for i in 0 to d_width-1 generate
    tx_parity(i+1) <= tx_parity(i) XOR tx_data_i(i);
  end generate;
  
end Behavioral;