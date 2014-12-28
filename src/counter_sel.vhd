library ieee;
use ieee.std_logic_1164.all;
use work.eecs361_gates.all;

entity counter_sel is
  
  port (
    same   : in  std_logic;
    hit    : in  std_logic;
    is_max : in  std_logic;
    L2Wr   : in  std_logic;
    crst   : out std_logic);

end counter_sel;

architecture structural of counter_sel is
signal no_rst : std_logic;
signal no_same : std_logic;
signal no_hit : std_logic;
signal no_max : std_logic;
signal no_same_no_max : std_logic;
signal same_no_hit_wr : std_logic;
signal same_xor_hit : std_logic;
begin  -- structural

  inv_map1 : not_gate port map (
    x => same,
    z => no_same);

  inv_map2 : not_gate port map (
    x => hit,
    z => no_hit);

  inv_map3 : not_gate port map (
    x => is_max,
    z => no_max);

  inv_map4 : not_gate port map (
    x => no_rst,
    z => crst);

  and_map1 : and_gate port map (
    x => no_same,
    y => no_max,
    z => no_same_no_max);

  xor_map : xor_gate port map (
    x => same,
    y => hit,
    z => same_xor_hit);

  and_map2 : and_gate port map (
    x => same_xor_hit,
    y => L2Wr,
    z => same_no_hit_wr);

  or_map : or_gate port map (
    x => no_same_no_max,
    y => same_no_hit_wr,
    z => no_rst);

end structural;


