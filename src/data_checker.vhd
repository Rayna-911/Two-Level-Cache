library ieee;
use ieee.std_logic_1164.all;
use work.eecs361_gates.all;

entity check_mem_data is
  
  port (
    x : in  std_logic;
    z : out std_logic);

end check_mem_data;

architecture structural of check_mem_data is
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
component mux
  port (
    sel  : in  std_logic;
    src0 : in  std_logic;
    src1 : in  std_logic;
    z    : out std_logic);
end component;
signal xx : std_logic_vector(0 downto 0);
signal zz : std_logic_vector(0 downto 0);
signal one : std_logic_vector(0 downto 0) := (others=>'1');
signal zero : std_logic_vector(0 downto 0) := (others=>'0');
signal is_one : std_logic;
signal is_zero : std_logic;
signal is_unknown : std_logic;
begin  -- structural

  xx(0) <= x;

  cmp_one : cmp_n generic map (
    n => 1)
    port map (
      a      => xx,
      b      => one,
      a_eq_b => is_one);

  cmp_zero : cmp_n generic map (
    n => 1)
    port map (
      a      => xx,
      b      => zero,
      a_eq_b => is_zero);

  nor_map : nor_gate port map (
    x => is_one,
    y => is_zero,
    z => is_unknown);

  mux_map : mux port map (
    sel  => is_unknown,
    src0 => x,
    src1 => '0',
    z    => z);

end structural;
