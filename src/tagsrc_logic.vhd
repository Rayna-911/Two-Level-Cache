library ieee;
use ieee.std_logic_1164.all;
use work.eecs361_gates.all;

entity tagsrc_logic is
  
  port (
    same   : in  std_logic;
    is_max : in  std_logic;
    L2Wr   : in  std_logic;
    tagSrc : out std_logic);

end tagsrc_logic;

architecture structural of tagsrc_logic is
signal no_max : std_logic;
signal same_or_no_max : std_logic;
begin  -- structural

  inv_map : not_gate port map (
    x => is_max,
    z => no_max);

  or_map1 : or_gate port map (
    x => same,
    y => no_max,
    z => same_or_no_max);

  or_map2 : or_gate port map (
    x => same_or_no_max,
    y => L2Wr,
    z => tagSrc);

end structural;
