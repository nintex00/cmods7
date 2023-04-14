---------------------------------------------------------
--
-- File:         dac_driver.vhd
-- Author:       funsten1
-- Description:  x2 DACs from PMOD D2A board, MFPN: DAC121S101/-Q1. 
-- This is the DAC driver to drive the Serial Peripheral Interface (SPI) logic.
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

entity dac_driver is
    port ( 
        -- Clocks and reset
        clk_i    : in std_logic; -- System clock.
        rst_i    : in std_logic; -- Active-high push-button reset.
        gpio_i   : in std_logic; -- Push-button for testing DAC.
        
        -- x2 DACs from PMOD D2A board, MFPN: DAC121S101/-Q1.
        dac_seta_i      : in  std_logic_vector(11 downto 0); -- 12-bit data for assigning to DAC A.
        dac_setb_i      : in  std_logic_vector(11 downto 0); -- 12-bit data for assigning to DAC B.
        dac_dina_o      : out std_logic; -- Serial data input for DAC A (IC1).
        dac_dinb_o      : out std_logic; -- Serial data input for DAC B (IC2).
        dac_sclk_o      : out std_logic; -- For the two DACs. Serial clock input clocked on falling edges of this pin.
        dac_sync_n_o    : out std_logic  -- For the two DACs. Active-low frame synchronization input for data input. When '0', the input shift register is enabled to transfer data on falling edge of dac_sclk_o.                 
    );
end dac_driver;

architecture Behavioral of dac_driver is


--    COMPONENT dac_ila
--    PORT (
--        clk : IN STD_LOGIC;
    
--        probe0 : IN STD_LOGIC_VECTOR(15 DOWNTO 0); 
--        probe1 : IN STD_LOGIC_VECTOR(15 DOWNTO 0); 
--        probe2 : IN STD_LOGIC_VECTOR(0 DOWNTO 0); 
--        probe3 : IN STD_LOGIC_VECTOR(0 DOWNTO 0); 
--        probe4 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
--        probe5 : IN STD_LOGIC_VECTOR(0 DOWNTO 0)
--    );
--    END COMPONENT;

    signal clk_6mhz     : std_logic := '0';
    
    signal dac_sclk     : std_logic;
    signal dac_sync_n   : std_logic := '1';
    signal dac_dina_vec : std_logic_vector(15 downto 0) := (others => '0');
    signal dac_dinb_vec : std_logic_vector(15 downto 0) := (others => '0');
    
    signal dac_cntr   : integer := 0;
    
    signal gpio_dl    : std_logic; -- Delayed gpio_i by one clock cycle.
    
    -- State for DAC
    type dac_state_type   is (SYNC_HIGH, SYNC_LOW);						  
    signal dac_state : dac_state_type := SYNC_HIGH;   
    
begin

    dac_sync_n_o <= dac_sync_n;
    dac_dina_o   <= dac_dina_vec(15);
    dac_dinb_o   <= dac_dinb_vec(15);
    dac_sclk_o   <= dac_sclk;
    
    -- Divide clk_i from 12 MHz to 6 MHz
 	div_clk_proc : process (clk_i, rst_i)
	begin 
	    if rst_i = '1' then
	       clk_6mhz <= '0';
	       
		elsif rising_edge(clk_i) then 
           clk_6mhz <= not(clk_6mhz);
        end if;
    end process div_clk_proc;
    
    dac_sclk   <= clk_6mhz;
    
    -- DAC SPI Driver Process
	dac_driver_proc : process (dac_sclk, rst_i, gpio_i, dac_seta_i, dac_setb_i)
	begin
        if rst_i = '1' then
        
            dac_sync_n <= '1';
            dac_cntr   <=  0;
            dac_state  <= SYNC_HIGH;
            
		elsif rising_edge(dac_sclk) then
            
            dac_sync_n <= '1';
            gpio_dl <= gpio_i;
            
            case dac_state is
			
			    when SYNC_HIGH => 
                    dac_dina_vec <= "00" & "00" & dac_seta_i;
                    dac_dinb_vec <= "00" & "00" & dac_setb_i;   
                    
                    if gpio_i = '1' and gpio_dl = '0' then
                        dac_state <= SYNC_LOW;
                        dac_sync_n   <= '0';
                    end if;
                
                when SYNC_LOW =>
     
                    if dac_cntr >= 15 then
                        dac_cntr   <= 0;
                        dac_sync_n <= '1';
                        dac_state  <= SYNC_LOW;
                    else
                        dac_sync_n    <= '0';
                        dac_dina_vec  <= dac_dina_vec(14 downto 0) & '0'; -- Shift bits for DAC A.
                        dac_dinb_vec  <= dac_dinb_vec(14 downto 0) & '0'; -- Shift bits for DAC A.
                        dac_cntr      <= dac_cntr + 1;
                    end if;  
                
            when others =>
            
            end case;
		end if;
	end process dac_driver_proc;
	
--    dac_ila_inst : dac_ila
--    PORT MAP (
--        clk => clk_i,
    
--        probe0 => dac_dina_vec, 
--        probe1 => dac_dinb_vec, 
--        probe2(0) => dac_sync_n, 
--        probe3(0) => gpio_i, 
--        probe4(0) => dac_dina_vec(15),
--        probe5(0) => dac_sclk
--    );

end Behavioral;
