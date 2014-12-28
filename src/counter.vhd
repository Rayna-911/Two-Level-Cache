library ieee;
use ieee.std_logic_1164.all;
use work.eecs361_gates.all;
use work.eecs361.all;

entity counter is
  
  port (
    clk       : in std_logic;
    arst      : in std_logic;
    enable    : in std_logic;
    IncCond   : in std_logic;
    CountOut  : out std_logic_vector(31 downto 0));

end counter;

architecture structural of counter is
component register_n
  generic (
    n : integer);
  port (
    clk      : in  std_logic;
    arst     : in  std_logic;
    regWrt   : in  std_logic;
    data_in  : in  std_logic_vector(n-1 downto 0);
    data_out : out std_logic_vector(n-1 downto 0));
end component;
component fulladder_n
  generic (
    n : integer);
  port (
    cin  : in  std_logic;
    x    : in  std_logic_vector(n-1 downto 0);
    y    : in  std_logic_vector(n-1 downto 0);
    cout : out std_logic;
    z    : out std_logic_vector(n-1 downto 0));
end component;
signal clk_inv : std_logic;
signal WrEnable : std_logic;
signal const_one : std_logic_vector(31 downto 0) := (0=>'1', others=>'0');
signal counter_in : std_logic_vector(31 downto 0);
signal counter_out : std_logic_vector(31 downto 0);
signal dummie_cout : std_logic;
begin

  adder_map : fulladder_n generic map (
    n => 32)
    port map (
      cin  => '0',
      x    => counter_out,
      y    => const_one,
      cout => dummie_cout,
      z    => counter_in);

  inv_map : not_gate port map (
    x => clk,
    z => clk_inv);

  and_map : and_gate port map (
    x => enable,
    y => IncCond,
    z => WrEnable);

  reg_map : register_n generic map (
    n => 32)
    port map (
      clk      => clk_inv,
      arst     => arst,
      regWrt   => WrEnable,
      data_in  => counter_in,
      data_out => counter_out);
      
	  CountOut<=counter_out;

end structural;
