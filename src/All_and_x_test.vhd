library ieee;
use ieee.std_logic_1164.all;

entity All_and_x_test is

  port (
    dout_test : out std_logic_vector(3 downto 0)
    );
end All_and_x_test;

architecture structural of All_and_x_test is
component All_and_x is
  generic (
    n : integer);
  port (
    data : in  std_logic_vector(n-1 downto 0);
    x    : in  std_logic;
    dout : out std_logic_vector(n-1 downto 0));

end component All_and_x;

signal data_test : std_logic_vector(3 downto 0);
signal x_test : std_logic;
signal n: integer := 4;

begin

  All_and_x_map: All_and_x generic map (n=>n) port map (data => data_test, x => x_test,dout => dout_test);
  test_proc : process
  begin
    --0000 v.s. 0000
    data_test <= "1100";
    x_test <= '1';
  
    wait for 5 ns;
    data_test <= "1100";
    x_test <= '0';
    wait for 5 ns;
    
    --0001 v.s. 0001
     data_test <= "1011";
    x_test <= '1';
    wait for 5 ns;
    data_test <= "1011";
    x_test <= '0';
    wait for 5 ns;

    wait;
  end process;
end architecture structural;


