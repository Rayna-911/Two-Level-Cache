library ieee;
use ieee.std_logic_1164.all;
use work.eecs361_gates.all;

entity register_n is
  
  generic (
    n : integer);

  port (
    clk      : in  std_logic;
    arst     : in  std_logic;
    regWrt   : in  std_logic;
    data_in  : in  std_logic_vector(n-1 downto 0);
    data_out : out std_logic_vector(n-1 downto 0));

end register_n;

architecture structural of register_n is
component dffr_a
  port (
    clk    : in  std_logic;
    arst   : in  std_logic;
    aload  : in  std_logic;
    adata  : in  std_logic;
    d      : in  std_logic;
    enable : in  std_logic;
    q      : out std_logic);
end component;
signal enabled_clk : std_logic;
begin  -- structural

  dffr_a_arr : for i in 0 to n-1 generate
    dffr_a_map : dffr_a port map (
      clk    => clk,
      arst   => arst,
      aload  => '0',
      adata  => '0',
      d      => data_in(i),
      enable => regWrt,
      q      => data_out(i));
  end generate dffr_a_arr;

end structural;
