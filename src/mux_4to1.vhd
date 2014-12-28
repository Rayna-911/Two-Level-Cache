library ieee;
use ieee.std_logic_1164.all;
use work.eecs361_gates.all;

entity mux_4to1 is
  port (
       sel0,sel1 : in std_logic;
       src0,src1,src2,src3:	in	std_logic;
	   z	 : out std_logic
      );
end mux_4to1;

architecture structural of mux_4to1 is
signal sg1,sg2: std_logic;

begin 
    p1: entity work.mux port map(sel0,src0,src1,sg1);
        
    p2: entity work.mux port map(sel0,src2,src3,sg2);
	
	p3: entity work.mux port map(sel1,sg1,sg2,z); 
 
end architecture structural;