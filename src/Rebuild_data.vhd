library ieee;
use ieee.std_logic_1164.all;
use work.eecs361_gates.all;

entity Rebuild_data is
   port (
    base   : in  std_logic_vector(2051 downto 0);--original block data (64*8+1)*4=2052
    data   : in  std_logic_vector(512 downto 0);--data for replacement 64*8+1=513
    offset : in  std_logic_vector(1 downto 0);--sub block offest
    enable : in  std_logic;
    dout   : out std_logic_vector(2051 downto 0));

end Rebuild_data;

architecture structural of Rebuild_data is

component dec_n
  generic (
    n : integer);
  port (
    src : in  std_logic_vector(n-1 downto 0);
    z   : out std_logic_vector((2**n)-1 downto 0));
end component;

component mux_n
  generic (
    n : integer);
  port (
    sel  : in  std_logic;
    src0 : in  std_logic_vector(n-1 downto 0);
    src1 : in  std_logic_vector(n-1 downto 0);
    z    : out std_logic_vector(n-1 downto 0));
end component;

signal offset_dec : std_logic_vector(3 downto 0);
signal sel_wire : std_logic_vector(3 downto 0);

begin  -- structural

  dec_map : dec_n generic map (
    n => 2)
    port map (
      src => offset,
      z   => offset_dec);

  and_arr: for i in 0 to 3 generate
    and_map : and_gate port map (
      x => enable,
      y => offset_dec(i),
      z => sel_wire(i));
  end generate and_arr;

  mux_arr: for i in 0 to 3 generate
    mux_map : mux_n generic map (
      n => 513)
      port map (
        sel  => sel_wire(i),
        src0 => base((i+1)*513-1 downto i*513),
        src1 => data,
        z    => dout((i+1)*513-1 downto i*513));
  end generate mux_arr;

end structural;


