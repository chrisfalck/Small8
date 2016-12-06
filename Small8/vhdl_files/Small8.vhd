library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Small8 is 
    port (
        inport_0, inport_1: in std_logic_vector(7 downto 0) := (others => '0');
        outport_0, outport_1: out std_logic_vector(7 downto 0) := (others => '0');
        clock, reset: in std_logic := '0'  
    );
end Small8;

architecture behavior of Small8 is 

    -- (2) = tristate enable, (1) = load, (0) = clear
    -- Accumulator register
    signal A_control_sig: std_logic_vector(3 downto 0) := (others => '0');
    -- Data register
    signal D_control_sig: std_logic_vector(3 downto 0) := (others => '0');
    -- Instruction register
    signal IR_control_sig, Temp_1_control_sig, Temp_2_control_sig, Temp_3_control_sig, Temp_4_control_sig, Temp_5_control_sig: std_logic_vector(3 downto 0) := (others => '0');

    
    -- (5) = upper tristate enable (4) = lower tristate enable, 
    -- (3) = upper load, (2) = upper clear, (1) lower load, (0) lower clear.
    -- Program counter registers    
    signal PC_control_sig: std_logic_vector(7 downto 0) := (others => '0');
    -- Index registers
    signal X_control_sig: std_logic_vector(7 downto 0) := (others => '0');
    -- Stack pointer registers
    signal SP_control_sig: std_logic_vector(7 downto 0) := (others => '0');
    -- Address register pointer registers
    signal AR_control_sig: std_logic_vector(7 downto 0) := (others => '0');

    -- ALU 
    -- (3) = Z, (2) = S, (1) = V, (0) = C
    signal ALU_flags_sig: std_logic_vector(3 downto 0) := (others => '0');
    signal ALU_control_sig: std_logic_vector(3 downto 0) := (others => '0');

    signal internal_data_bus_sig: std_logic_vector(7 downto 0) := (others => '0');

    signal ram_addr_bus_sig: std_logic_vector(15 downto 0) := (others => '0');
    signal ram_control_sig, ram_out_bus_control_sig: std_logic := '0';
    signal ram_tri_state_sig: std_logic_vector(7 downto 0):= (others => '0');

    signal ALU_flag_control_sig: std_logic_vector(7 downto 0);

    signal IR_data_sig: std_logic_vector(7 downto 0) := (others => '0');    
    component S8_Controller
        port (
            clock, reset: in std_logic;
            -- (3) = Z, (2) = S, (1) = V, (0) = C
            ALU_flags:  in std_logic_vector(3 downto 0);
            ALU_control: out std_logic_vector(3 downto 0);
            ALU_flag_control: out std_logic_vector(7 downto 0);
            IR_data: in std_logic_vector(7 downto 0);
            -- '1' = write to, '0' = read from
            Ram_control, ram_out_bus_control: out std_logic;
            -- (3) = increment, (2) = tristate enable, (1) = load, (0) = clear.
            A_control, D_control, IR_control, Temp_1_control, Temp_2_control, Temp_3_control, Temp_4_control, Temp_5_control: out std_logic_vector(3 downto 0); 
            -- (7) = upper increment (6) = lower increment (5) = upper tristate enable (4) = lower tristate enable, 
            -- (3) = upper load, (2) = upper clear, (1) lower load, (0) lower clear.
            PC_control, X_control, AR_control, SP_control: out std_logic_vector(7 downto 0) 
        );
    end component;

    component S8_Architecture
        port (
            clock: in std_logic;
            inport_0, inport_1: in std_logic_vector(7 downto 0);
            outport_0, outport_1: out std_logic_vector(7 downto 0);
		    internal_data_bus: inout std_logic_vector(7 downto 0);
            ram_addr_bus: out std_logic_vector(15 downto 0);
            IR_data: out std_logic_vector(7 downto 0);
            ALU_control: in std_logic_vector(3 downto 0);
            ALU_flag_control: in std_logic_vector(7 downto 0);
            -- (3) = Z, (2) = S, (1) = V, (0) = C
            ALU_flags: out std_logic_vector(3 downto 0);
            -- (3) = increment, (2) = tristate enable, (1) = load, (0) = clear.
            A_control, D_control, IR_control, Temp_1_control, Temp_2_control, Temp_3_control, Temp_4_control, Temp_5_control: in std_logic_vector(3 downto 0); 
            -- (7) = upper increment (6) = lower increment (5) = upper tristate enable (4) = lower tristate enable, 
            -- (3) = upper load, (2) = upper clear, (1) lower load, (0) lower clear.
            PC_control, X_control, AR_control, SP_control: in std_logic_vector(7 downto 0)        
        );
    end component;

    component Small8_ram
        port (
            address: in std_logic_vector(7 downto 0);
            clock: in std_logic;
            data: in  std_logic_vector(7 downto 0);	  
            wren: in std_logic;	  
            q: out std_logic_vector(7 downto 0)
        );
    end component;

    component tri_state_buffer
        generic (width : positive := 8);
        port (
            data_in : in std_logic_vector((width - 1) downto 0) := (others => '0') ;
            data_out : out std_logic_vector((width - 1) downto 0) := (others => '0') ;
            out_enable: in std_logic := '0'
        );
    end component;

begin

    S8_Controller_inst: S8_Controller
    port map (
        clock => clock,
        reset => reset,
        ALU_flags => ALU_flags_sig,
        ALU_flag_control => ALU_flag_control_sig,
        ALU_control => ALU_control_sig,
        IR_data => IR_data_sig,
        Ram_control => Ram_control_sig,
        ram_out_bus_control => ram_out_bus_control_sig,
        A_control => A_control_sig,
        D_control => D_control_sig,
        IR_control => IR_control_sig,
        Temp_1_control => Temp_1_control_sig,
        Temp_2_control => Temp_2_control_sig,
        Temp_3_control => Temp_3_control_sig,
        Temp_4_control => Temp_4_control_sig,
        Temp_5_control => Temp_5_control_sig,
        PC_control => PC_control_sig,
        X_control => X_control_sig,
        AR_control => AR_control_sig,
        SP_control => SP_control_sig
    );

    S8_Architecture_inst: S8_Architecture
    port map (
        clock => clock,
        inport_0 => inport_0,
        inport_1 => inport_1,
        outport_0 => outport_0,
        outport_1 => outport_1,
	    internal_data_bus => internal_data_bus_sig,
        ram_addr_bus => ram_addr_bus_sig,
        IR_data => IR_data_sig,
        ALU_control => ALU_control_sig,
        ALU_flags => ALU_flags_sig,
        ALU_flag_control => ALU_flag_control_sig,
        A_control => A_control_sig,
        D_control => D_control_sig,
        IR_control => IR_control_sig,
        Temp_1_control => Temp_1_control_sig,
        Temp_2_control => Temp_2_control_sig,
        Temp_3_control => Temp_3_control_sig,
        Temp_4_control => Temp_4_control_sig,
        Temp_5_control => Temp_5_control_sig,
        PC_control => PC_control_sig,
        X_control => X_control_sig,
        AR_control => AR_control_sig,
        SP_control => SP_control_sig
    );

    Small8_ram_inst: Small8_ram
    port map (
        address => ram_addr_bus_sig(7 downto 0),
        clock => clock,
        data => internal_data_bus_sig,
        wren => ram_control_sig,
        q => ram_tri_state_sig
    );

    tri_state_inst: tri_state_buffer
    generic map (width => 8)
    port map (
        data_in => ram_tri_state_sig,
        data_out => internal_data_bus_sig,
        out_enable => ram_out_bus_control_sig
    );

end behavior;







