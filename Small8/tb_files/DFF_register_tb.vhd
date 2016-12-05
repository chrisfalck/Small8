library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity DFF_register_tb is
end DFF_register_tb;

architecture behavior of DFF_register_tb is
    component DFF_register   
    generic (width : positive);
    port (
        clock, load, clear, out_enable, inc: in std_logic := '0';
        data_in: in std_logic_vector((width - 1) downto 0) := (others => '0');
        data_out: out std_logic_vector((width - 1) downto 0) := (others => '0') 
    );
    end component;

    signal clock_signal, load_signal, clear_signal, out_enable_sig, inc_sig : std_logic;
    signal data_in_signal, data_out_signal : std_logic_vector(7 downto 0);

begin

    Register_instance: DFF_register
    generic map (width => 8)
    port map (
        clock => clock_signal,
        load => load_signal,
        out_enable => out_enable_sig,
        inc => inc_sig,
        clear => clear_signal,
        data_in => data_in_signal,
        data_out => data_out_signal
    );

    process begin
        out_enable_sig <= '1';
        inc_sig <= '1';
        clock_signal <= '0';
        load_signal <= '1';
        clear_signal <= '0';
        data_in_signal <= (std_logic_vector(to_unsigned(25, 8)));
        wait for 50 ns;
        clock_signal <= '1';
        wait for 50 ns;

        clock_signal <= '0';
        load_signal <= '0';
        clear_signal <= '0';
        data_in_signal <= (std_logic_vector(to_unsigned(25, 8)));
        wait for 50 ns;
        clock_signal <= '1';
        wait for 50 ns;

        clock_signal <= '0';
        load_signal <= '0';
        clear_signal <= '1';
        data_in_signal <= (std_logic_vector(to_unsigned(25, 8)));
        wait for 50 ns;
        clock_signal <= '1';
        wait for 50 ns;

        clock_signal <= '0';
        load_signal <= '1';
        clear_signal <= '1';
        data_in_signal <= (std_logic_vector(to_unsigned(25, 8)));
        wait for 50 ns;
        clock_signal <= '1';
        wait for 50 ns;

        wait;
    end process;

end behavior; -- behavrio