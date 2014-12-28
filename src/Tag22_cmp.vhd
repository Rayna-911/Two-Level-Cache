library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Tag22_cmp is

  port (
    aa  : in std_logic_vector(21 downto 0);
    bb  : in std_logic_vector(21 downto 0);
    eq  : out std_logic);
    
end Tag22_cmp;

architecture behavioral of Tag22_cmp is

component cmp_n
  generic (
    n : integer
  );
  port (
    a      : in std_logic_vector(n-1 downto 0);
    b      : in std_logic_vector(n-1 downto 0);
    a_eq_b : out std_logic;
    a_gt_b : out std_logic;
    a_lt_b : out std_logic;
    signed_a_gt_b : out std_logic;
    signed_a_lt_b : out std_logic
  );
end component;

begin

cmp_n_map : cmp_n generic map(
  n => 22 )
  port map (
    a => aa,
    b => bb,
    a_eq_b => eq);

end architecture behavioral;