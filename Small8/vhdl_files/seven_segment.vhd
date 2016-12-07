LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY seven_segment IS

	PORT (
		i	: in std_logic_vector(3 downto 0);
		
		-- outputs a through g are low true.
		a,b,c,d,e,f,g	: out std_logic
	);
	
END seven_segment;

ARCHITECTURE behavior OF seven_segment IS
BEGIN

	a <= 	(NOT(i(3)) AND NOT(i(2)) AND NOT(i(1)) AND i(0)) OR
			(NOT(i(3)) AND i(2) AND NOT(i(1)) AND NOT(i(0))) OR
			(i(3) AND NOT(i(2)) AND i(1) AND i(0)) OR
			(i(3) AND i(2) AND NOT(i(1)) AND i(0));
			
	b <=	(NOT(i(3)) AND i(2) AND NOT(i(1)) AND i(0)) OR
			(NOT(i(3)) AND i(2) AND i(1) AND NOT(i(0))) OR
			(i(3) AND NOT(i(2)) AND i(1) AND i(0)) OR
			(i(3) AND i(2) AND NOT(i(1)) AND NOT(i(0))) OR
			(i(3) AND i(2) AND i(1) AND NOT(i(0))) OR
			(i(3) AND i(2) AND i(1) AND i(0));
			
	c <=	(NOT(i(3)) AND NOT(i(2)) AND i(1) AND NOT(i(0))) OR
			(i(3) AND i(2) AND NOT(i(1)) AND NOT(i(0))) OR
			(i(3) AND i(2) AND i(1) AND NOT(i(0))) OR
			(i(3) AND i(2) AND i(1) AND i(0));
			
	d <=	(NOT(i(3)) AND NOT(i(2)) AND NOT(i(1)) AND i(0)) OR
			(NOT(i(3)) AND i(2) AND NOT(i(1)) AND NOT(i(0))) OR
			(NOT(i(3)) AND i(2) AND i(1) AND i(0)) OR
			(i(3) AND NOT(i(2)) AND NOT(i(1)) AND i(0)) OR 
			(i(3) AND NOT(i(2)) AND i(1) AND NOT(i(0))) OR
			(i(3) AND i(2) AND i(1) AND i(0));
			
	e <=	(NOT(i(3)) AND NOT(i(2)) AND NOT(i(1)) AND i(0)) OR
			(NOT(i(3)) AND NOT(i(2)) AND i(1) AND i(0)) OR
			(NOT(i(3)) AND i(2) AND NOT(i(1)) AND NOT(i(0))) OR
			(NOT(i(3)) AND i(2) AND NOT(i(1)) AND i(0)) OR
			(NOT(i(3)) AND i(2) AND i(1) AND i(0)) OR
			(i(3) AND NOT(i(2)) AND NOT(i(1)) AND i(0));
			
	f <=	(NOT(i(3)) AND NOT(i(2)) AND NOT(i(1)) AND i(0)) OR
			(NOT(i(3)) AND NOT(i(2)) AND i(1) AND NOT(i(0))) OR
			(NOT(i(3)) AND NOT(i(2)) AND i(1) AND i(0)) OR
			(NOT(i(3)) AND i(2) AND i(1) AND i(0)) OR
			(i(3) AND i(2) AND NOT(i(1)) AND i(0));
			
	g <=	(NOT(i(3)) AND NOT(i(2)) AND NOT(i(1)) AND NOT(i(0))) OR
			(NOT(i(3)) AND NOT(i(2)) AND NOT(i(1)) AND i(0)) OR
			(NOT(i(3)) AND i(2) AND i(1) AND i(0)) OR
			(i(3) AND i(2) AND NOT(i(1)) AND NOT(i(0)));
			

END behavior;