library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Top_Level is 
    port (
        clock, reset: in std_logic := '0';
        seven_seg_0, seven_seg_1, seven_seg_2, seven_seg_3: out std_logic_vector(6 downto 0);
        inport_0, inport_1: in std_logic_vector(7 downto 0)
    );
end Top_Level;

architecture behavior of Top_Level is

    component Small8
    port (
        inport_0, inport_1: in std_logic_vector(7 downto 0) := (others => '0');
        outport_0, outport_1: out std_logic_vector(7 downto 0) := (others => '0');
        clock, reset: in std_logic := '0'  
    );
    end component;

    component seven_segment
    port (
 		i: in std_logic_vector(3 downto 0);
		-- outputs a through g are low true.
		a,b,c,d,e,f,g	: out std_logic       
    );
    end component;

    signal seven_seg_coded_signal_0, seven_seg_coded_signal_1: std_logic_vector(7 downto 0);

begin

    Small8_inst: Small8
    port map (
        inport_0 => inport_0,
        inport_1 => inport_1,
        outport_0 => seven_seg_coded_signal_0,
        outport_1 => seven_seg_coded_signal_1,
        clock => clock,
        reset => reset
    );

    Seven_seg_0_inst: seven_segment
    port map (
        i => seven_seg_coded_signal_0(3 downto 0),
        a => seven_seg_0(6),
        b => seven_seg_0(5),
        c => seven_seg_0(4),
        d => seven_seg_0(3),
        e => seven_seg_0(2),
        f => seven_seg_0(1),
        g => seven_seg_0(0)
    );

    Seven_seg_1_inst: seven_segment
    port map (
        i => seven_seg_coded_signal_0(7 downto 4),
        a => seven_seg_1(6),
        b => seven_seg_1(5),
        c => seven_seg_1(4),
        d => seven_seg_1(3),
        e => seven_seg_1(2),
        f => seven_seg_1(1),
        g => seven_seg_1(0)
    );

    Seven_seg_2_inst: seven_segment
    port map (
        i => seven_seg_coded_signal_1(3 downto 0),
        a => seven_seg_2(6),
        b => seven_seg_2(5),
        c => seven_seg_2(4),
        d => seven_seg_2(3),
        e => seven_seg_2(2),
        f => seven_seg_2(1),
        g => seven_seg_2(0)
    );

    Seven_seg_3_inst: seven_segment
    port map (
        i => seven_seg_coded_signal_1(7 downto 4),
        a => seven_seg_3(6),
        b => seven_seg_3(5),
        c => seven_seg_3(4),
        d => seven_seg_3(3),
        e => seven_seg_3(2),
        f => seven_seg_3(1),
        g => seven_seg_3(0)
    );


end behavior;


















