---------------------------------------------------------
--
-- File:         hamming_encoding.vhd
-- Author:       funsten1
-- Description:  In this example, the hamming_encoding module takes a 5-bit input data_i and
-- outputs an 8-bit encoded value encoded. The first 5 bits of encoded are simply the
-- same as the input bits. The last 3 bits are parity bits that are computed using XOR 
-- operations on certain combinations of the input bits. This produces a Hamming code with a
-- distance of 3, meaning that it can detect up to 2 errors and correct 1 error.
-- Note that this is just a simple example and in practice, more complex Hamming codes can be 
-- implemented with larger input sizes and more parity bits.
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

entity hamming_encoding is
    port (
    -- Input
    data_i     : in  std_logic_vector(4 downto 0);
    
    -- Output
    encoded_o  : out std_logic_vector(7 downto 0) 
    );
end hamming_encoding;

architecture Behavioral of hamming_encoding is

begin

  encoded_o(0) <= data_i(0);
  encoded_o(1) <= data_i(1);
  encoded_o(2) <= data_i(2);
  encoded_o(3) <= data_i(3);
  encoded_o(4) <= data_i(4);
  
  encoded_o(5) <= data_i(0) xor data_i(1) xor data_i(3);
  encoded_o(6) <= data_i(0) xor data_i(2) xor data_i(3);
  encoded_o(7) <= data_i(0) xor data_i(1) xor data_i(2) xor data_i(4);
  
end Behavioral;
