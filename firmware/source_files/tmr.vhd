---------------------------------------------------------
--
-- File:         tmr.vhd
-- Author:       funsten1
-- Description:  Triple Modular Redundancy (tmr) module that takes a register
-- and registers into three independent registers. The outputs of the registers
-- are then passed through three 2-input AND gates followed by a third stage
-- OR gate. Thus this builds a voting logic circuit to prevent Single Event
-- Upsets (SEUs) from affecting a particular register.
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

entity tmr is
    generic (
        reg_depth : integer
    );
    port (
        clk_i : in std_logic;
        rst_i : in std_logic;
        
        data_i : in  std_logic_vector(reg_depth downto 0);
        data_o : out std_logic_vector(reg_depth downto 0)
    );
end tmr;

architecture Behavioral of tmr is

  signal reg1 : std_logic_vector(reg_depth downto 0);
  signal reg2 : std_logic_vector(reg_depth downto 0);
  signal reg3 : std_logic_vector(reg_depth downto 0);
    
begin

    -- Register the data input into three independent registers.
 	d_ff_proc : process (clk_i, rst_i, data_i)
	begin 
	    if rst_i = '1' then
	       reg1 <= (others => '0');
	       reg2 <= (others => '0');
	       reg3 <= (others => '0');
	       
		elsif rising_edge(clk_i) then 
           reg1 <= data_i;
           reg2 <= data_i;
           reg3 <= data_i;
        end if;
    end process d_ff_proc;

    -- Voting logic circuit
    data_o <= (reg1 and reg2) or (reg1 and reg3) or (reg2 and reg3);
 
end Behavioral;

 -- How to apply tmr to multiple registers elegantly:
 -- In this example, the tmr_example entity takes two generics: NUM_REGISTERS, which specifies the number of sets of registers to create, and DATA_WIDTH, which specifies the width of the data stored in each register. The outputs port returns the output of the voter circuits.

--The gen_registers generate statement creates NUM_REGISTERS sets of registers, each consisting of a process that increments the register value on the rising edge of the clock.

--The gen_voters generate statement creates DATA_WIDTH voters, each consisting of a set of inputs connected to the corresponding bit of each set of registers and an output connected to the corresponding bit of the output vector. The tmr_voter component takes an array of register inputs and outputs a single bit, which is combined into the output vector using std_logic_vector.

--This approach allows you to apply TMR to multiple registers in an elegant and scalable manner by using arrays and generate statements.

--library ieee;
--use ieee.std_logic_1164.all;

--entity tmr_example is
--  generic (
--    NUM_REGISTERS : integer := 3;
--    DATA_WIDTH    : integer := 8
--  );
--  port (
--    clk    : in  std_logic;
--    reset  : in  std_logic;
--    outputs : out std_logic_vector(DATA_WIDTH-1 downto 0)
--  );
--end entity tmr_example;

--architecture behavioral of tmr_example is
--  type register_array is array (0 to NUM_REGISTERS-1) of std_logic_vector(DATA_WIDTH-1 downto 0);
--  signal registers : register_array;

--  component tmr_voter is
--    port (
--      inputs : in  register_array;
--      output : out std_logic_vector(DATA_WIDTH-1 downto 0)
--    );
--  end component tmr_voter;

--begin
--  -- Generate sets of registers
--  gen_registers: for i in 0 to NUM_REGISTERS-1 generate
--    process (clk, reset)
--    begin
--      if reset = '1' then
--        registers(i) <= (others => '0');
--      elsif rising_edge(clk) then
--        registers(i) <= registers(i) + 1;
--      end if;
--    end process;
--  end generate;

--  -- Generate voters
--  gen_voters: for i in 0 to DATA_WIDTH-1 generate
--    signal inputs : register_array := (others => (others => '0'));
--    signal output : std_logic_vector(NUM_REGISTERS-1 downto 0);

--    begin
--      -- Connect inputs to registers
--      for j in 0 to NUM_REGISTERS-1 loop
--        inputs(j) <= registers(j)(i);
--      end loop;

--      -- Instantiate voter circuit
--      voter : tmr_voter port map (
--        inputs => inputs,
--        output => output(i)
--      );
--    end generate;

--  -- Output the result of the voter circuits
--  outputs <= std_logic_vector(output);
--end architecture behavioral;
  
