library ieee;
use ieee.std_logic_1164.all;
use work.eecs361_gates.all;

entity L1_cache is
  port (
    arst        : in  std_logic;
    clk         : in  std_logic;
    address     : in  std_logic_vector(31 downto 0);
    dataFromCPU : in  std_logic_vector(31 downto 0);
    Wr          : in  std_logic;
    done        : in  std_logic;
    dataFromL2  : in  std_logic_vector(64*8-1 downto 0);
    dataToCPU   : out std_logic_vector(31 downto 0);
    ready       : out std_logic;
    addressOut  : out std_logic_vector(31 downto 0);
    dataToL2    : out std_logic_vector(64*8-1 downto 0);
    request     : out std_logic;
    L2DataWr    : out std_logic;
    l1_hit_cnt  : out std_logic_vector(31 downto 0);
    l1_miss_cnt : out std_logic_vector(31 downto 0);
    l1_evict_cnt : out std_logic_vector(31 downto 0));

end entity L1_cache;

architecture structural of L1_cache is

component L1_datapath is
  port (
    cs             : in std_logic;
    oe             : in std_logic;
    we             : in std_logic;
    d_is_dirty     : in std_logic;
    enable_replace  : in std_logic;
    record_data    : in std_logic;
    DataSrc        : in std_logic;
    TagSrc         : in std_logic;
    DataInSrc      : in std_logic; 
    hit            : out std_logic;
    dirty          : out std_logic;
    CPU_data       : in std_logic_vector(4*8-1 downto 0);
    Tag            : in std_logic_vector(21 downto 0);
    Index          : in std_logic_vector(3 downto 0);
    offset         : in std_logic_vector(5 downto 0);
    DataIn         : out std_logic_vector(4*8-1 downto 0);
    L2DataIn       : in std_logic_vector(511 downto 0);
    L2Data         : out std_logic_vector(511 downto 0);
    L2Addr         : out std_logic_vector(31 downto 0);
    clk            : in std_logic;
    arst           : in std_logic;
	valid:out std_logic);
  
end component L1_datapath;

component L1_control is
  port (
    
    Wr             : in  std_logic;
    hit            : in  std_logic;
    dirty          : in  std_logic;
    done           : in  std_logic;
  state          : in  std_logic_vector(2 downto 0);
    hit_inc        : out std_logic;
    miss_inc       : out std_logic;
    cs             : out std_logic;
    oe             : out std_logic;
    we             : out std_logic;
    is_dirty       : out std_logic;
    enable_replace : out std_logic;
    recordData     : out std_logic;
    DataSrc        : out std_logic;
    DataInSrc      : out std_logic;
    TagSrc         : out std_logic;
    L2DataWr       : out std_logic;
    request        : out std_logic;
    ready          : out std_logic;
    next_state     : out std_logic_vector(2 downto 0));

end component;

component counter is
  
  port (
    clk       : in std_logic;
    arst      : in std_logic;
    enable    : in std_logic;
    IncCond   : in std_logic;
    CountOut  : out std_logic_vector(31 downto 0));

end component counter;

component and_gate is port(
    x: in  std_logic; 
    y: in  std_logic;
    z: out std_logic);
end component ;

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

signal hit_inc_L1 : std_logic;
signal miss_inc_L1 : std_logic;
--for between control & datapath
signal state_into_reg : std_logic_vector (2 downto 0);
signal state_outof_reg : std_logic_vector (2 downto 0);
signal cs_temp  : std_logic;
signal oe_temp  : std_logic;
signal we_temp  : std_logic;
signal is_dirty_temp : std_logic;
signal enable_replace_temp : std_logic;
signal recordData_temp     : std_logic;
signal DataSrc_temp        : std_logic;
signal DataInSrc_temp      : std_logic;
signal TagSrc_temp        : std_logic;
signal hit_temp        : std_logic;
signal dirty_temp      : std_logic;


signal Tag_CPU     : std_logic_vector(21 downto 0);
signal Index_CPU   : std_logic_vector(3 downto 0);
signal offset_CPU  : std_logic_vector(5 downto 0);
signal valid_temp,evict_temp: std_logic;

begin

Tag_CPU <= address(31 downto 10);
Index_CPU <= address(9 downto 6);
offset_CPU <= address(5 downto 0);

control_map : L1_control
  port map(
    
    Wr => Wr,
    hit => hit_temp,
    dirty => dirty_temp,
    done => done,
	  state => state_outof_reg,
    hit_inc => hit_inc_L1,
    miss_inc => miss_inc_L1,
    cs => cs_temp,
    oe => oe_temp,
    we => we_temp,
    is_dirty => is_dirty_temp,
    enable_replace => enable_replace_temp,
    recordData => recordData_temp,
    DataSrc => DataSrc_temp,
    DataInSrc => DataInSrc_temp,
    TagSrc => TagSrc_temp,
    L2DataWr => L2DataWr,
    request => request,
    ready  => ready,
    next_state => state_into_reg);
    
L1_datapath_map : L1_datapath
  port map(
    cs => cs_temp,
    oe => oe_temp,
    we => we_temp,
    d_is_dirty => is_dirty_temp,
    enable_replace => enable_replace_temp,
    record_data => recordData_temp,
    DataSrc => DataSrc_temp,
    TagSrc => TagSrc_temp,
    DataInSrc => DataInSrc_temp,
    hit => hit_temp,
    dirty => dirty_temp,
	
    CPU_data => dataFromCPU,
    Tag => Tag_CPU,
    Index => Index_CPU,
    offset => offset_CPU,
    DataIn => dataToCPU,
	
    L2DataIn => dataFromL2,
    L2Data => dataToL2,
    L2Addr => addressOut,
	
    clk => clk,
    arst => arst,
	valid=>valid_temp);

state_map : register_n 
  generic map(
    n => 3)
  port map(
    clk => clk,
    arst => arst,
    regWrt => '1',
    data_in => state_into_reg,
    data_out => state_outof_reg);
	
 and_map: and_gate 
 port map(
 x=>valid_temp,
 y=>miss_inc_L1,
 z=>evict_temp
 
 );

  hit_count : counter port map (
    clk     => clk,
    arst    => arst,
    enable  => '1',
    IncCond => hit_inc_L1,
    CountOut => l1_hit_cnt);

  miss_count : counter port map (
    clk     => clk,
    arst    => arst,
    enable  => '1',
    IncCond => miss_inc_L1,
    CountOut=> l1_miss_cnt);

  evict_count : counter port map (
    clk     => clk,
    arst    => arst,
    enable  => '1',
    IncCond => evict_temp,
    CountOut=> l1_evict_cnt);

end structural;
