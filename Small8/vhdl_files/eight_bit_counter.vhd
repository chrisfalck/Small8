library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity eight_bit_counter is
    generic(
        count_up_to : positive := 128;
        width : positive := 8
    );

    -- All logic is high true.
    port(
        clock:      in std_logic := '0';
        reset:      in std_logic := '0';
        load:       in std_logic := '0';
        hold:       in std_logic := '0';
        current:    buffer std_logic_vector((width - 1) downto 0) := (others => '0');
        ld_val:     in std_logic_vector((width - 1) downto 0) := (others => '0')
    );
end eight_bit_counter;

architecture behavior of eight_bit_counter is
begin
    counterLogic : process(clock, current)

        variable increment_current : std_logic_vector((width - 1) downto 0) := (others => '0');
        variable counting_limit_reached : std_logic := '0';
        
    begin

        if (unsigned(current) = to_unsigned(count_up_to, width)) then
            counting_limit_reached := '1';
        else 
            counting_limit_reached := '0';
        end if;

        if (clock'event and clock = '1' and counting_limit_reached = '0') then -- Wait for rising clock edge.

            if (reset = '1') then -- If reset is true, set values to 0.
                current <= std_logic_vector(to_unsigned(0, width));
            elsif (hold = '0') then -- If hold is true, take no action.

                if (load = '1') then -- If hold is false and load is true, load ld_val.
                    current <= ld_val;
                else -- If no other block has been executed, we should increment the current value.
                    increment_current := std_logic_vector(unsigned(current) + to_unsigned(1, width));
                    current <= increment_current;
                end if;
            end if;
        end if;

        if (clock'event and clock = '1' and counting_limit_reached = '1') then -- Wait for rising clock edge.
            current <= std_logic_vector(to_unsigned(0, width));
        end if;

    end process counterLogic;
end architecture;











--