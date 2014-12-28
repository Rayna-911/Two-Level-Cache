library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.eecs361_gates.all;

entity memory is
  generic (
    mem_file : string;
    num_word : integer);
  port (
    clk : in std_logic;
    cs : in std_logic;
    oe : in std_logic;
    we : in std_logic;
    addr : in std_logic_vector(31 downto 0);
    din : in std_logic_vector(num_word*32-1 downto 0);
    dout : out std_logic_vector(num_word*32-1 downto 0));
end memory;

architecture structural of memory is
component syncram
  generic (
    mem_file : string);
  port (
    clk : in std_logic;
    cs : in std_logic;
    oe : in std_logic;
    we : in std_logic;
    addr : in std_logic_vector(31 downto 0);
    din : in std_logic_vector(31 downto 0);
    dout : out std_logic_vector(31 downto 0));
end component;
component fulladder_32
  port (
    cin : in std_logic;
    x : in std_logic_vector(31 downto 0);
    y : in std_logic_vector(31 downto 0);
    cout : out std_logic;
    z : out std_logic_vector(31 downto 0));
end component;
component check_mem_data
  port (
    x : in  std_logic;
    z : out std_logic);
end component;
signal address_arr : std_logic_vector(32*num_word-1 downto 0);
signal dummie_cout : std_logic_vector(num_word-1 downto 0);
signal mem_dout : std_logic_vector(num_word*32-1 downto 0);
begin
  mem_arr : for i in 0 to num_word-1 generate
    sram_map : syncram generic map (
      mem_file => mem_file)
      port map (
        clk => clk,
        cs => cs,
        oe => oe,
        we => we,
        addr => address_arr(32*(i+1)-1 downto 32*i),
        din => din(32*(i+1)-1 downto 32*i),
        dout => mem_dout(32*(i+1)-1 downto 32*i));
  end generate mem_arr;

  adder_arr : for i in 0 to num_word-1 generate
    adder_map : fulladder_32 port map (
      cin => '0',
      x => addr,
      y => std_logic_vector(to_unsigned(i*4, 32)),
      cout => dummie_cout(i),
      z => address_arr(32*(i+1)-1 downto 32*i));
  end generate adder_arr;

  check_data: for i in 0 to num_word*32-1 generate
    checker : check_mem_data port map (
      x => mem_dout(i),
      z => dout(i));
  end generate check_data;
end structural;
