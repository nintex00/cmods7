---------------------------------------------------------
--
-- File:         blink_leds.vhd
-- Author:       funsten1
-- Description:  Blinks leds at 1 Hz. For this board, the RGB led toggles for 2 seconds
-- and the general LEDs blink at 1 Hz.
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
use IEEE.STD_LOGIC_UNSIGNED.all;

entity blink_leds is
    generic (
        sys_clk_freq : integer  -- System clock frequency.
    );
    port ( 
        -- Inputs
        clk_i    : in std_logic; -- System clock.
        rst_i    : in std_logic; -- Active-high push-button reset.
        duty_i   : in std_logic_vector(7 downto 0); -- Duty cycle value for pulse width modulation (PWM)) of RGB LED in 8-bits.

        -- Outputs
        led_o           : out std_logic_vector(3 downto 0) := (others => '0'); -- Active-high Four general purpose LEDs.
        led_blue_n_o    : out std_logic := '1';  -- Active-low Blue LED of RGB LED.
        led_green_n_o   : out std_logic := '1';  -- Active-low Green LED of RGB LED.
        led_red_n_o     : out std_logic := '1'   -- Active-low Red LED of RGB LED.
    );
end blink_leds;

architecture Behavioral of blink_leds is

    signal clk_1hz   : std_logic := '0'; -- Clock running at 1 Hz.
    signal cntr_1hz  : integer   := 0;   -- Counter for 1 Hz.
    
    -- State for RGB LED 
    type led_state_type   is (BLUE_STATE, GREEN_STATE, RED_STATE, VIOLET_STATE, YELLOW_STATE, CYAN_STATE, WHITE_STATE);						  
    signal led_state : led_state_type := BLUE_STATE;
    
    signal led_blue_n  : std_logic := '1';
    signal led_green_n : std_logic := '1';
    signal led_red_n   : std_logic := '1';
    
    -- For pulse width modulation (PWM) of RGB LED.
    signal cnt_reg  : unsigned(7 downto 0) := (others => '0');
    signal pwm_reg  : std_logic;
    signal duty_reg : unsigned(7 downto 0);  
begin
    
    -- 1 Hz generated from 12 MHz clock
	clk_1Hz_proc : process (clk_i, rst_i)
	begin
        if rst_i = '1' then
            cntr_1Hz <= 0;   
            clk_1hz  <= '0';
            
		elsif rising_edge(clk_i) then
			if(cntr_1Hz >= sys_clk_freq) then
                cntr_1Hz <= 0;   
                clk_1hz   <= not(clk_1hz);
            else
                cntr_1Hz  <= cntr_1Hz + 1;
            end if;
		end if;
	end process clk_1Hz_proc;
    
    led_o(0)  <= clk_1hz;
    led_o(1)  <= clk_1hz;
    led_o(2)  <= clk_1hz;
    led_o(3)  <= clk_1hz;
    
    
    -- Finite state machine for RGB LED
    rgb_led_proc : process(clk_1hz, rst_i)	
	begin
		if rst_i = '1' then
		  led_state <= BLUE_STATE;
          led_blue_n  <= '1';
          led_green_n <= '1';
          led_red_n   <= '1';  
              
        elsif rising_edge(clk_1hz) then
            led_blue_n  <= '1';
            led_green_n <= '1';
            led_red_n   <= '1';
            
            case led_state is
			
			    when BLUE_STATE => 
                    led_blue_n    <= '0';
                    led_state     <= GREEN_STATE;
            
                when GREEN_STATE => 
                    led_green_n   <= '0';
                    led_state     <= RED_STATE;
                
                when RED_STATE => 
                    led_red_n     <= '0';
                    led_state     <= VIOLET_STATE;
                    
                when VIOLET_STATE => 
                    led_red_n     <= '0';
                    led_blue_n    <= '0';
                    led_state     <= YELLOW_STATE;
          
                when YELLOW_STATE => 
                    led_green_n   <= '0';
                    led_red_n     <= '0';
                    led_state     <= CYAN_STATE;  
                    
                when CYAN_STATE => 
                    led_green_n   <= '0';
                    led_blue_n    <= '0';
                    led_state     <= WHITE_STATE;  
                    
               when WHITE_STATE => 
                    led_green_n   <= '0';
                    led_blue_n    <= '0';
                    led_red_n     <= '0';
                    led_state     <= BLUE_STATE;   
                
            when others =>
            
            end case;
             
		end if;	
	end process rgb_led_proc;  

    -- Invoke pulse width modulation on the RGB LED
    led_blue_n_o  <= led_blue_n  or pwm_reg;
    led_green_n_o <= led_green_n or pwm_reg;
    led_red_n_o   <= led_red_n   or pwm_reg;

    -- Duty cycle register
    duty_reg <= unsigned(duty_i);
	
    -- Pulse width modulation (PWM) for RGB LED
    pwm_rgb_led_proc : process(clk_i, rst_i)	
	begin
		if rst_i = '1' then
            cnt_reg <= (others => '0');
            pwm_reg <= '0';
		            
        elsif rising_edge(clk_i) then
          cnt_reg <= cnt_reg + 1;
          
          if cnt_reg = "11111111" then
             cnt_reg <= (others => '0');
          end if;
          
          if cnt_reg < duty_reg then
             pwm_reg <= '1';
          else
             pwm_reg <= '0';
          end if;
        end if;
	end process pwm_rgb_led_proc;  

end Behavioral;
