---------------------------------------------------------
--
-- File:         xadc_top.vhd
-- Author:       funsten1
-- Description:  Top xadc interface for 1 MSps 10-bit internal ADC to FPGA.
-- Since the CMODS7's system clock is 12 MHz, the DRP functionality of the XADC
-- restricts the sample rate to 231 kSps. With continuous channel sequencing,
-- the sample rate is decreased. This XADC samples the temperature, VAUX5, and VAUX12 ports.
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
        
        xadc_addr_i : in std_logic_vector(7 downto 0);   -- XADC address for read/write of data using the DRP functionality.
        xadc_o      : out std_logic_vector(15 downto 0); -- XADC DRP output.
        
        xadc_enable_i     : in  std_logic := '0';
        xadc_data_valid_o : out std_logic := '0';        -- XADC data valid flag.
        
        -- XADC dedicated pins
        vaux5p_i   : in std_logic; -- XADC positive pin for VAUX5
        vaux5n_i   : in std_logic; -- XADC negative pin for VAUX5
        vaux12p_i  : in std_logic; -- XADC positive pin for VAUX12
        vaux12n_i  : in std_logic  -- XADC negative pin for VAUX12
    );
end xadc_top;

architecture Behavioral of xadc_top is

    -- XADC ILA
    COMPONENT xadc_ila 
    PORT (
        clk : IN STD_LOGIC;

        probe0 : IN STD_LOGIC_VECTOR(0 DOWNTO 0); 
        probe1 : IN STD_LOGIC_VECTOR(0 DOWNTO 0); 
        probe2 : IN STD_LOGIC_VECTOR(0 DOWNTO 0); 
        probe3 : IN STD_LOGIC_VECTOR(0 DOWNTO 0); 
        probe4 : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
        probe5 : IN STD_LOGIC_VECTOR(15 DOWNTO 0)
    );
    END COMPONENT;

    -- XADC IP core
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

    signal di_in    : std_logic_vector(15 downto 0) := (others => '0');    -- DRP data in to the XADC. For writing.
    signal do_out   : std_logic_vector(15 downto 0) := (others => '0');    -- DRP data out. For reading.
    signal dwe_in   : std_logic := '0';                                    -- DRP write enable.
    signal den_in   : std_logic := '1';                                    -- DRP read enable.
    signal drdy_out : std_logic;                                           -- Indicates data is ready from XADC.
    signal xadc_addr    : std_logic_vector(6 downto 0) := (others => '0'); -- DRP channel address to read temp, VAUX5, or VAUX12.

    -- State for XADC
    type xadc_state_type   is (ENABLE_XADC, WAIT_FOR_DATA_READY);						  
    signal xadc_state : xadc_state_type := ENABLE_XADC;   
    
begin

    xadc_o    <= do_out; 
    xadc_addr <= xadc_addr_i(6 downto 0);
    
    -- For controlling the enable and data ready between the communications interface and the XADC.
    xadc_addr_proc : process (clk_i, rst_i, xadc_enable_i, drdy_out)
	begin
        if rst_i = '1' then
            xadc_data_valid_o <= '0';
            xadc_state        <= ENABLE_XADC;
            
		elsif rising_edge(clk_i) then
   
            case xadc_state is
			
			    when ENABLE_XADC => 
			         -- Detect if the communication interface xadc flag 
			         -- is enabled, then be ready to read from xadc.
			         if xadc_enable_i = '1' then
                         den_in            <= '1';      
                         xadc_state        <= WAIT_FOR_DATA_READY;
                     end if;
                     
                     xadc_data_valid_o <= '0';
			
			    when WAIT_FOR_DATA_READY =>
			         -- Immediately turn off data enable for the DRP on 
			         -- the XADC and wait for data ready to send data valid
			         -- flag for writing the data to UART.
			         den_in <= '0';
			         
			         if drdy_out = '1' then
			             xadc_data_valid_o <= '1';
			             xadc_state        <= ENABLE_XADC;
			         end if; 
			    when others =>
			    
            end case;           
            
        end if;  
            
    end process xadc_addr_proc;
      
      
    xadc_inst : xadc_wiz_0
      PORT MAP (
        di_in => di_in,
        daddr_in => xadc_addr, --"001" & x"5", -- x"00" for temp, x"15" for vaux5, and x"1C" for vaux12
        den_in => den_in,
        dwe_in => dwe_in,
        drdy_out => drdy_out,
        do_out => do_out,
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
   
   
--   xadc_ila_inst : xadc_ila
--    PORT MAP (
--        clk => clk_i,
    
--        probe0(0) => dwe_in, 
--        probe1(0) => den_in, 
--        probe2(0) => drdy_out, 
--        probe3 => (others => '0'), 
--        probe4 => di_in,
--        probe5 => do_out
--    );

end Behavioral;
