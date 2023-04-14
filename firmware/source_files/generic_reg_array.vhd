---------------------------------------------------------
--
-- File:         generic_reg_array.vhd
-- Author:       funsten1
-- Description:  Writes a register through a depth of registers across the FPGA fabric to read out.
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

entity d_ff is
    port (
        d_in:     in    std_logic;
        clk:      in    std_logic;
        rst:      in    std_logic;
        q_out:    out   std_logic
    );
end entity;

architecture foo of d_ff is

    signal q:   std_logic;

begin

ff:
    process (clk, rst)
    begin
        if (rst = '1') then
			q <= '0';
		elsif clk'event and clk = '1' then
            q <= d_in;
        end if;
    end process;

    q_out <= q;

end architecture;

library ieee;
use ieee.std_logic_1164.all;

entity reg is
   generic (
      reg_width     : integer := 8;
      reg_depth     : integer := 20000
   );
port (
    clk			:	in  std_logic;
    rst			:	in  std_logic;
    data_in		:	in  std_logic_vector(reg_width -1 downto 0);
    data_out	:	out std_logic_vector(reg_width -1 downto 0)
 
);
end reg;

architecture behv_nxm_reg of reg is

-- d flip flop component
component d_ff
    port (
        d_in:       in    std_logic;
        clk:        in    std_logic;
        rst:        in    std_logic;
        q_out:      out   std_logic
    );
end component;

-- internal signals used
type reg_array is array (0 to reg_depth) of std_logic_vector(reg_width -1 downto 0);
signal wrt_data, q	: reg_array;

begin

	wrt_data(0)(reg_width -1 downto 0)	<= data_in;
	data_out <= q(reg_depth -1)(reg_width -1 downto 0);

gen_d_ff:
    for row in 0 to reg_depth -1 generate
    begin
gen_d_ff0:
        for col in 0 to reg_width -1 generate
        begin
dff_x:  
            d_ff 
            port map(
                d_in => wrt_data(row)(col), 
                clk => clk, 
				rst => rst,
                q_out => q(row)(col)
            );
			wrt_data(row+1)(col) <= q(row)(col);
        end generate;
    end generate;

end architecture;