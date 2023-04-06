---------------------------------------------------------
--
-- File:         piezo_buzzer.vhd
-- Author:       funsten1
-- Description:  Interfaces with piezo buzzer to generate music.
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
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity piezo_buzzer is
    generic (
        sys_clk_freq : integer  -- System clock frequency.
    );
    port ( 
     -- Inputs
     clk_i      :  in   std_logic; -- system clock
     rst_i      :  in   std_logic; -- scynchronous reset
     gpio_i     :  in   std_logic; -- Push button gpio
     
     -- Outputs
     tone_o     :  out  std_logic  -- Piezo buzzer tone for different frequencies.
    );
end piezo_buzzer;

architecture Behavioral of piezo_buzzer is

    constant freq_2khz : integer := 2_000;
   
    -- Musical notes in units of Hz
    constant c4 : integer := 262;
    constant d4 : integer := 294;
    constant e4 : integer := 330;
    constant f4 : integer := 349;
    constant g4 : integer := 394;
    constant a4 : integer := 440;
    constant b4 : integer := 494;
    constant c5 : integer := 523;
    
    -- Delay times in between notes in units of Hz
    constant delay1000ms : integer := 1;
    constant delay167ms  : integer := 6; 
    constant delay500ms  : integer := 2;
   
	
	-- Array of tones for melody
	type    star_wars_note_array_type is array(0 to 15) of integer;
    signal star_wars_note_array : star_wars_note_array_type :=     (c4,
                                                                    g4,
                                                                    f4,
                                                                    e4,
                                                                    d4,
                                                                    c5,
                                                                    g4,
                                                                    f4,
                                                                    e4,
                                                                    d4,
                                                                    c5,
                                                                    f4,
                                                                    g4,
                                                                    e4,
                                                                    f4,
                                                                    d4);

    -- Array of tones for melody
	type    star_wars_delay_array_type is array(0 to 14) of integer;
    signal star_wars_delay_array : star_wars_delay_array_type := (delay1000ms,
                                                                  delay1000ms,
                                                                  delay167ms,
                                                                  delay167ms,
                                                                  delay167ms,
                                                                  delay1000ms,
                                                                  delay500ms,
                                                                  delay167ms,
                                                                  delay167ms,
                                                                  delay167ms,
                                                                  delay1000ms,
                                                                  delay500ms,
                                                                  delay167ms,
                                                                  delay167ms,
                                                                  delay167ms);


    signal clk_xhz    : std_logic := '0'; -- Clock running at a particular note frequency.
    signal cntr_note  : integer   := 0;   -- Counter for X kHz notes.
    signal cntr_dly   : integer   := 0;   -- Counter for delay between notes
    
    signal gpio_dl    : std_logic; -- Delayed gpio_i by one clock cycle.
    
    -- State for Melody State Machine 
    type melody_state_type   is (IDLE, DELAY_STATE);						  
    signal melody_state : melody_state_type := IDLE;
    
    signal note_index : integer := 0;
    
    signal play_flag  : std_logic := '0';
    
begin

    tone_o <= clk_xhz;
                        
    -- Melody process
	melody_proc : process (clk_i, rst_i, gpio_i)
	begin
        if rst_i = '1' then
            melody_state <= IDLE;
            note_index   <= 0;
            play_flag    <= '0';
            
		elsif rising_edge(clk_i) then
            
            gpio_dl <= gpio_i;
            
            case melody_state is
			
			    when IDLE =>
			         note_index <= 0;
			         
			         if gpio_i = '1' and gpio_dl = '0' then
			             play_flag    <= '1';
			             melody_state <= DELAY_STATE;
                     else
                         play_flag <= '0';
			         end if;
			    
--			    when PLAY_TONE => 
   
--                    melody_state <= DELAY_STATE;
                    
                when DELAY_STATE =>
                    if note_index < 15 then
                        if(cntr_dly >= sys_clk_freq/star_wars_delay_array(note_index)) then
                            cntr_dly     <= 0;   
                            note_index   <= note_index + 1;
                            melody_state <= DELAY_STATE;
                        else
                            cntr_dly  <= cntr_dly + 1;
                        end if;
                    else
                        note_index   <= 0;
                        melody_state <= IDLE;
                    end if;
                    
            when others =>
            
            end case;
		end if;
	end process melody_proc;
	

    create_note_proc : process(clk_i, rst_i, play_flag, note_index)
    begin
        if rst_i = '1' then
            cntr_note <= 0;
            clk_xhz   <= '0';
        elsif rising_edge(clk_i) then
            if play_flag = '1' then
                if(cntr_note >= sys_clk_freq/star_wars_note_array(note_index)) then
                    cntr_note   <= 0;   
                    clk_xhz     <= not(clk_xhz);
                else
                    cntr_note  <= cntr_note + 1;
                end if;
            else
                cntr_note <= 0;
                clk_xhz   <= '0';
            end if;
        end if;
    end process create_note_proc;

end Behavioral;
