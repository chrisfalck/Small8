library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity alu_ns is
  generic(
    width : positive := 16
  );
  port (
    carry_in : in std_logic_vector(0 downto 0) := (others => '0');
    input1   : in std_logic_vector(width - 1 downto 0) := (others => '0');
    input2   : in std_logic_vector(width - 1 downto 0) := (others => '0');
    sel      : in std_logic_vector(3 downto 0) := (others => '0');
    output   : out std_logic_vector(width - 1 downto 0) := (others => '0');
    overflow : out std_logic := '0'
  );
end alu_ns;

architecture behavior of alu_ns is
begin

  process(sel, input1, input2)

    -- Variables must be declared before the begin block.
    variable uns_input1 : unsigned(width - 1 downto 0) := to_unsigned(0, width);
    variable uns_input2 : unsigned(width - 1 downto 0) := to_unsigned(0, width);
    variable uns_operation_output : unsigned(width - 1 downto 0) := to_unsigned(0, width);

    -- We use (width downto 0) rather than width - 1 because we need room for the carry bit.
    variable uns_arithmetic_output : unsigned(width downto 0) := to_unsigned(0, width + 1);

    -- Multiplication outputs may be up to double the bits of the inputs even without overflow.
    variable uns_multiplication_output : unsigned((width + width - 1) downto 0) := to_unsigned(0, width + width);
    variable uns_multiplication_overflow_check : unsigned(width - 1 downto 0) := to_unsigned(0, width);

    variable std_arithmetic_output : std_logic_vector(width downto 0) := (others => '0');
    variable std_overflow_output : std_logic := '0';

  begin
    case sel is
      -- Output NOT(input1). Overflow = '0'.
      when "0000" =>
        output <= not(input1);
        overflow <= '0';

      -- Output input1 NOR input2. Overflow = '0'.
      when "0001" =>
        uns_input1 := unsigned(input1);
        uns_input2 := unsigned(input2);
        uns_operation_output := (uns_input1 nor uns_input2);
        output <= std_logic_vector(uns_operation_output);
        overflow <= '0';

      -- Output input1 XOR input2. Overflow = '0'.
      when "0010" =>
        uns_input1 := unsigned(input1);
        uns_input2 := unsigned(input2);
        uns_operation_output := (uns_input1 xor uns_input2);
        output <= std_logic_vector(uns_operation_output);
        overflow <= '0';

      -- Output input1 OR input2. Overflow = '0'.
      when "0011" =>
        uns_input1 := unsigned(input1);
        uns_input2 := unsigned(input2);
        uns_operation_output := (uns_input1 or uns_input2);
        output <= std_logic_vector(uns_operation_output);
        overflow <= '0';

      -- Output input1 AND input2. Overflow = '0'.
      when "0100" =>
        uns_input1 := unsigned(input1);
        uns_input2 := unsigned(input2);
        uns_operation_output := (uns_input1 and uns_input2);
        output <= std_logic_vector(uns_operation_output);
        overflow <= '0';

      -- Output input1 + input2.
      -- Overflow = '1' if input1 + input2 > max number of output bits. Otherwise '0'.
      when "0101" =>
        uns_input1 := unsigned(input1);
        uns_input2 := unsigned(input2);
        uns_arithmetic_output := (('0' & uns_input1) + uns_input2 + unsigned(carry_in));
        std_arithmetic_output := std_logic_vector(uns_arithmetic_output);
        output <= std_arithmetic_output(width - 1 downto 0);
        overflow <= std_arithmetic_output(width);

      -- Output input1 - input2. Overflow = '0'.
      when "0110" =>
        uns_input1 := unsigned(input1);
        uns_input2 := unsigned(input2);
        uns_arithmetic_output := (('0' & uns_input1) - uns_input2);
        output <= std_logic_vector(uns_arithmetic_output(width - 1 downto 0));
        overflow <= '0';

      -- Output input1 * input2.
      -- Output the lower 8 bits of the 16 bit multiplication output.
      -- Overflow = '1' if input1 * input2 > max number of output bits. Otherwise '0'.
      when "0111" =>
        uns_input1 := unsigned(input1);
        uns_input2 := unsigned(input2);
        uns_multiplication_output := (uns_input1 * uns_input2);
        std_arithmetic_output := std_logic_vector(uns_multiplication_output(width downto 0));
        output <= std_arithmetic_output(width - 1 downto 0);

        -- Set uns_multiplication_overflow_check to be it's max possible value.
        for i in 0 to (width - 1) loop
          uns_multiplication_overflow_check(i) := '1';
        end loop;
        
        if (uns_multiplication_output > uns_multiplication_overflow_check) then
          overflow <= '1';
        else
          overflow <= '0';
        end if;

      -- Output 0. Overflow = '0'.
      when "1000" =>
        output <= std_logic_vector(to_unsigned(0, width));
        overflow <= '0';

      -- Output 0. Overflow = '0'.
      when "1001" =>
        output <= std_logic_vector(to_unsigned(0, width));
        overflow <= '0';

      -- Output input1 shifted left by 1 bit. Overflow = the most significant bit that gets popped from the original input1.
      when "1010" =>
        uns_input1 := unsigned(input1);
        uns_operation_output := shift_left(uns_input1, 1);
        output <= std_logic_vector(uns_operation_output);
        overflow <= input1(width - 1);

      -- Output input1 shifted right by 1 bit. Overflow = the least significant bit that gets popped from the original input1.
      when "1011" =>
        uns_input1 := unsigned(input1);
        uns_operation_output := shift_right(uns_input1, 1);
        output <= std_logic_vector(uns_operation_output);
        overflow <= input1(0);

      -- Output the reverse of the bits in input1. Overflow = '0'.
      when "1100" =>
        for i in 0 to (width - 1) loop
          output(i) <= input1(width - 1 - i);
        end loop;
        overflow <= '0';

      -- Output the high-half bits of input1 swapped with the low-half bits of input1.
      when "1101" =>
        uns_input1 := unsigned(input1);
        uns_operation_output := rotate_left(uns_input1, (width / 2));
        output <= std_logic_vector(uns_operation_output);
        overflow <= '0';

      -- Output 0. Overflow = '0'.
      when "1110" =>
        output <= std_logic_vector(to_unsigned(0, width));
        overflow <= '0';

      -- Output 0. Overflow = '0'.
      when "1111" =>
        output <= std_logic_vector(to_unsigned(0, width));
        overflow <= '0';

      -- Handle all other possible values of sel (like all other possible data types for std_logic).
      when others =>
        output <= std_logic_vector(to_unsigned(0, width));
        overflow <= '0';

    end case;

  end process;

end behavior;









--
