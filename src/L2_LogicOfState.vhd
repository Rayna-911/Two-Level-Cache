library ieee;
use ieee.std_logic_1164.all;
use work.eecs361_gates.all;

entity L2_LogicOfState is
  
  port (
    addr_tag  : in  std_logic_vector(21 downto 0);
    cache_tag : in  std_logic_vector(21 downto 0);
    max_tag   : in  std_logic_vector(21 downto 0);
    valid     : in  std_logic;
    same      : out std_logic;
    hit       : out std_logic;
    is_max    : out std_logic);

end L2_LogicOfState;

architecture structural of L2_LogicOfState is
component cmp_n
  generic (
    n : integer);
  port (
    a             : in  std_logic_vector(n-1 downto 0);
    b             : in  std_logic_vector(n-1 downto 0);
    a_eq_b        : out std_logic;
    a_gt_b        : out std_logic;
    a_lt_b        : out std_logic;
    signed_a_gt_b : out std_logic;
    signed_a_lt_b : out std_logic);
end component;
signal null_gt_1 : std_logic;
signal null_lt_1 : std_logic;
signal null_sgt_1 : std_logic;
signal null_slt_1 : std_logic;
signal null_gt_2 : std_logic;
signal null_lt_2 : std_logic;
signal null_sgt_2 : std_logic;
signal null_slt_2 : std_logic;
signal is_same : std_logic;
begin  -- structural

  cmp_map1 : cmp_n generic map (
    n => 22)
    port map (
      a             => addr_tag,
      b             => cache_tag,
      a_eq_b        => is_same,
      a_gt_b        => null_gt_1,
      a_lt_b        => null_lt_1,
      signed_a_gt_b => null_sgt_1,
      signed_a_lt_b => null_slt_1);

  cmp_map2 : cmp_n generic map (
    n => 22)
    port map (
      a             => cache_tag,
      b             => max_tag,
      a_eq_b        => is_max,
      a_gt_b        => null_gt_2,
      a_lt_b        => null_lt_2,
      signed_a_gt_b => null_sgt_2,
      signed_a_lt_b => null_slt_2);

  and_map : and_gate port map (
    x  => valid,
    y  => is_same,
    z  => hit);

  same <= is_same;

end structural;


