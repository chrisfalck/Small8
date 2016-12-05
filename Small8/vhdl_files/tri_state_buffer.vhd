library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tri_state_buffer is
    generic (width : positive := 8);
    port (
        data_in : in std_logic_vector((width - 1) downto 0) := (others => '0') ;
        data_out : out std_logic_vector((width - 1) downto 0) := (others => '0') ;
        out_enable: in std_logic := '0'
    );
end tri_state_buffer;

architecture behavior of tri_state_buffer is 
begin 

    with out_enable select
         data_out <= data_in when '1',
                     (others => 'Z') when others;

end behavior;