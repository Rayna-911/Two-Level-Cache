library ieee;
use ieee.std_logic_1164.all;
use work.eecs361_gates.all;

entity n_or is
  
  generic (
    n           : integer;
    block_width : integer);

  port (
    data : in  std_logic_vector(n*block_width-1 downto 0);
    dout : out std_logic_vector(block_width-1 downto 0));

end n_or;

architecture structural of n_or is
signal temp : std_logic_vector((n-1)*block_width-1 downto 0);
begin  -- structural

  or_map : or_gate_n generic map (
    n => block_width)
    port map (
      x => data(block_width-1 downto 0),
      y => data(2*block_width-1 downto block_width),
      z => temp(block_width-1 downto 0));

  or_arr: for i in 1 to n-2 generate
    or_gate_map : or_gate_n generic map (
      n => block_width)
      port map (
        x => temp(i*block_width-1 downto (i-1)*block_width),
        y => data((i+2)*block_width-1 downto (i+1)*block_width),
        z => temp((i+1)*block_width-1 downto i*block_width));
  end generate or_arr;

  dout <= temp((n-1)*block_width-1 downto (n-2)*block_width);
  
end structural;


