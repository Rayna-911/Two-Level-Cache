library ieee;
use ieee.std_logic_1164.all;
use work.eecs361_gates.all;
use work.eecs361.all;

entity L1_datapath is
  port (
    cs             : in std_logic;
    oe             : in std_logic;
    we             : in std_logic;
    d_is_dirty     : in std_logic;
    enable_replace  : in std_logic;
    record_data    : in std_logic;
    DataSrc        : in std_logic;
    TagSrc         : in std_logic;
    DataInSrc      : in std_logic; --above is all the input by control logic
    hit            : out std_logic;
    dirty          : out std_logic;
    --for CPU
    CPU_data       : in std_logic_vector(4*8-1 downto 0);
    Tag            : in std_logic_vector(21 downto 0);
    Index          : in std_logic_vector(3 downto 0);
    offset         : in std_logic_vector(5 downto 0);
    DataIn         : out std_logic_vector(4*8-1 downto 0);
    --for L2 Data
    L2DataIn       : in std_logic_vector(511 downto 0);
    L2Data         : out std_logic_vector(511 downto 0);
    L2Addr         : out std_logic_vector(31 downto 0);
    --for outside
    clk            : in std_logic;
    arst           : in std_logic;
	valid:out std_logic);
  
end entity L1_datapath;

Architecture Structural of L1_datapath is

component L1_replacer is
  port (
    is_dirty       : in  std_logic;
    Tag            : in  std_logic_vector(21 downto 0);
    base           : in  std_logic_vector((2**4)*(4*8)-1 downto 0);
    data           : in  std_logic_vector(4*8-1 downto 0);
    offset         : in  std_logic_vector(6-1 downto 0);
    enable_replace : in  std_logic;
    din_csram      : out std_logic_vector((2+22+(2**4)*(4*8))-1 downto 0));
end component L1_replacer;

component sync_csram is
  
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

end component sync_csram;

component Tag22_cmp is
  port (
    aa  : in std_logic_vector(21 downto 0);
    bb  : in std_logic_vector(21 downto 0);
    eq  : out std_logic);
    
end component Tag22_cmp;

component register_n is
  
  generic (
    n : integer);

  port (
    clk      : in  std_logic;
    arst     : in  std_logic;
    regWrt   : in  std_logic;
    data_in  : in  std_logic_vector(n-1 downto 0);
    data_out : out std_logic_vector(n-1 downto 0));

end component register_n;

component general_mux is
  
  generic (
    sel_width   : integer;
    block_width : integer );
  port (
    data : in  std_logic_vector((2**sel_width)*block_width-1 downto 0);
    sel  : in  std_logic_vector(sel_width-1 downto 0);
    z    : out std_logic_vector(block_width-1 downto 0));
  
end component general_mux;

--for sync_csram
signal d_din  : std_logic_vector((2+22+(2**4)*(4*8))-1 downto 0);
signal d_dout : std_logic_vector((2+22+(2**4)*(4*8))-1 downto 0);
--for data_reg
signal d_dout_q : std_logic_vector (511 downto 0);
--for general mux
signal gen_mux_data : std_logic_vector (511 downto 0);
--for L1replacer
signal base_data : std_logic_vector (511 downto 0);
--for hit
signal same : std_logic;

begin

L1_replacer_map : L1_replacer port map(
    is_dirty => d_is_dirty,
    Tag => Tag,
    base => base_data,
    data => CPU_data,
    offset => offset,
    enable_replace => enable_replace,
    din_csram => d_din);

Sync_csram_map : sync_csram generic map(
    INDEX_WIDTH => 4,
    BIT_WIDTH => 536) 
  port map(
    clk => clk,
    cs => cs,
    oe => oe,
    we => we,
    index => Index,
    din => d_din,
    dout => d_dout);

cmp_map : Tag22_cmp port map(
    aa => Tag,
    bb => d_dout (533 downto 512),
    eq => same);
  
hit_map : and_gate port map(same, d_dout(535), hit); --same & valid bit creat hit

Data_reg_map : register_n  
  generic map (
    n => 512)
  port map (
    clk => clk,
    arst => arst,
    regWrt => record_data,
    data_in => d_dout (511 downto 0),
    data_out => d_dout_q);
    
gen_mux_map : general_mux
  generic map (
    sel_width =>4,
    block_width =>4*8 )
  port map (
    data => gen_mux_data,
    sel => offset(5 downto 2),
    z => DataIn);

Gen_mux_input_mux_map: mux_n
  generic map(
	  n	=> 512)
  port map(
	sel	=> DataInSrc,
	src0 => d_dout(511 downto 0),
	src1 => L2DataIn,
	z	=> gen_mux_data);

datasrc_mux_map : mux_n
  generic map(
	  n	=> 512)
  port map(
	sel	=> DataSrc,
	src0 => d_dout_q,
	src1 => L2DataIn,
	z	=> base_data);
	
L2Data <= d_dout(511 downto 0);
    
L2Addr_mux_map : mux_n
  generic map(
	  n	=> 22)
  port map(
	sel	=> TagSrc,
	src0 => Tag,
	src1 => d_dout(533 downto 512),
	z	=> L2Addr(31 downto 10));

L2Addr(9 downto 6) <= Index;

L2Addr(5 downto 0) <= (others=>'0');

dirty <= d_dout(534);
valid<=d_dout(535);

end structural;
