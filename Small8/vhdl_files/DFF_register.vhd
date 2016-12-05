-- Variable length DFF register with synchronous load and clear. 
library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity DFF_register is
  generic (width : positive := 8);
  port (
      clock, load, clear, out_enable, inc: in std_logic := '0';
      data_in: in std_logic_vector((width - 1) downto 0) := (others => '0');
      data_out: buffer std_logic_vector((width - 1) downto 0) := (others => '0')
  );
end DFF_register;

architecture behavior of DFF_register is

    signal data_out_sig: std_logic_vector((width - 1) downto 0) := (others => '0');

begin

    with out_enable select
         data_out <= data_out_sig when '1',
                     (others => 'Z') when others;

    process(clock, load) begin
        if (clock'event and clock = '1') then 
            if (clear = '1') then 
                data_out_sig <= (others => '0');
            elsif (load = '1') then 
                data_out_sig <= data_in;
            elsif (inc = '1') then 
                data_out_sig <= std_logic_vector(unsigned(data_out_sig) + to_unsigned(1, width));          
            else 
                data_out_sig <= data_out_sig;
            end if;
        end if;
    end process;

end behavior; -- arch

