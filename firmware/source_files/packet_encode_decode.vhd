---------------------------------------------------------
--
-- File:         packet_encode_decode.vhd
-- Author:       funsten1
-- Description:  Packet encode/decode module for handling bytes received and transmitted from UART.
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
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;
use IEEE.STD_LOGIC_UNSIGNED.all;

entity packet_encode_decode is
    generic(
        uart_d_width : integer := 8           -- UART Data bus width
    );
    port ( 
     -- Inputs
     clk_i      :  in   std_logic;                                 -- system clock
     rst_i      :  in   std_logic;                                 -- scynchronous reset
     rx_busy_i  :  in   std_logic := '0';                          -- Data reception in progress
     rx_error_i :  in   std_logic := '0';                          -- Start, parity, or stop bit error detected
     rx_data_i  :  in   std_logic_vector(uart_d_width-1 downto 0); -- Data received
     tx_busy_i  :  in   std_logic := '1';                          -- Transmission in progress
    
     -- Outputs
     tx_ena_o   :  out  std_logic;                                 -- Initiate transmission
     tx_data_o  :  out  std_logic_vector(uart_d_width-1 downto 0)  -- Data to transmit
    
    );
end packet_encode_decode;

architecture Behavioral of packet_encode_decode is

    -- UART ILA
    COMPONENT uart_ila
    PORT (
        clk : IN STD_LOGIC;

        probe0 : IN STD_LOGIC_VECTOR(0 DOWNTO 0); 
        probe1 : IN STD_LOGIC_VECTOR(0 DOWNTO 0); 
        probe2 : IN STD_LOGIC_VECTOR(0 DOWNTO 0); 
        probe3 : IN STD_LOGIC_VECTOR(0 DOWNTO 0); 
        probe4 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
        probe5 : IN STD_LOGIC_VECTOR(22 DOWNTO 0);
        probe6 : IN STD_LOGIC_VECTOR(7 DOWNTO 0)
    );
    END COMPONENT;
    
    -- State for UART
    type uart_state_type   is (IDLE, RECEIVE_STATE, TRANSMIT_STATE);						  
    signal uart_state : uart_state_type := IDLE;   
    
    signal test_data_cntr : std_logic_vector(22 downto 0) := (others => '0');
    signal test_data      : std_logic_vector(22 downto 0) := (others => '0');
    
    signal tx_busy        : std_logic;
    signal tx_ena         : std_logic;
    signal rx_busy        : std_logic;
    
begin


    tx_busy <= tx_busy_i;
    tx_ena_o <= tx_ena;
    rx_busy <= rx_busy_i;
    
 -- UART logic controller
	uart_logic_proc : process (clk_i, rst_i, rx_busy, rx_data_i, tx_busy)
	begin
        if rst_i = '1' then
            tx_ena   <= '0';
            tx_data_o  <= (others => '0');
            uart_state <= IDLE;
            
            test_data_cntr <= (others => '0');
            
		elsif rising_edge(clk_i) then
            
            --tx_ena <= '0';
            
            case uart_state is
			
			    when IDLE => 
                    --tx_data    <= (others => '0');
                    tx_ena <= '0';
                    if rx_busy = '1' then
                        uart_state <= RECEIVE_STATE;
                    end if;
            
                when RECEIVE_STATE => 
                    if rx_busy = '0' then
                       --if rx_data_i = x"55" then
                          tx_data_o   <= x"41";
                          tx_ena    <= '1';
                          
                          test_data_cntr <= test_data_cntr + '1';
                          uart_state     <= TRANSMIT_STATE;
                          
                       --end if; 
                    end if;

                
                when TRANSMIT_STATE => 
                    tx_ena    <= '0';
                    
                    if tx_busy = '0' then
                        
                        if test_data_cntr > x"400000" then --4194304 then
                            test_data_cntr <= (others => '0');
                            uart_state <= IDLE; 
                        else
                            tx_ena     <= '1';
                            uart_state <= RECEIVE_STATE; 
                        end if;
                    else
                        uart_state <= TRANSMIT_STATE;
                    end if;
                
            when others =>
            
            end case;
		end if;
	end process uart_logic_proc;
	
	
	  -- UART ILA
    uart_ila_inst : uart_ila
    PORT MAP (
        clk => clk_i,

        probe0(0) => rst_i, 
        probe1(0) => tx_busy, 
        probe2(0) => tx_ena, 
        probe3(0) => rx_busy, 
        probe4    => (others => '0'),
        probe5    => test_data_cntr,
        probe6    => (others => '0')
    );  


end Behavioral;
