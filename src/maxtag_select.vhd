library ieee;
use ieee.std_logic_1164.all;
use work.eecs361_gates.all;
use work.eecs361.all;

entity maxtag_select is
port (
    din     : in  std_logic_vector(215 downto 0);--The combine of 4 sets tag+counter 
    max_tag : out std_logic_vector(21 downto 0));--the tag with max counter
end maxtag_select;

architecture structural of maxtag_select is
component cmp_n is
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
end component cmp_n;

component mux_n is
  generic (
	n	: integer
  );
  port (
	sel	  : in	std_logic;
	src0  :	in	std_logic_vector(n-1 downto 0);
	src1  :	in	std_logic_vector(n-1 downto 0);
	z	  : out std_logic_vector(n-1 downto 0)
  );
end component mux_n;

signal a_eq_b1,a_gt_b1,cmp_1,signed_a_gt_b1,signed_a_lt_b1 : std_logic; --compare 1
signal a_eq_b2,a_gt_b2,cmp_2,signed_a_gt_b2,signed_a_lt_b2 : std_logic; --compare 2
signal a_eq_b3,a_gt_b3,cmp_3,signed_a_gt_b3,signed_a_lt_b3 : std_logic; --compare 3

signal tag_m1,tag_m2,tag_m3 : std_logic_vector(53 downto 0);

begin
cmp_1_map: cmp_n generic map (n => 32) port map (din(31 downto 0),din(85 downto 54),a_eq_b1,a_gt_b1,cmp_1,signed_a_gt_b1,signed_a_lt_b1);
mux_1_map: mux_n generic map (n => 54) port map (cmp_1,din(53 downto 0),din(107 downto 54),tag_m1);

cmp_2_map: cmp_n generic map (n => 32) port map (tag_m1(31 downto 0),din(139 downto 108),a_eq_b2,a_gt_b2,cmp_2,signed_a_gt_b2,signed_a_lt_b2);
mux_2_map: mux_n generic map (n => 54) port map (cmp_2,tag_m1,din(161 downto 108),tag_m2);

cmp_3_map: cmp_n generic map (n => 32) port map (tag_m2(31 downto 0),din(193 downto 162),a_eq_b3,a_gt_b3,cmp_3,signed_a_gt_b3,signed_a_lt_b3);
mux_3_map: mux_n generic map (n => 54) port map (cmp_3,tag_m2,din(215 downto 162),tag_m3); 

max_tag <= tag_m3(53 downto 32);
end structural;



