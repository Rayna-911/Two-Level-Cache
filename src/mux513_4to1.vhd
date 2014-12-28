library ieee;
use ieee.std_logic_1164.all;
use work.eecs361.mux_n;

entity mux513_4to1 is
  port (
  data :in  std_logic_vector(2051 downto 0);--the combine of vb+data from 4 sets
	sel    : in  std_logic_vector(1 downto 0);--sel of offset
	z	    : out std_logic_vector(512 downto 0)
  );
end mux513_4to1;

architecture structural of mux513_4to1 is
  signal sel0,sel1: std_logic_vector(512 downto 0);
begin
  mux0_map: mux_n generic map (n => 513) port map (sel =>  sel(0), src0  => data(512 downto 0), src1 => data(1025 downto 513), z	=> sel0);--00,01
  mux1_map: mux_n generic map (n => 513) port map (sel =>  sel(0), src0  => data(1538 downto 1026), src1 => data(2051 downto 1539), z	=> sel1);--10,11
 
 mux_map : mux_n generic map (n => 513) port map (sel =>  sel(1), src0  => sel0,  src1 => sel1,  z	=> z);
end structural;
