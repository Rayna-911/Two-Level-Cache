library ieee;
use ieee.std_logic_1164.all;
use work.eecs361_gates.all;

entity L1_replacer is
  port (
    is_dirty       : in  std_logic;
    Tag            : in  std_logic_vector(21 downto 0);
    base           : in  std_logic_vector((2**4)*(4*8)-1 downto 0);
    data           : in  std_logic_vector(4*8-1 downto 0);
    offset         : in  std_logic_vector(6-1 downto 0);
    enable_replace : in  std_logic;
    din_csram      : out std_logic_vector((2+22+(2**4)*(4*8))-1 downto 0));
end L1_replacer;

architecture structural of L1_replacer is

component replacer is
  
  generic (
    offset_width : integer;
    block_width  : integer);

  port (
    base   : in  std_logic_vector((2**offset_width)*block_width-1 downto 0);
    data   : in  std_logic_vector(block_width-1 downto 0);
    offset : in  std_logic_vector(offset_width-1 downto 0);
    enable : in  std_logic;
    dout   : out std_logic_vector((2**offset_width)*block_width-1 downto 0));

end component replacer;

signal dout_replacer : std_logic_vector((2**4)*(4*8)-1 downto 0);
signal offset_replacer : std_logic_vector (3 downto 0);

begin

offset_replacer <= offset(5 downto 2);

  replacer_map : replacer generic map (
    offset_width => 4,
    block_width => 4*8)
  port map (
    base => base,
    data => data,
    offset => offset_replacer,
    enable => enable_replace,
    dout => dout_replacer);
 
din_csram(535) <= '1';
din_csram(534) <= is_dirty;
din_csram(533 downto 512) <= Tag;
din_csram(511 downto 0) <= dout_replacer;
    
end structural;

