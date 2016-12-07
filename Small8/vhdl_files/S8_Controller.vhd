library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity S8_Controller is
    port (
        clock, reset: in std_logic;
        -- (3) = Z, (2) = S, (1) = V, (0) = C
        ALU_flags:  in std_logic_vector(3 downto 0) := (others => '0');
        ALU_control: out std_logic_vector(3 downto 0) := (others => '0');
        ALU_flag_control: out std_logic_vector(7 downto 0) := (others => '0');
        IR_data: in std_logic_vector(7 downto 0) := (others => '0');
        -- '1' = write to, '0' = read from
        Ram_control: out std_logic := '0';
        Ram_out_bus_control: out std_logic := '0';
        -- (3) = increment, (2) = tristate enable, (1) = load, (0) = clear.
        A_control, D_control, IR_control, Temp_1_control, Temp_2_control, Temp_3_control, Temp_4_control, Temp_5_control: out std_logic_vector(3 downto 0) := (others => '0'); 
        out_reg_0_control, out_reg_1_control, in_reg_0_control, in_reg_1_control: out std_logic_vector(3 downto 0) := (others => '0'); 
        in_or_out_port_0_targeted: in std_logic := '0';
        in_or_out_port_1_targeted: in std_logic := '0';
        -- (7) = upper increment (6) = lower increment (5) = upper tristate enable (4) = lower tristate enable, 
        -- (3) = upper load, (2) = upper clear, (1) lower load, (0) lower clear.
        PC_control, X_control, AR_control, SP_control: out std_logic_vector(7 downto 0) := (others => '0')
    );
end S8_Controller;

architecture behavior of S8_Controller is 

    -- Up to 128 states. 
    constant start: std_logic_vector(6 downto 0) := std_logic_vector(to_unsigned(0, 7));
    constant fetch_opcode: std_logic_vector(6 downto 0) := std_logic_vector(to_unsigned(1, 7));
    constant fetch_opcode_2: std_logic_vector(6 downto 0) := std_logic_vector(to_unsigned(2, 7));
    constant fetch_opcode_3: std_logic_vector(6 downto 0) := std_logic_vector(to_unsigned(3, 7));
    constant fetch_opcode_4: std_logic_vector(6 downto 0) := std_logic_vector(to_unsigned(4, 7));

    -- Store the value pointed to by the two bytes following the LDAA opcode into A.
    constant LDAA: std_logic_vector(6 downto 0) := std_logic_vector(to_unsigned(5, 7));
    constant LDAA_2: std_logic_vector(6 downto 0) := std_logic_vector(to_unsigned(6, 7));
    constant LDAA_3: std_logic_vector(6 downto 0) := std_logic_vector(to_unsigned(7, 7));
    constant LDAA_3_1: std_logic_vector(6 downto 0) := std_logic_vector(to_unsigned(8, 7));
    constant LDAA_4: std_logic_vector(6 downto 0) := std_logic_vector(to_unsigned(9, 7));
    constant LDAA_5: std_logic_vector(6 downto 0) := std_logic_vector(to_unsigned(10, 7));
    constant LDAA_5_1: std_logic_vector(6 downto 0) := std_logic_vector(to_unsigned(11, 7));
    constant LDAA_6: std_logic_vector(6 downto 0) := std_logic_vector(to_unsigned(12, 7));
    constant LDAA_7: std_logic_vector(6 downto 0) := std_logic_vector(to_unsigned(13, 7));
    constant LDAA_8: std_logic_vector(6 downto 0) := std_logic_vector(to_unsigned(14, 7));
    constant LDAA_8_1: std_logic_vector(6 downto 0) := std_logic_vector(to_unsigned(15, 7));
    constant LDAA_9: std_logic_vector(6 downto 0) := std_logic_vector(to_unsigned(16, 7));

    -- Store A into D.
    constant STAR: std_logic_vector(6 downto 0) := std_logic_vector(to_unsigned(17, 7));

    -- Bitwise AND A and D and store the output in A.
    -- Set the Z and S flags during this operation. 
    constant ANDR: std_logic_vector(6 downto 0) := std_logic_vector(to_unsigned(18, 7));
    constant ANDR_2: std_logic_vector(6 downto 0) := std_logic_vector(to_unsigned(19, 7));
    constant ANDR_3: std_logic_vector(6 downto 0) := std_logic_vector(to_unsigned(20, 7));
    constant ANDR_4: std_logic_vector(6 downto 0) := std_logic_vector(to_unsigned(21, 7));

    -- If the Z flag is '1', load the next two bytes of memory into PC. 
    -- Otherwise, continue PC after skipping the two address bytes. 
    constant BEQA: std_logic_vector(6 downto 0) := std_logic_vector(to_unsigned(22, 7));
    constant BEQA_2: std_logic_vector(6 downto 0) := std_logic_vector(to_unsigned(23, 7));
    constant BEQA_2_1: std_logic_vector(6 downto 0) := std_logic_vector(to_unsigned(24, 7));
    constant BEQA_3: std_logic_vector(6 downto 0) := std_logic_vector(to_unsigned(25, 7));
    constant BEQA_4: std_logic_vector(6 downto 0) := std_logic_vector(to_unsigned(26, 7));
    constant BEQA_5: std_logic_vector(6 downto 0) := std_logic_vector(to_unsigned(27, 7));
    constant BEQA_5_1: std_logic_vector(6 downto 0) := std_logic_vector(to_unsigned(28, 7));
    constant BEQA_6: std_logic_vector(6 downto 0) := std_logic_vector(to_unsigned(29, 7));
    constant BEQA_7: std_logic_vector(6 downto 0) := std_logic_vector(to_unsigned(30, 7));
    constant BEQA_8: std_logic_vector(6 downto 0) := std_logic_vector(to_unsigned(31, 7));

    -- A + D + C_flag -> A
    constant ADCR: std_logic_vector(6 downto 0) := std_logic_vector(to_unsigned(32, 7));
    constant ADCR_2: std_logic_vector(6 downto 0) := std_logic_vector(to_unsigned(33, 7));
    constant ADCR_3: std_logic_vector(6 downto 0) := std_logic_vector(to_unsigned(34, 7));
    constant ADCR_4: std_logic_vector(6 downto 0) := std_logic_vector(to_unsigned(35, 7));

    -- Store the value in A inside the memory address in the two bytes following the STAA Opcode. 
    constant STAA: std_logic_vector(6 downto 0) := std_logic_vector(to_unsigned(36, 7));
    constant STAA_2: std_logic_vector(6 downto 0) := std_logic_vector(to_unsigned(37, 7));
    constant STAA_3: std_logic_vector(6 downto 0) := std_logic_vector(to_unsigned(38, 7));
    constant STAA_3_1: std_logic_vector(6 downto 0) := std_logic_vector(to_unsigned(39, 7));
    constant STAA_4: std_logic_vector(6 downto 0) := std_logic_vector(to_unsigned(40, 7));
    constant STAA_5: std_logic_vector(6 downto 0) := std_logic_vector(to_unsigned(41, 7));
    constant STAA_5_1: std_logic_vector(6 downto 0) := std_logic_vector(to_unsigned(42, 7));
    constant STAA_6: std_logic_vector(6 downto 0) := std_logic_vector(to_unsigned(43, 7));
    constant STAA_7: std_logic_vector(6 downto 0) := std_logic_vector(to_unsigned(44, 7));
    constant STAA_8: std_logic_vector(6 downto 0) := std_logic_vector(to_unsigned(45, 7));
    constant STAA_8_1: std_logic_vector(6 downto 0) := std_logic_vector(to_unsigned(46, 7));
    constant STAA_9: std_logic_vector(6 downto 0) := std_logic_vector(to_unsigned(47, 7));

    constant fetch_opcode_S: std_logic_vector(6 downto 0) := std_logic_vector(to_unsigned(48, 7));
    constant fetch_opcode_S_2: std_logic_vector(6 downto 0) := std_logic_vector(to_unsigned(49, 7));
    constant fetch_opcode_S_3: std_logic_vector(6 downto 0) := std_logic_vector(to_unsigned(50, 7));
    constant fetch_opcode_S_4: std_logic_vector(6 downto 0) := std_logic_vector(to_unsigned(51, 7));

    constant CLRC: std_logic_vector(6 downto 0) := std_logic_vector(to_unsigned(52, 7));

    constant BCAA: std_logic_vector(6 downto 0) := std_logic_vector(to_unsigned(53, 7));
    constant BCAA_2: std_logic_vector(6 downto 0) := std_logic_vector(to_unsigned(54, 7));
    constant BCAA_2_1: std_logic_vector(6 downto 0) := std_logic_vector(to_unsigned(55, 7));
    constant BCAA_3: std_logic_vector(6 downto 0) := std_logic_vector(to_unsigned(56, 7));
    constant BCAA_4: std_logic_vector(6 downto 0) := std_logic_vector(to_unsigned(57, 7));
    constant BCAA_5: std_logic_vector(6 downto 0) := std_logic_vector(to_unsigned(58, 7));
    constant BCAA_5_1: std_logic_vector(6 downto 0) := std_logic_vector(to_unsigned(59, 7));
    constant BCAA_6: std_logic_vector(6 downto 0) := std_logic_vector(to_unsigned(60, 7));
    constant BCAA_7: std_logic_vector(6 downto 0) := std_logic_vector(to_unsigned(61, 7));
    constant BCAA_8: std_logic_vector(6 downto 0) := std_logic_vector(to_unsigned(62, 7));

    constant decode_opcode: std_logic_vector(6 downto 0) := std_logic_vector(to_unsigned(63, 7));

    constant LDAI: std_logic_vector(6 downto 0) := std_logic_vector(to_unsigned(64, 7));
    constant LDAI_2: std_logic_vector(6 downto 0) := std_logic_vector(to_unsigned(65, 7));
    constant LDAI_2_1: std_logic_vector(6 downto 0) := std_logic_vector(to_unsigned(66, 7));
    constant LDAI_3: std_logic_vector(6 downto 0) := std_logic_vector(to_unsigned(67, 7));

    constant RORC: std_logic_vector(6 downto 0) := std_logic_vector(to_unsigned(68, 7));
    constant RORC_2: std_logic_vector(6 downto 0) := std_logic_vector(to_unsigned(69, 7));
    constant RORC_3: std_logic_vector(6 downto 0) := std_logic_vector(to_unsigned(70, 7));

    signal curr_state, next_state: std_logic_vector(6 downto 0) := std_logic_vector(to_unsigned(0, 7));

begin

    -- Tranistion to next_state on the active clock edge.
    process begin
        wait until (clock'event and clock='1');
            if (reset = '1') then
                curr_state <= start;
            else 
                curr_state <= next_state;
            end if;
    end process;

    -- Do the actual work for states.
    process(curr_state, IR_data) begin

        -- Default values for all signals.
        ALU_control <= (others => '0');
        ALU_flag_control <= (others => '0');
        A_control <= (others => '0'); 
        D_control <= (others => '0'); 
        IR_control <= (others => '0');
        PC_control <= (others => '0'); 
        X_control <= (others => '0'); 
        AR_control <= (others => '0'); 
        SP_control <= (others => '0'); 
        Temp_1_control <= (others => '0'); 
        Temp_2_control <= (others => '0');
        Temp_3_control <= (others => '0'); 
        Temp_4_control <= (others => '0'); 
        Temp_5_control <= (others => '0'); 
        out_reg_0_control <= (others => '0');
        out_reg_1_control <= (others => '0');
        in_reg_0_control <= (others => '0');
        in_reg_1_control <= (others => '0');
        Ram_out_bus_control <= '0'; 
        Ram_control <= '0';
        next_state <= curr_state;

        -- Clear all registers and restart all counters.
        if (curr_state = start) then  
            A_control(0) <= '1'; D_control(0) <= '1'; IR_control(0) <= '1';
            Temp_1_control(0) <= '1'; Temp_2_control(0) <= '1'; Temp_3_control(0) <= '1';
            Temp_4_control(0) <= '1'; Temp_5_control(0) <= '1'; out_reg_0_control(0) <= '1';
            out_reg_1_control(0) <= '1'; in_reg_0_control(0) <= '1'; in_reg_1_control(0) <= '1';
            PC_control(0) <= '1'; X_control(0) <= '1'; AR_control(0) <= '1'; SP_control(0) <= '1';
            PC_control(2) <= '1'; X_control(2) <= '1'; AR_control(2) <= '1'; SP_control(2) <= '1';
            next_state <= fetch_opcode;

        -- Load IR with the current PC opcode. 
        elsif (curr_state = fetch_opcode) then -- Load lower PC into AR.
            PC_control(4) <= '1'; -- lower tristate enable.
            AR_control(1) <= '1'; -- lower address load.
            next_state <= fetch_opcode_2;
        elsif (curr_state = fetch_opcode_2) then -- Load upper PC into AR.
            PC_control(5) <= '1'; -- Upper tristate enable
            AR_control(3) <= '1'; -- Upper address load
            next_state <= fetch_opcode_3;
        elsif (curr_state = fetch_opcode_3) then -- The value at the current PC is loaded into IR.
            -- Allow address to register
            next_state <= fetch_opcode_4;
        elsif (curr_state = fetch_opcode_4) then 
            Ram_out_bus_control <= '1'; -- Drive bus from mem
            IR_control(1) <= '1'; -- Register load
            PC_control(6) <= '1';
            next_state <= decode_opcode;

        elsif (curr_state = decode_opcode) then 
            case IR_data is 
                -- Test Case A.
                when "00000001" => next_state <= ADCR;
                when "00100001" => next_state <= ANDR;
                when "10001000" => next_state <= LDAA;
                when "10110010" => next_state <= BEQA;
                when "11110001" => next_state <= STAR;
                when "11110110" => next_state <= STAA;
                when "11111001" => next_state <= CLRC;
                when "10110000" => next_state <= BCAA;
                -- Test Case B.
                when "10000100" => next_state <= LDAI;
                when "01100010" => next_state <= RORC;
                when others => next_state <= curr_state;
            end case;

        elsif (curr_state = RORC) then 
            Temp_1_control(1) <= '1';
            A_control(2) <= '1';
            next_state <= RORC_2;
        elsif (curr_state = RORC_2) then 
            ALU_flag_control(7) <= '1';
            ALU_flag_control(5) <= '1';
            ALU_flag_control(1) <= '1';
            ALU_control <= "1011";
            Temp_3_control(1) <= '1';
            next_state <= RORC_3;
        elsif (curr_state = RORC_3) then 
            Temp_3_control(2) <= '1';
            A_control(1) <= '1';
            next_state <= fetch_opcode;
            
        -- Single register: 
        --      (3) = increment, (2) = tristate enable, (1) = load, (0) = clear.
        -- Dual Register: 
        --      (7) = upper increment (6) = lower increment (5) = upper tristate enable (4) = lower tristate enable, 
        --      (3) = upper load, (2) = upper clear, (1) lower load, (0) lower clear.
        elsif (curr_state = LDAI) then 
            PC_control(4) <= '1';
            AR_control(1) <= '1';
            next_state <= LDAI_2;
        elsif (curr_state = LDAI_2) then 
            PC_control(5) <= '1';
            AR_control(3) <= '1';
            next_state <= LDAI_2_1;
        elsif (curr_state = LDAI_2_1) then 
            next_state <= LDAI_3;
        elsif (curr_state = LDAI_3) then 
            Ram_out_bus_control <= '1';
            A_control(1) <= '1';
            PC_control(6) <= '1';
            next_state <= fetch_opcode;

        elsif (curr_state = BCAA) then 
            if (ALU_flags(0) = '0') then 
                PC_control(4) <= '1';
                AR_control(1) <= '1';
            else 
                PC_control(6) <= '1';
            end if;
            next_state <= BCAA_2;
        elsif (curr_state = BCAA_2) then 
            if (ALU_flags(0) = '0') then 
                PC_control(5) <= '1';
                AR_control(3) <= '1';
                next_state <= BCAA_2_1;
            else 
                PC_control(6) <= '1';
                next_state <= fetch_opcode;
            end if;
        elsif (curr_state = BCAA_2_1) then
            next_state <= BCAA_3;
        elsif (curr_state = BCAA_3) then
            Ram_out_bus_control <= '1';
            Temp_4_control(1) <= '1';
            PC_control(6) <= '1';
            next_state <= BCAA_4;
        elsif (curr_state = BCAA_4) then 
            PC_control(4) <= '1';
            AR_control(1) <= '1';
            next_state <= BCAA_5;
        elsif (curr_state = BCAA_5) then 
            PC_control(5) <= '1';
            AR_control(3) <= '1';
            next_state <= BCAA_5_1;
        elsif (curr_state = BCAA_5_1) then 
            next_state <= BCAA_6;
        elsif (curr_state = BCAA_6) then 
            Ram_out_bus_control <= '1';
            Temp_5_control(1) <= '1';
            PC_control(6) <= '1';
            next_state <= BCAA_7;
        elsif (curr_state = BCAA_7) then 
            PC_control(1) <= '1';
            Temp_4_control(2) <= '1';
            next_state <= BCAA_8;
        elsif (curr_state = BCAA_8) then 
            PC_control(3) <= '1';
            Temp_5_control(1) <= '1';
            next_state <= fetch_opcode;

        elsif (curr_state = CLRC) then 
            ALU_flag_control(0) <= '1';
            next_state <= fetch_opcode; 

        elsif (curr_state = STAR) then
            A_control(2) <= '1'; -- drive bus           
            D_control(1) <= '1'; -- read from bus
            next_state <= fetch_opcode;

        -- Single register: 
        --      (3) = increment, (2) = tristate enable, (1) = load, (0) = clear.
        -- Dual Register: 
        --      (7) = upper increment (6) = lower increment (5) = upper tristate enable (4) = lower tristate enable, 
        --      (3) = upper load, (2) = upper clear, (1) lower load, (0) lower clear.
        elsif (curr_state = LDAA) then
            PC_control(4) <= '1'; -- drive bus
            AR_control(1) <= '1'; -- read from bus        
            next_state <= LDAA_2;
        elsif (curr_state = LDAA_2) then
            PC_control(5) <= '1'; -- drive bus
            AR_control(3) <= '1'; -- read from bus
            next_state <= LDAA_3_1;
        elsif (curr_state = LDAA_3_1) then -- Wait for address to register.
            next_state <= LDAA_3;
        elsif (curr_state = LDAA_3) then 
            Ram_out_bus_control <= '1'; -- drive bus with mem
            Temp_4_control(1) <= '1'; -- read from bus
            PC_control(6) <= '1'; -- inc lower
            next_state <= LDAA_4;
        elsif (curr_state = LDAA_4) then 
            PC_control(4) <= '1'; -- drive bus
            AR_control(1) <= '1'; -- read from bus        
            next_state <= LDAA_5;
        elsif (curr_state = LDAA_5) then 
            PC_control(5) <= '1'; -- drive bus
            AR_control(3) <= '1'; -- read from bus
            next_state <= LDAA_5_1;
        elsif (curr_state = LDAA_5_1) then
            -- Wait for address to register.
            next_state <= LDAA_6; 
        elsif (curr_state = LDAA_6) then
            Ram_out_bus_control <= '1'; -- drive bus with mem
            Temp_5_control(1) <= '1'; -- read from bus
            next_state <= LDAA_7;
        elsif (curr_state = LDAA_7) then  -- At this point, Temp_4 contains value at mem(PC-1) and Temp_5 has mem(PC).
            Temp_4_control(2) <= '1'; -- drive bus
            AR_control(1) <= '1'; -- read from bus        
            next_state <= LDAA_8;
        elsif (curr_state = LDAA_8) then 
            Temp_5_control(2) <= '1'; -- drive bus
            AR_control(3) <= '1'; -- read from bus        
            PC_control(6) <= '1'; -- inc lower
            next_state <= LDAA_8_1;          
        elsif (curr_state = LDAA_8_1) then 
            -- Wait for address to register. 
            next_state <= LDAA_9;
        elsif (curr_state = LDAA_9) then
            if (in_or_out_port_0_targeted = '1') then 
                in_reg_0_control(2) <= '1';
            elsif (in_or_out_port_1_targeted = '1') then 
                in_reg_1_control(2) <= '1';
            else 
                Ram_out_bus_control <= '1'; -- drive bus with mem
            end if;
            A_control(1) <= '1'; -- read from bus
            next_state <= fetch_opcode;

        -- Single register: 
        --      (3) = increment, (2) = tristate enable, (1) = load, (0) = clear.
        -- Dual Register: 
        --      (7) = upper increment (6) = lower increment (5) = upper tristate enable (4) = lower tristate enable, 
        --      (3) = upper load, (2) = upper clear, (1) lower load, (0) lower clear.
        elsif (curr_state = STAA) then
            PC_control(4) <= '1'; -- drive bus
            AR_control(1) <= '1'; -- read from bus        
            next_state <= STAA_2;
        elsif (curr_state = STAA_2) then
            PC_control(5) <= '1'; -- drive bus
            AR_control(3) <= '1'; -- read from bus
            next_state <= STAA_3_1;
        elsif (curr_state = STAA_3_1) then -- Wait for address to register.
            next_state <= STAA_3;
        elsif (curr_state = STAA_3) then 
            Ram_out_bus_control <= '1'; -- drive bus with mem
            Temp_4_control(1) <= '1'; -- read from bus
            PC_control(6) <= '1'; -- inc lower
            next_state <= STAA_4;
        elsif (curr_state = STAA_4) then 
            PC_control(4) <= '1'; -- drive bus
            AR_control(1) <= '1'; -- read from bus        
            next_state <= STAA_5;
        elsif (curr_state = STAA_5) then 
            PC_control(5) <= '1'; -- drive bus
            AR_control(3) <= '1'; -- read from bus
            next_state <= STAA_5_1;
        elsif (curr_state = STAA_5_1) then
            -- Wait for address to register.
            next_state <= STAA_6; 
        elsif (curr_state = STAA_6) then
            Ram_out_bus_control <= '1'; -- drive bus with mem
            Temp_5_control(1) <= '1'; -- read from bus
            next_state <= STAA_7;
        elsif (curr_state = STAA_7) then 
            Temp_4_control(2) <= '1'; -- drive bus
            AR_control(1) <= '1'; -- read from bus        
            next_state <= STAA_8;
        elsif (curr_state = STAA_8) then 
            Temp_5_control(2) <= '1'; -- drive bus
            AR_control(3) <= '1'; -- read from bus        
            PC_control(6) <= '1'; -- inc lower
            next_state <= STAA_8_1;          
        elsif (curr_state = STAA_8_1) then 
            -- Wait for address to register. 
            next_state <= STAA_9;
        elsif (curr_state = STAA_9) then
            if (in_or_out_port_0_targeted = '1') then 
                out_reg_0_control(1) <= '1';
            elsif (in_or_out_port_1_targeted = '1') then 
                out_reg_1_control(1) <= '1';
            else
                Ram_control <= '1'; -- write bus to ram at address AR
            end if;
            A_control(2) <= '1'; -- write to bus
            next_state <= fetch_opcode;

        -- -- Single register: 
        -- --      (3) = increment, (2) = tristate enable, (1) = load, (0) = clear.
        -- -- Dual Register: 
        -- --      (7) = upper increment (6) = lower increment (5) = upper tristate enable (4) = lower tristate enable, 
        -- --      (3) = upper load, (2) = upper clear, (1) lower load, (0) lower clear.
        elsif (curr_state = ANDR) then
            A_control(2) <= '1'; -- drive bus
            Temp_1_control(1) <= '1'; -- read from bus
            next_state <= ANDR_2;
        elsif (curr_state = ANDR_2) then
            D_control(2) <= '1'; -- drive bus
            Temp_2_control(1) <= '1'; -- read from bus
            next_state <= ANDR_3;
        elsif (curr_state = ANDR_3) then
            ALU_control <= "0100"; -- AND temp 1 and temp 2
            ALU_flag_control(7) <= '1'; -- set Z flag
            ALU_flag_control(5) <= '1'; -- set S flag
            Temp_3_control(1) <= '1'; -- read from alu out bus
            next_state <= ANDR_4;
        elsif (curr_state = ANDR_4) then 
            Temp_3_control(2) <= '1'; -- drive bus
            A_control(1) <= '1'; -- read from bus
            next_state <= fetch_opcode;

        -- Single register: 
        --      (3) = increment, (2) = tristate enable, (1) = load, (0) = clear.
        -- Dual Register: 
        --      (7) = upper increment (6) = lower increment (5) = upper tristate enable (4) = lower tristate enable, 
        --      (3) = upper load, (2) = upper clear, (1) lower load, (0) lower clear.
        -- A + D + Carry_in -> A
        elsif (curr_state = ADCR) then
            A_control(2) <= '1'; -- drive bus
            Temp_1_control(1) <= '1'; -- read from bus
            next_state <= ADCR_2;
        elsif (curr_state = ADCR_2) then
            D_control(2) <= '1'; -- drive bus
            Temp_2_control(1) <= '1'; -- read from bus
            next_state <= ADCR_3;
        elsif (curr_state = ADCR_3) then
            Temp_3_control(1) <= '1'; -- read from alu bus
            ALU_flag_control(7) <= '1'; -- Z flag load
            ALU_flag_control(5) <= '1'; -- S flag load 
            ALU_flag_control(3) <= '1'; -- V flag load 
            ALU_flag_control(1) <= '1'; -- C flag load 
            ALU_control <= "0101";
            next_state <= ADCR_4;
        elsif (curr_state = ADCR_4) then
            Temp_3_control(2) <= '1'; -- drive bus
            A_control(1) <= '1'; -- read from bus
            next_state <= fetch_opcode;

        -- -- Single register: 
        -- --      (3) = increment, (2) = tristate enable, (1) = load, (0) = clear.
        -- -- Dual Register: 
        -- --      (7) = upper increment (6) = lower increment (5) = upper tristate enable (4) = lower tristate enable, 
        -- --      (3) = upper load, (2) = upper clear, (1) lower load, (0) lower clear.
        elsif (curr_state = BEQA) then
            if (ALU_flags(3) = '1') then 
                PC_control(4) <= '1'; -- drive bus from lower
                AR_control(1) <= '1'; -- read lower from bus
                next_state <= BEQA_2; 
            else
                PC_control(6) <= '1';
                next_state <= BEQA_2;
            end if;
        elsif (curr_state = BEQA_2) then 
            if (ALU_flags(3) = '1') then 
                PC_control(5) <= '1'; -- drive bus from upper
                AR_control(3) <= '1'; -- read from lower
                next_state <= BEQA_2_1;
            else 
                PC_control(6) <= '1';
                next_state <= fetch_opcode;  -- if not branching, we're done
            end if;
        elsif (curr_state = BEQA_2_1) then 
            next_state <= BEQA_3;
        elsif (curr_state = BEQA_3) then
            PC_control(6) <= '1';
            Ram_out_bus_control <= '1'; -- drive bus with new PC
            Temp_4_control(1) <= '1'; -- read lower from bus
            next_state <= BEQA_4;
        elsif (curr_state = BEQA_4) then 
            PC_control(4) <= '1'; -- drive bus from lower
            AR_control(1) <= '1'; -- read lower from bus
            next_state <= BEQA_5; 
        elsif (curr_state = BEQA_5) then 
            PC_control(5) <= '1'; -- drive bus from lower
            AR_control(3) <= '1'; -- read lower from bus
            next_state <= BEQA_5_1;
        elsif (curr_state = BEQA_5_1) then 
            next_state <= BEQA_6;
        elsif (curr_state = BEQA_6) then 
            Ram_out_bus_control <= '1';
            Temp_5_control(1) <= '1';
            next_state <= BEQA_7;
        elsif (curr_state = BEQA_7) then 
            Temp_4_control(2) <= '1';
            PC_control(1) <= '1';
            next_state <= BEQA_8;
        elsif (curr_state = BEQA_8) then 
            Temp_5_control(2) <= '1';
            PC_control(3) <= '1';
            next_state <= fetch_opcode; 
        end if;

    end process;

end behavior;















