library ieee;
use ieee.std_logic_1164.all;
use work.eecs361_gates.all;
use work.eecs361.all;

entity sync_csram is
  
  generic (
    INDEX_WIDTH : integer;
    BIT_WIDTH : integer);

  port (
    clk   : in  std_logic;
    cs    : in  std_logic;
    oe    : in  std_logic;
    we    : in  std_logic;
    index : in  std_logic_vector(INDEX_WIDTH-1 downto 0);
    din   : in  std_logic_vector(BIT_WIDTH-1 downto 0);
    dout  : out std_logic_vector(BIT_WIDTH-1 downto 0));

end sync_csram;

architecture structural of sync_csram is
component csram
  generic (
    INDEX_WIDTH : integer;
    BIT_WIDTH   : integer);
  port (
    cs    : in  std_logic;
    oe    : in  std_logic;
    we    : in  std_logic;
    index : in  std_logic_vector(INDEX_WIDTH-1 downto 0);
    din   : in  std_logic_vector(BIT_WIDTH-1 downto 0);
    dout  : out std_logic_vector(BIT_WIDTH-1 downto 0));
end component;
signal clocked_we : std_logic;
signal clk_inv : std_logic;
begin  -- structural

  inv_map : not_gate port map (
    x => clk,
    z => clk_inv);

  and_map : and_gate port map (
    x => clk_inv,
    y => we,
    z => clocked_we);

  csram_map : csram generic map (
    INDEX_WIDTH => INDEX_WIDTH,
    BIT_WIDTH   => BIT_WIDTH)
    port map (
      cs    => cs,
      oe    => oe,
      we    => clocked_we,
      index => index,
      din   => din,
      dout  => dout);

end structural;
