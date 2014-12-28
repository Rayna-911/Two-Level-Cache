library ieee;
use ieee.std_logic_1164.all;
use work.eecs361_gates.all;

entity L2_cache is
  
  port (
    arst       : in  std_logic;
    clk        : in  std_logic;
    addressIn  : in  std_logic_vector(31 downto 0);
    L1_data    : in  std_logic_vector(511 downto 0);
    request    : in  std_logic;
    L2DataWr   : in  std_logic;
    mem_data   : in  std_logic_vector(511 downto 0);
    DataToL1   : out std_logic_vector(511 downto 0);
    done       : out std_logic;
    addressOut : out std_logic_vector(31 downto 0);
    DataToMem  : out std_logic_vector(511 downto 0);
    cs         : out std_logic;
    oe         : out std_logic;
    we         : out std_logic;
	l2_hit_cnt  : out std_logic_vector(31 downto 0);
    l2_miss_cnt : out std_logic_vector(31 downto 0);
    l2_evict_cnt : out std_logic_vector(31 downto 0));

end L2_cache;

architecture structural of L2_cache is
component L2_datapath is

  port (
    arst       : in  std_logic;
    clk        : in  std_logic;
    addressIn  : in  std_logic_vector(31 downto 0);
    L1_data    : in  std_logic_vector(511 downto 0);--width=sub_block width=64*8=512
    mem_data   : in  std_logic_vector(511 downto 0);
    read_cache : in  std_logic;
    checkback  : in  std_logic;
    WrData     : in  std_logic;
    L2DataWr   : in  std_logic;
    rec_status : in  std_logic;
    dataSrc    : in  std_logic;
    dataInSrc  : in  std_logic;
    DataToL1   : out std_logic_vector(511 downto 0);
    DataToMem  : out std_logic_vector(511 downto 0);
    addressOut : out std_logic_vector(31 downto 0);
    hit        : out std_logic;
    evict      : out std_logic;
	valid      : out std_logic
    );

end component L2_datapath;

component L2_control is
  port (
    arst       : in  std_logic;
    request    : in  std_logic;
    L2DataWr   : in  std_logic;
    hit        : in  std_logic;
    state      : in  std_logic_vector(2 downto 0);
    hit_inc    : out std_logic;
    miss_inc   : out std_logic;
    cs         : out std_logic;
    oe         : out std_logic;
    we         : out std_logic;
    WrData     : out std_logic;
    read_cache : out std_logic;
    checkback  : out std_logic;
    rec_status : out std_logic;
    DataSrc    : out std_logic;
    DataInSrc  : out std_logic;
    done       : out std_logic;
    next_state : out std_logic_vector(2 downto 0);
	ReadHit_check:out std_logic);
end component;
component counter is
  port (
    clk       : in std_logic;
    arst      : in std_logic;
    enable    : in std_logic;
    IncCond   : in std_logic;
    CountOut  : out std_logic_vector(31 downto 0));
end component;

component register_n is
  generic (
    n : integer);
  port (
    clk      : in  std_logic;
    arst     : in  std_logic;
    regWrt   : in  std_logic;
    data_in  : in  std_logic_vector(n-1 downto 0);
    data_out : out std_logic_vector(n-1 downto 0));
end component;

signal hit,evict : std_logic;
signal state : std_logic_vector(2 downto 0);
signal hit_inc : std_logic;
signal miss_inc : std_logic;
signal WrData : std_logic;
signal read_cache : std_logic;
signal checkback : std_logic;
signal rec_status : std_logic;
signal DataSrc : std_logic;
signal DataInSrc : std_logic;
signal next_state : std_logic_vector(2 downto 0);

signal ReadHit_check,hit_inc_real:std_logic;
signal valid,evict_f:std_logic;
begin 

 control_map : L2_control 
    port map (
      arst       => arst,
      request    => request,
      L2DataWr   => L2DataWr,
      hit        => hit,
      state      => state,
      hit_inc    => hit_inc,
      miss_inc   => miss_inc,
      cs         => cs,
      oe         => oe,
      we         => we,
      WrData     => WrData,
      read_cache => read_cache,
      checkback  => checkback,
      rec_status => rec_status,
      DataSrc    => DataSrc,
      DataInSrc  => DataInSrc,
      done       => done,
      next_state => next_state,
	  ReadHit_check =>ReadHit_check);
      
  datapath_map : L2_datapath 
      port map (
      arst      => arst,
      clk       => clk,
      addressIn => addressIn,
      L1_data   => L1_data,
      mem_data  => mem_data,
      read_cache => read_cache,
      checkback => checkback,
      WrData    => WrData,
      L2DataWr  => L2DataWr,
      rec_status => rec_status,
      dataSrc   => DataSrc,
      dataInSrc => DataInSrc,
      DataToL1  => DataToL1,
      DataToMem => DataToMem,
      addressOut => addressOut,
      hit        => hit,
      evict      => evict,
	  valid      => valid
      );
	
  hit_count : counter port map (
    clk     => clk,
    arst    => arst,
    enable  => '1',
    IncCond => hit_inc, --hit_inc_real
    CountOut => l2_hit_cnt);

  miss_count : counter port map (
    clk     => clk,
    arst    => arst,
    enable  => '1',
    IncCond => miss_inc,
    CountOut=> l2_miss_cnt);
--7:48 edit here	
--evict_f_map: and_gate port map(valid, miss_inc,evict_f);
  evict_count : counter port map (
    clk     => clk,
    arst    => arst,
    enable  => '1',
	IncCond => evict,
    --IncCond => evict_f,
    CountOut=> l2_evict_cnt);

  state_register : register_n generic map (
    n => 3)
    port map (
      clk      => clk,
      arst     => arst,
      regWrt   => '1',
      data_in  => next_state,
      data_out => state);

end structural;


