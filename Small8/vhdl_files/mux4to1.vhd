library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mux4to1 is 
    port (
        sel: in std_logic_vector(1 downto 0) := "00";
        input_0, input_1, input_2, input_3: in std_logic_vector(15 downto 0) := (others => '0');
        data_out: out std_logic_vector(15 downto 0)
    );
end mux4to1;

architecture behavior of mux4to1 is begin

    case sel is 
        when "00" => 
            data_out <= input_0;
        when "01" => 
            data_out <= input_1;
        when "10" => 
            data_out <= input_2;
        when "11" => 
            data_out <= input_3;
        when others 
            data_out <= (others => '0');

end behavior;