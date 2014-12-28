library ieee;
use ieee.std_logic_1164.all;
use work.eecs361_gates.all;

entity mux_general is
  
  generic (
    sel_width   : integer;
    block_width : integer );
  port (
    data : in  std_logic_vector((2**sel_width)*block_width-1 downto 0);
    sel  : in  std_logic_vector(sel_width-1 downto 0);
    z    : out std_logic_vector(block_width-1 downto 0));
  
end mux_general;

architecture structural of mux_general is
  
component dec_n
  generic (
    n : integer);
  port (
    src : in  std_logic_vector(n-1 downto 0);
    z   : out std_logic_vector((2**n)-1 downto 0));
end component;

component All_and_x
  generic (
    n : integer);
  port (
    data : in  std_logic_vector(n-1 downto 0);
    x    : in  std_logic;
    dout : out std_logic_vector(n-1 downto 0));
end component;

component n_or
  generic (
    n           : integer;
    block_width : integer);
  port (
    data : in  std_logic_vector(n*block_width-1 downto 0);
    dout : out std_logic_vector(block_width-1 downto 0));
end component;

signal sel_wire : std_logic_vector((2**sel_width)-1 downto 0);
signal and_res : std_logic_vector((2**sel_width)*block_width-1 downto 0);

begin  -- structural

  dec_map : dec_n generic map (
    n => sel_width)
    port map (
      src => sel,
      z   => sel_wire);

  and_arr: for i in 0 to (2**sel_width)-1 generate
    and_map : All_and_x generic map (
      n => block_width)
      port map (
        data => data((i+1)*block_width-1 downto i*block_width),
        x    => sel_wire(i),
        dout => and_res((i+1)*block_width-1 downto i*block_width));
  end generate and_arr;

  or_map : n_or generic map (
    n           => 2**sel_width,
    block_width => block_width)
    port map (
      data => and_res,
      dout => z);

end structural;


