library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Small8_tb is 
end Small8_tb;

architecture behavior of Small8_tb is 
    component Small8
        port (
            inport_0, inport_1: in std_logic_vector(7 downto 0);
            outport_0, outport_1: out std_logic_vector(7 downto 0);
            clock, reset: in std_logic   
        );
    end component;

    signal inport_0_sig, inport_1_sig, outport_0_sig, outport_1_sig: std_logic_vector(7 downto 0) := (others => '0');
    signal clock_sig, reset_sig: std_logic := '0'; 
begin

    test_inst: Small8
    port map (
        inport_0 => inport_0_sig,
        inport_1 => inport_1_sig,
        outport_0 => outport_0_sig,
        outport_1 => outport_1_sig,
        clock => clock_sig, 
        reset => reset_sig
    );

    process begin
        reset_sig <= '1';
        clock_sig <= '1';
        wait for 50 ns;
        clock_sig <= '0';
        wait for 50 ns;
        reset_sig <= '0';

        for i in 0 to 500 loop
            clock_sig <= not(clock_sig);
            wait for 1000 ns;
        end loop;
        
    wait;
    end process;

end behavior;