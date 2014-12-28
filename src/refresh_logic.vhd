library ieee;
use ieee.std_logic_1164.all;
use work.eecs361_gates.all;

entity refresh_logic is
  
  port (
    same    : in  std_logic;
    is_max  : in  std_logic;
    refresh : out std_logic);

end refresh_logic;

architecture structural of refresh_logic is
signal not_same : std_logic;
begin  -- structural

  inv_map : not_gate port map (
    x => same,
    z => not_same);

  and_map : and_gate port map (
    x => not_same,
    y => is_max,
    z => refresh);

end structural;
