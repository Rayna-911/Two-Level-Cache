library ieee;
use ieee.std_logic_1164.all;
use work.eecs361_gates.all;

entity All_and_x is
  
  generic (
    n : integer);

  port (
    data : in  std_logic_vector(n-1 downto 0);
    x    : in  std_logic;
    dout : out std_logic_vector(n-1 downto 0));

end All_and_x;

architecture structural of All_and_x is

begin  -- structural

  and_arr: for i in 0 to n-1 generate
    and_map : and_gate port map (
      x => x ,
      y => data(i),
      z => dout(i));
  end generate and_arr;

end structural;



