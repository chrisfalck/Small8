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
        -- (7) = upper increment (6) = lower increment (5) = upper tristate enable (4) = lower tristate enable, 
        -- (3) = upper load, (2) = upper clear, (1) lower load, (0) lower clear.
        PC_control, X_control, AR_control, SP_control: out std_logic_vector(7 downto 0) := (others => '0')
    );
end S8_Controller;

architecture behavior of S8_Controller is 

    -- Up to 64 states. 
    constant start: std_logic_vector(5 downto 0) := std_logic_vector(to_unsigned(0, 6));
    constant fetch_opcode: std_logic_vector(5 downto 0) := std_logic_vector(to_unsigned(1, 6));
    constant fetch_opcode_2: std_logic_vector(5 downto 0) := std_logic_vector(to_unsigned(2, 6));
    constant fetch_opcode_3: std_logic_vector(5 downto 0) := std_logic_vector(to_unsigned(3, 6));
    constant fetch_opcode_4: std_logic_vector(5 downto 0) := std_logic_vector(to_unsigned(4, 6));


    constant decode_opcode: std_logic_vector(5 downto 0) := std_logic_vector(to_unsigned(63, 6));

    -- Store the value pointed to by the two bytes following the LDAA opcode into A.
    constant LDAA: std_logic_vector(5 downto 0) := std_logic_vector(to_unsigned(5, 6));
    constant LDAA_2: std_logic_vector(5 downto 0) := std_logic_vector(to_unsigned(6, 6));
    constant LDAA_3: std_logic_vector(5 downto 0) := std_logic_vector(to_unsigned(7, 6));
    constant LDAA_3_1: std_logic_vector(5 downto 0) := std_logic_vector(to_unsigned(8, 6));
    constant LDAA_4: std_logic_vector(5 downto 0) := std_logic_vector(to_unsigned(9, 6));
    constant LDAA_5: std_logic_vector(5 downto 0) := std_logic_vector(to_unsigned(10, 6));
    constant LDAA_5_1: std_logic_vector(5 downto 0) := std_logic_vector(to_unsigned(11, 6));
    constant LDAA_6: std_logic_vector(5 downto 0) := std_logic_vector(to_unsigned(12, 6));
    constant LDAA_7: std_logic_vector(5 downto 0) := std_logic_vector(to_unsigned(13, 6));
    constant LDAA_8: std_logic_vector(5 downto 0) := std_logic_vector(to_unsigned(14, 6));
    constant LDAA_8_1: std_logic_vector(5 downto 0) := std_logic_vector(to_unsigned(15, 6));
    constant LDAA_9: std_logic_vector(5 downto 0) := std_logic_vector(to_unsigned(16, 6));

    -- Store A into D.
    constant STAR: std_logic_vector(5 downto 0) := std_logic_vector(to_unsigned(17, 6));

    -- Bitwise AND A and D and store the output in A.
    -- Set the Z and S flags during this operation. 
    constant ANDR: std_logic_vector(5 downto 0) := std_logic_vector(to_unsigned(18, 6));
    constant ANDR_2: std_logic_vector(5 downto 0) := std_logic_vector(to_unsigned(19, 6));
    constant ANDR_3: std_logic_vector(5 downto 0) := std_logic_vector(to_unsigned(20, 6));
    constant ANDR_4: std_logic_vector(5 downto 0) := std_logic_vector(to_unsigned(21, 6));

    -- If the Z flag is '1', load the next two bytes of memory into PC. 
    -- Otherwise, continue PC after skipping the two address bytes. 
    constant BEQA: std_logic_vector(5 downto 0) := std_logic_vector(to_unsigned(22, 6));
    constant BEQA_2: std_logic_vector(5 downto 0) := std_logic_vector(to_unsigned(23, 6));
    constant BEQA_2_1: std_logic_vector(5 downto 0) := std_logic_vector(to_unsigned(24, 6));
    constant BEQA_3: std_logic_vector(5 downto 0) := std_logic_vector(to_unsigned(25, 6));
    constant BEQA_4: std_logic_vector(5 downto 0) := std_logic_vector(to_unsigned(26, 6));
    constant BEQA_5: std_logic_vector(5 downto 0) := std_logic_vector(to_unsigned(27, 6));
    constant BEQA_5_1: std_logic_vector(5 downto 0) := std_logic_vector(to_unsigned(28, 6));
    constant BEQA_6: std_logic_vector(5 downto 0) := std_logic_vector(to_unsigned(29, 6));
    constant BEQA_7: std_logic_vector(5 downto 0) := std_logic_vector(to_unsigned(30, 6));
    constant BEQA_8: std_logic_vector(5 downto 0) := std_logic_vector(to_unsigned(31, 6));

    -- A + D + C_flag -> A
    constant ADCR: std_logic_vector(5 downto 0) := std_logic_vector(to_unsigned(32, 6));
    constant ADCR_2: std_logic_vector(5 downto 0) := std_logic_vector(to_unsigned(33, 6));
    constant ADCR_3: std_logic_vector(5 downto 0) := std_logic_vector(to_unsigned(34, 6));
    constant ADCR_4: std_logic_vector(5 downto 0) := std_logic_vector(to_unsigned(35, 6));

    -- constant STAA: std_logic_vector(5 downto 0) := std_logic_vector(to_unsigned(17, 6));
    -- constant STAA_2: std_logic_vector(5 downto 0) := std_logic_vector(to_unsigned(9, 6));
    -- constant STAA_3: std_logic_vector(5 downto 0) := std_logic_vector(to_unsigned(10, 6));

    signal curr_state, next_state: std_logic_vector(5 downto 0) := std_logic_vector(to_unsigned(0, 6));

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
        Ram_out_bus_control <= '0'; 
        Ram_control <= '0';
        next_state <= curr_state;

        -- Clear all registers and restart all counters.
        if (curr_state = start) then  
            A_control(0) <= '1'; D_control(0) <= '1'; IR_control(0) <= '1';
            Temp_1_control(0) <= '1'; Temp_2_control(0) <= '1'; Temp_3_control(0) <= '1';
            Temp_4_control(0) <= '1'; Temp_5_control(0) <= '1';
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
            if (IR_data = "10001000") then
                next_state <= LDAA;
            -- elsif (IR_data = "11110110") then
                -- next_state <= STAA;
            elsif (IR_data = "11110001") then
                next_state <= STAR;
            elsif (IR_data = "00100001") then
                next_state <= ANDR;
            elsif (IR_data = "00000001") then
                next_state <= ADCR;
            elsif (IR_data = "10110010") then
                next_state <= BEQA;
            else
                next_state <= curr_state;
            end if;

        -- LDAA Starts at state 5
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
        elsif (curr_state <= LDAA_6) then
            Ram_out_bus_control <= '1'; -- drive bus with mem
            Temp_5_control(1) <= '1'; -- read from bus
            next_state <= LDAA_7;
        elsif (curr_state = LDAA_7) then 
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
            Ram_out_bus_control <= '1'; -- drive bus with mem
            A_control(1) <= '1'; -- read from bus
            next_state <= fetch_opcode;

        -- Single register: 
        --      (3) = increment, (2) = tristate enable, (1) = load, (0) = clear.
        -- Dual Register: 
        --      (7) = upper increment (6) = lower increment (5) = upper tristate enable (4) = lower tristate enable, 
        --      (3) = upper load, (2) = upper clear, (1) lower load, (0) lower clear.
        -- elsif (curr_state = STAA) then
        --     PC_control(6) <= '1'; -- inc lower
        --     PC_control(4) <= '1'; -- drive bus from lower
        --     AR_control(1) <= '1'; -- read lower from bus
        --     next_state <= STAA_2;
        -- elsif (curr_state = STAA_2) then
        --     PC_control(6) <= '1'; -- inc lower
        --     PC_control(5) <= '1'; -- drive bus from upper
        --     AR_control(3) <= '1'; -- read upper from bus
        --     next_state <= STAA_3;
        -- elsif (curr_state = STAA_3) then
        --     AR_control(5) <= '1'; -- drive mem from upper
        --     AR_control(4) <= '1'; -- drive mem from lower
        --     Ram_control <= '1'; -- signal to write to ram
        --     A_control(2) <= '1'; -- drive bus
        --     next_state <= fetch_opcode;

        elsif (curr_state = STAR) then
            -- PC_control(6) <= '1'; -- inc lower
            A_control(2) <= '1'; -- drive bus           
            D_control(1) <= '1'; -- read from bus
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
        -- -- Single register: 
        -- --      (3) = increment, (2) = tristate enable, (1) = load, (0) = clear.
        -- -- Dual Register: 
        -- --      (7) = upper increment (6) = lower increment (5) = upper tristate enable (4) = lower tristate enable, 
        -- --      (3) = upper load, (2) = upper clear, (1) lower load, (0) lower clear.
        -- -- A + D + Carry_in -> A
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
        elsif (curr_state <= BEQA_7) then 
            Temp_4_control(2) <= '1';
            PC_control(1) <= '1';
            next_state <= BEQA_8;
        elsif (curr_state <= BEQA_8) then 
            Temp_5_control(2) <= '1';
            PC_control(3) <= '1';
            next_state <= fetch_opcode; 
        end if;

    end process;

end behavior;















