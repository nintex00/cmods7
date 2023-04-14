---------------------------------------------------------
--
-- File:         packet_encode_decode.vhd
-- Author:       funsten1
-- Description:  Packet encode/decode module for handling bytes received and transmitted from UART.
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
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity packet_encode_decode is
    generic(
        fpga_rev     : std_logic_vector(23 downto 0) := x"230404"; -- Revision date.
        uart_d_width : integer := 8                                -- UART Data bus width
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
     tx_data_o  :  out  std_logic_vector(uart_d_width-1 downto 0); -- Data to transmit
     
     -- XADC
     xadc_addr_o : out  std_logic_vector(7 downto 0);              -- XADC address to send to the XADC IP core.
     xadc_out_i  : in   std_logic_vector(15 downto 0);             -- XADC data read in for wriitng out through UART.
     xadc_data_valid_i : in  std_logic;                            -- Valid pin from XADC to write data to UART.
     xadc_enable_o     : out std_logic                             -- Enable flag to tell the XADC, UART is ready to write data.
    
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
    
    -- Fifo IP core 16 bits write, 8 bits read, with depth 16 samples.
    COMPONENT fifo_16b_write_8b_read_16_depth
      PORT (
        clk : IN STD_LOGIC;
        srst : IN STD_LOGIC;
        din : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
        wr_en : IN STD_LOGIC;
        rd_en : IN STD_LOGIC;
        dout : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
        full : OUT STD_LOGIC;
        empty : OUT STD_LOGIC;
        rd_data_count : OUT STD_LOGIC_VECTOR(5 DOWNTO 0);
        wr_data_count : OUT STD_LOGIC_VECTOR(4 DOWNTO 0)
      );
    END COMPONENT;
    
    COMPONENT blk_mem_gen_0
    PORT (
        clka : IN STD_LOGIC;
        ena : IN STD_LOGIC;
        wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
        addra : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
        dina : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
        clkb : IN STD_LOGIC;
        enb : IN STD_LOGIC;
        addrb : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
        doutb : OUT STD_LOGIC_VECTOR(15 DOWNTO 0)
    );
    END COMPONENT;
    
    -- State for UART
    type uart_state_type   is (IDLE, RECEIVE_STATE, COUNT_SAMPLES, READ_FROM_FIFO, WAIT_FOR_READING, ASSIGN_BYTE_FROM_FIFO, ASSIGN_BYTE_1, ASSIGN_BYTE_2, WAIT_FOR_BUSY, TRANSMIT_STATE, WAIT_FOR_BRAM, READ_FROM_BRAM, WAIT_FOR_READING_BRAM_1, WAIT_FOR_READING_BRAM_2, ASSIGN_BYTE1_FROM_BRAM, ASSIGN_BYTE2_FROM_BRAM, WAIT_FOR_XADC_VALID);						  
    signal uart_state : uart_state_type := IDLE;   
    
    signal test_data_cntr : std_logic_vector(22 downto 0) := (others => '0');
    signal test_data      : std_logic_vector(22 downto 0) := (others => '0');
    
    signal tx_busy        : std_logic;
    signal tx_ena         : std_logic;
    signal rx_busy        : std_logic;
    
    -- Fifo signals
    signal data_16b       : std_logic_vector(15 downto 0) := (others => '0'); -- Data to write to the fifo in samples of 16 bits.
    signal data_8b        : std_logic_vector(7 downto 0)  := (others => '0'); -- Data to read from the fifo in samples of 8 bits.
    signal wr_en          : std_logic := '0'; -- When '1', fifo will write 16b samples.
    signal rd_en          : std_logic := '0'; -- When '1', fifo will read out 8b samples.
    signal byte_cntr      : integer   := 0;   -- Count bytes.
    signal burst_flag     : std_logic := '0'; -- Flag indicating that a read burst is taking place.
    
    -- FPGA Rev Flag
    signal fpga_rev_flag  : std_logic := '0'; -- Flag indicating the fpga_rev register is to be readout.
    
    -- BRAM signals
    signal bram_read_addr  : std_logic_vector(15 downto 0) := (others => '0'); 
    signal bram_read_data  : std_logic_vector(15 downto 0) := (others => '0'); 
    signal bram_read_en    : std_logic := '0'; 
    signal bram_flag       : std_logic := '0';
    
    -- XADC signals
    signal xadc_flag       : std_logic := '0';
begin


    tx_busy <= tx_busy_i;
    tx_ena_o <= tx_ena;
    rx_busy <= rx_busy_i;
    
 -- UART logic controller
	uart_logic_proc : process (clk_i, rst_i, rx_busy, rx_data_i, tx_busy, data_8b, xadc_data_valid_i)
	begin
        if rst_i = '1' then
            tx_ena   <= '0';
            tx_data_o  <= (others => '0');
            uart_state <= IDLE;
            
            test_data_cntr <= (others => '0');
            data_16b       <= (others => '0');
            wr_en          <= '0';
            rd_en          <= '0';
            byte_cntr      <=  0;
            burst_flag     <= '0';
            fpga_rev_flag  <= '0';
            bram_flag      <= '0';
            bram_read_addr <= (others => '0');
            bram_read_en   <= '0';
            xadc_flag      <= '0';
            xadc_enable_o  <= '0';
            
		elsif rising_edge(clk_i) then
            
            tx_ena <= '0';
            wr_en <= '0';
            rd_en <= '0';
            xadc_enable_o <= '0';
            
            case uart_state is
			
			    when IDLE => 
                    tx_ena    <= '0';
                    
                    test_data_cntr <= (others => '0');
                    data_16b       <= (others => '0');
                    burst_flag     <= '0';
                    fpga_rev_flag  <= '0';
                    bram_flag      <= '0';
                    xadc_flag      <= '0';
                    bram_read_addr <= (others => '0');
                    byte_cntr      <=  0;
                    --bram_read_en   <= '0';      
                            
                    if rx_busy = '1' then
                        uart_state <= RECEIVE_STATE;
                    end if;
            
                when RECEIVE_STATE => 
                   if rx_busy = '0' then
                    
                       -- Read burst of data
                       if rx_data_i = x"55" then
                          burst_flag  <= '1';
                          uart_state  <= COUNT_SAMPLES;
                          
                       elsif rx_data_i = x"41" then
                          tx_data_o   <= x"32";
                          tx_ena      <= '1';  
                          uart_state  <= WAIT_FOR_BUSY;    
                       
                       elsif rx_data_i = x"20" then
                          fpga_rev_flag <= '1';
                          tx_ena        <= '1';
                          tx_data_o     <= fpga_rev(23 downto 16);
                          uart_state    <= WAIT_FOR_BUSY;
                           
                       elsif rx_data_i = x"30" then
                            bram_flag    <= '1';
                            bram_read_en <= '1';
                            uart_state   <= WAIT_FOR_BRAM;
                            
                       elsif (rx_data_i = x"00") or (rx_data_i = x"15") or (rx_data_i = x"1C") then
                            xadc_addr_o  <= rx_data_i;
                            xadc_enable_o  <= '1';
                            uart_state   <= WAIT_FOR_XADC_VALID;

                       end if; 
                       
                   end if;
                    
                when COUNT_SAMPLES => 
                      if (data_16b > x"FFFF") then
                        data_16b <= (others => '0');
                      else
                        wr_en    <= '1'; -- Write to fifo.
                      end if; 
                      
                      uart_state  <= READ_FROM_FIFO;
                      
                
                      
                when READ_FROM_FIFO =>
                    if byte_cntr = 0 then
                        data_16b   <= data_16b + '1';
                    end if;
                    
                    rd_en      <= '1';
                    uart_state <= WAIT_FOR_READING;
                
                when WAIT_FOR_BRAM =>
                    uart_state <= READ_FROM_BRAM;
                    
                when READ_FROM_BRAM =>
                    if byte_cntr = 1 then
                        byte_cntr      <= 0;
                        bram_read_addr <= bram_read_addr + '1';
                        test_data_cntr <= test_data_cntr + '1';
                    end if;
                    
                    --bram_read_en <= '1';
                    uart_state   <= WAIT_FOR_READING_BRAM_1;
                    
                when WAIT_FOR_READING => 
                    uart_state     <= ASSIGN_BYTE_FROM_FIFO;
               
               when WAIT_FOR_READING_BRAM_1 => 
                    uart_state     <= WAIT_FOR_READING_BRAM_2; 
                when WAIT_FOR_READING_BRAM_2 => 
                    uart_state     <= ASSIGN_BYTE1_FROM_BRAM;
                    
                when ASSIGN_BYTE_FROM_FIFO =>
                    tx_data_o   <= data_8b;
                    tx_ena      <= '1';
                      
                    test_data_cntr <= test_data_cntr + '1';
                    uart_state     <= WAIT_FOR_BUSY;
                
                when ASSIGN_BYTE1_FROM_BRAM =>
                    tx_data_o      <= bram_read_data(15 downto 8);
                    tx_ena         <= '1';
                    --test_data_cntr <= test_data_cntr + '1';
                    uart_state     <= WAIT_FOR_BUSY;
                
                when ASSIGN_BYTE2_FROM_BRAM =>
                    tx_data_o      <= bram_read_data(7 downto 0);
                    tx_ena         <= '1';
                    --test_data_cntr <= test_data_cntr + '1';
                    uart_state     <= WAIT_FOR_BUSY;
                    
                when ASSIGN_BYTE_1 =>
                    tx_ena     <= '1';
                    if fpga_rev_flag = '1' then
                        tx_data_o  <= fpga_rev(15 downto 8);
                    elsif xadc_flag = '1' then
                        tx_data_o  <= xadc_out_i(7 downto 0);
                    end if;
                    uart_state <= WAIT_FOR_BUSY;
                    
                when ASSIGN_BYTE_2 =>
                    tx_ena     <= '1';
                    tx_data_o  <= fpga_rev(7 downto 0);
                    uart_state <= WAIT_FOR_BUSY;
                                           
                when WAIT_FOR_BUSY => 
                    uart_state <= TRANSMIT_STATE;
                
                when WAIT_FOR_XADC_VALID =>
                    if xadc_data_valid_i = '1' then
                        xadc_flag    <= '1'; 
                        tx_ena       <= '1';
                        tx_data_o    <= xadc_out_i(15 downto 8);
                        uart_state   <= WAIT_FOR_BUSY;
                    end if;
                
                when TRANSMIT_STATE => 
                    
                    if tx_busy = '0' and burst_flag = '1' then
                         
                        if byte_cntr = 1 then
                            byte_cntr  <= 0;
                            if test_data_cntr >= x"400000" then  --4194304 then
                                uart_state     <= IDLE; 
                            else
                                uart_state <= COUNT_SAMPLES; 
                            end if;
                        else
                            byte_cntr  <= byte_cntr + 1;
                            uart_state <= READ_FROM_FIFO;
                        end if;
                    elsif tx_busy = '1' then
                        uart_state <= TRANSMIT_STATE;
                    elsif fpga_rev_flag = '1' then
                        if byte_cntr = 2 then
                           byte_cntr <= 0;
                           uart_state <= IDLE;
                        elsif byte_cntr = 1 then
                           byte_cntr  <= byte_cntr + 1;
                           uart_state <= ASSIGN_BYTE_2;                         
                        elsif byte_cntr = 0 then
                           byte_cntr  <= byte_cntr + 1;
                           uart_state <= ASSIGN_BYTE_1;
                        end if;
                    elsif xadc_flag = '1' then
                        if byte_cntr = 1 then
                            byte_cntr <= 0;
                            uart_state <= IDLE;
                        elsif byte_cntr = 0 then
                            byte_cntr  <= byte_cntr + 1;
                            uart_state <= ASSIGN_BYTE_1;
                        end if;
                            
                    elsif tx_busy = '0' and bram_flag = '1' then
                        if byte_cntr = 1 then
                            if bram_read_addr >= x"FFFF" then
                                uart_state     <= IDLE; 
                            else
                                uart_state <= READ_FROM_BRAM; 
                            end if;
                        else
                            byte_cntr  <= byte_cntr + 1;
                            uart_state <= ASSIGN_BYTE2_FROM_BRAM;
                        end if;
                    else
                        uart_state <= IDLE;
                    end if;
                
            when others =>
            
            end case;
		end if;
	end process uart_logic_proc;
	
  -- Fifo for reading out the image data generated from the FPGA. Writes 16-bit samples and immediately reads 8 bit samples for UART.
  fifo_burst_read_inst : fifo_16b_write_8b_read_16_depth
  PORT MAP (
    clk => clk_i,
    srst => rst_i,
    din => data_16b,
    wr_en => wr_en,
    rd_en => rd_en,
    dout => data_8b,
    full => OPEN,
    empty => OPEN,
    rd_data_count => OPEN,
    wr_data_count => OPEN
  );
	
	-- UART ILA
   -- uart_ila_inst : uart_ila
--    PORT MAP (
--        clk => clk_i,

--        probe0(0) => rst_i, 
--        probe1(0) => rd_en, 
--        probe2(0) => tx_ena, 
--        probe3(0) => rx_busy, 
--        probe4(0) => wr_en,
--        probe5    => test_data_cntr,
--        probe6    => data_8b
--    );  

    -- Block memory IP core with an internal block memory data of a signal to read out through UART using a COE file.
    blk_mem_inst : blk_mem_gen_0
      PORT MAP (
        -- Write Ports
        clka    => '0',              -- Port A operations are synchronous to this chock.
        ena     => '1',              -- Enables Read, Write, and reset operations through Port A. 
        wea(0)  => '0',              -- Enables Write operations through port A. 
        addra   => (others => '0'),  -- Addresses the memory space for port A Write operations.
        dina    => (others => '0'),  -- Data input to be written into memory through Port A.
        
        -- Read Ports
        clkb    => clk_i,          -- Port B operations are synchronous to this chock.
        enb     => bram_read_en,   -- Enables Read, write and reset operations through Port B.
        addrb   => bram_read_addr, -- Addresses the memory space for port B Read operations.
        doutb   => bram_read_data  -- Data output from Read operations through port B.
      );
end Behavioral;
