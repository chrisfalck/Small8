library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity S8_Architecture is
    port (
        clock: in std_logic;
        inport_0, inport_1: in std_logic_vector(7 downto 0) := (others => '0');
        outport_0, outport_1: out std_logic_vector(7 downto 0) := (others => '0');
        ram_addr_bus: out std_logic_vector(15 downto 0) := (others => '0');
        IR_data: out std_logic_vector(7 downto 0) := (others => '0');
        ALU_control: in std_logic_vector(3 downto 0) := (others => '0');
        ALU_flags: out std_logic_vector(3 downto 0) := (others => '0');
        ALU_flag_control: in std_logic_vector(7 downto 0) := (others => '0');
        internal_data_bus: inout std_logic_vector(7 downto 0) := (others => '0');
        -- (3) = increment, (2) = tristate enable, (1) = load, (0) = clear.
        A_control, D_control, IR_control, Temp_1_control, Temp_2_control, Temp_3_control, Temp_4_control, Temp_5_control: in std_logic_vector(3 downto 0) := (others => '0'); 
        -- (7) = upper increment, (6) = lower increment, (5) = upper tristate enable (4) = lower tristate enable, 
        -- (3) = upper load, (2) = upper clear, (1) lower load, (0) lower clear.
        PC_control, X_control, AR_control, SP_control: in std_logic_vector(7 downto 0) := (others => '0')       
    );
end S8_Architecture;

architecture behavior of S8_Architecture is

    component DFF_register
        generic (width : positive := 8);
        port (
            clock, load, clear, out_enable, inc: in std_logic;
            data_in: in std_logic_vector((width - 1) downto 0);
            data_out: buffer std_logic_vector((width - 1) downto 0) 
        );
    end component;

    component alu_ns
        generic(
            width : positive := 16
        );
        port (
            carry_in : in std_logic_vector(0 downto 0);
            input1   : in std_logic_vector(width - 1 downto 0);
            input2   : in std_logic_vector(width - 1 downto 0);
            sel      : in std_logic_vector(3 downto 0);
            output   : out std_logic_vector(width - 1 downto 0);
            overflow : out std_logic
        );
    end component;

    -- Flags
    signal C_flag_data_in_sig, C_flag_data_out_sig: std_logic_vector(0 downto 0) := (others => '0');
    signal V_flag_data_in_sig, V_flag_data_out_sig: std_logic_vector(0 downto 0) := (others => '0');
    signal S_flag_data_in_sig, S_flag_data_out_sig: std_logic_vector(0 downto 0) := (others => '0');
    signal Z_flag_data_in_sig, Z_flag_data_out_sig: std_logic_vector(0 downto 0) := (others => '0');

    signal ALU_overflow_sig: std_logic := '0';
    -- signal ALU_carryin_sig: std_logic_vector(0 downto 0);

    -- 8 bit registers
    signal A_data_out_sig: std_logic_vector(7 downto 0) := (others => '0');
    signal D_data_out_sig: std_logic_vector(7 downto 0) := (others => '0');
    signal ALU_data_out_sig: std_logic_vector(7 downto 0) := (others => '0');

    signal Temp_1_out_sig, Temp_2_out_sig, Temp_3_out_sig, Temp_4_out_sig, Temp_5_out_sig: std_logic_vector(7 downto 0) := (others => '0');

    -- 16 bit registers
    signal PC_lower_data_out_sig: std_logic_vector(7 downto 0) := (others => '0');
    signal PC_upper_data_out_sig: std_logic_vector(7 downto 0) := (others => '0');
    signal X_lower_data_out_sig: std_logic_vector(7 downto 0) := (others => '0');
    signal X_upper_data_out_sig: std_logic_vector(7 downto 0) := (others => '0');
    signal SP_lower_data_out_sig: std_logic_vector(7 downto 0) := (others => '0');
    signal SP_upper_data_out_sig: std_logic_vector(7 downto 0) := (others => '0');
    signal AR_lower_data_out_sig: std_logic_vector(7 downto 0) := (others => '0');
    signal AR_upper_data_out_sig: std_logic_vector(7 downto 0) := (others => '0');

    -- Controlled internally by the ALU.

    -- C_flag: (1) = load, (0) = clear
    signal C_flag_control_sig: std_logic_vector(1 downto 0) := (others => '0');
    -- V_flag: (1) = load, (0) = clear
    signal V_flag_control_sig: std_logic_vector(1 downto 0) := (others => '0');
    -- S_flag: (1) = load, (0) = clear
    signal S_flag_control_sig: std_logic_vector(1 downto 0) := (others => '0');
    -- Z_flag: (1) = load, (0) = clear
    signal Z_flag_control_sig: std_logic_vector(1 downto 0) := (others => '0');

    signal outport_0_sig, outport_1_sig: std_logic_vector(7 downto 0) := (others => '0');
    

begin

    outport_0 <= outport_0_sig;
    outport_1 <= outport_1_sig;

    alu_inst: alu_ns
    generic map(width => 8)   
    port map (
        carry_in => C_flag_data_out_sig,
        input1 => Temp_1_out_sig,
        input2 => Temp_2_out_sig,
        sel    => ALU_control,
        output => ALU_data_out_sig,
        overflow => ALU_overflow_sig
    );

    Temp_register_1: DFF_register
    generic map (width => 8)
    port map (
        clock => clock,
        inc => Temp_1_control(3),
        out_enable => '1',
        load => Temp_1_control(1),
        clear => Temp_1_control(0),
        data_in => internal_data_bus,
        data_out => Temp_1_out_sig
    );

    Temp_register_2: DFF_register
    generic map (width => 8)
    port map (
        clock => clock,
        inc => Temp_2_control(3),
        out_enable => '1',
        load => Temp_2_control(1),
        clear => Temp_2_control(0),
        data_in => internal_data_bus,
        data_out => Temp_2_out_sig
    );

    Temp_register_3: DFF_register
    generic map (width => 8)
    port map (
        clock => clock,
        inc => Temp_3_control(3),
        out_enable => Temp_3_control(2),
        load => Temp_3_control(1),
        clear => Temp_3_control(0),
        data_in => ALU_data_out_sig,
        data_out => Temp_3_out_sig
    );
    internal_data_bus <= Temp_3_out_sig;


    Temp_register_4: DFF_register
    generic map (width => 8)
    port map (
        clock => clock,
        inc => Temp_4_control(3),
        out_enable => Temp_4_control(2),
        load => Temp_4_control(1),
        clear => Temp_4_control(0),
        data_in => internal_data_bus,
        data_out => Temp_4_out_sig
    );
    internal_data_bus <= Temp_4_out_sig;   

    Temp_register_5: DFF_register
    generic map (width => 8)
    port map (
        clock => clock,
        inc => Temp_5_control(3),
        out_enable => Temp_5_control(2),
        load => Temp_5_control(1),
        clear => Temp_5_control(0),
        data_in => internal_data_bus,
        data_out => Temp_5_out_sig
    );
    internal_data_bus <= Temp_5_out_sig;

    Z_flag_inst: DFF_register
    generic map (width => 1)
    port map (
        clock => clock,
        inc => '0',
        out_enable => '1',
        load => ALU_flag_control(7),
        clear => ALU_flag_control(6),
        data_in => Z_flag_data_in_sig,
        data_out => Z_flag_data_out_sig
    );
    ALU_flags(3) <= Z_flag_data_out_sig(0);
    Z_flag_data_in_sig(0) <= '1' when (ALU_data_out_sig = "00000000" and ALU_overflow_sig = '0') else '0';

    S_flag_inst: DFF_register
    generic map (width => 1)
    port map (
        clock => clock,
        inc => '0',
        out_enable => '1',
        load => ALU_flag_control(5),
        clear => ALU_flag_control(4),
        data_in => S_flag_data_in_sig,
        data_out => S_flag_data_out_sig
    );
    ALU_flags(2) <= S_flag_data_out_sig(0);
    S_flag_data_in_sig(0) <= ALU_data_out_sig(7);

    V_flag_inst: DFF_register
    generic map (width => 1)
    port map (
        clock => clock,
        inc => '0',
        out_enable => '1',
        load => ALU_flag_control(3),
        clear => ALU_flag_control(2),
        data_in => V_flag_data_in_sig,
        data_out => V_flag_data_out_sig
    );
    ALU_flags(1) <= V_flag_data_out_sig(0);
    V_flag_data_in_sig(0) <= (ALU_data_out_sig(7) xor ALU_overflow_sig);

    C_flag_inst: DFF_register
    generic map (width => 1)
    port map (
        clock => clock,
        inc => '0',
        out_enable => '1',
        load => ALU_flag_control(1),
        clear => ALU_flag_control(0),
        data_in => C_flag_data_in_sig,
        data_out => C_flag_data_out_sig
    );
    ALU_flags(0) <= C_flag_data_out_sig(0);
    C_flag_data_in_sig(0) <= ALU_overflow_sig;

    IR_inst: DFF_register
    generic map (width => 8)
    port map (
        clock => clock,
        inc => '0',
        out_enable => '1',
        load => IR_control(1),
        clear => IR_control(0),
        data_in => internal_data_bus,
        data_out => IR_data
    );

    D_inst: DFF_register
    generic map (width => 8)
    port map (
        clock => clock,
        inc => D_control(3),
        out_enable => D_control(2),
        load => D_control(1),
        clear => D_control(0),
        data_in => internal_data_bus,
        data_out => D_data_out_sig
    );
    internal_data_bus <= D_data_out_sig;

    A_inst: DFF_register
    generic map (width => 8)
    port map (
        clock => clock,
        inc => A_control(3),
        out_enable => A_control(2),
        load => A_control(1),
        clear => A_control(0),
        data_in => internal_data_bus,
        data_out => A_data_out_sig
    );
    internal_data_bus <= A_data_out_sig;

    AR_lower_inst: DFF_register
    generic map (width => 8)
    port map (
        clock => clock,
        inc => AR_control(6),
        out_enable => '1',
        load => AR_control(1),
        clear => AR_control(0),
        data_in => internal_data_bus,
        data_out => AR_lower_data_out_sig
    );
    ram_addr_bus(7 downto 0) <= AR_lower_data_out_sig;

    AR_upper_inst: DFF_register
    generic map (width => 8)
    port map (
        clock => clock,
        inc => AR_control(7),
        out_enable => '1',
        load => AR_control(3),
        clear => AR_control(2),
        data_in => internal_data_bus,
        data_out => AR_upper_data_out_sig
    );
    ram_addr_bus(15 downto 8) <= AR_upper_data_out_sig;

    SP_lower_inst: DFF_register
    generic map (width => 8)
    port map (
        clock => clock,
        inc => SP_control(6),
        out_enable => SP_control(4),
        load => SP_control(1),
        clear => SP_control(0),
        data_in => internal_data_bus,
        data_out => SP_lower_data_out_sig
    );
    internal_data_bus <= SP_lower_data_out_sig;

    SP_upper_inst: DFF_register
    generic map (width => 8)
    port map (
        clock => clock,
        inc => SP_control(7),
        out_enable => SP_control(5),
        load => SP_control(3),
        clear => SP_control(2),
        data_in => internal_data_bus,
        data_out => SP_upper_data_out_sig
    );
    internal_data_bus <= SP_upper_data_out_sig;

    X_lower_inst: DFF_register
    generic map (width => 8)
    port map (
        clock => clock,
        inc => X_control(6),
        out_enable => X_control(4),
        load => X_control(1),
        clear => X_control(0),
        data_in => internal_data_bus,
        data_out => X_lower_data_out_sig
    );
    internal_data_bus <= X_lower_data_out_sig;

    X_upper_inst: DFF_register
    generic map (width => 8)
    port map (
        clock => clock,
        inc => X_control(7),
        out_enable => X_control(5),
        load => X_control(3),
        clear => X_control(2),
        data_in => internal_data_bus,
        data_out => X_upper_data_out_sig
    );
    internal_data_bus <= X_upper_data_out_sig;

    PC_lower_inst: DFF_register
    generic map (width => 8)
    port map (
        clock => clock,
        inc => PC_control(6),
        out_enable => PC_control(4),
        load => PC_control(1),
        clear => PC_control(0),
        data_in => internal_data_bus,
        data_out => PC_lower_data_out_sig
    );
    internal_data_bus <= PC_lower_data_out_sig;

    PC_upper_inst: DFF_register
    generic map (width => 8)
    port map (
        clock => clock,
        inc => PC_control(7),
        out_enable => PC_control(5),
        load => PC_control(3),
        clear => PC_control(2),
        data_in => internal_data_bus,
        data_out => PC_upper_data_out_sig
    );
    internal_data_bus <= PC_upper_data_out_sig;


end behavior;