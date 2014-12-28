library ieee;
use ieee.std_logic_1164.all;
use work.eecs361_gates.all;

entity memory_hierarchy is
  generic (
    mem_file : string
  );
  
  port (
    clk         : in  std_logic;
	EN          : in  std_logic;
	Wr          : in  std_logic;
	Addr     	: in  std_logic_vector(31 downto 0);
	DataIn 		: in  std_logic_vector(31 downto 0);
    ready       : out std_logic;
    DataOut   	: out std_logic_vector(31 downto 0);
	l1_hit_cnt   : out std_logic_vector(31 downto 0);
	l1_miss_cnt  : out std_logic_vector(31 downto 0);
	l1_evict_cnt : out std_logic_vector(31 downto 0);
	l2_hit_cnt   : out std_logic_vector(31 downto 0);
	l2_miss_cnt  : out std_logic_vector(31 downto 0);
	l2_evict_cnt : out std_logic_vector(31 downto 0));

end memory_hierarchy;

architecture structural of memory_hierarchy is
component L1_cache
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
	l1_miss_cnt  : out std_logic_vector(31 downto 0);
	l1_evict_cnt : out std_logic_vector(31 downto 0));
end component;
component L2_cache
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
	l2_hit_cnt   : out std_logic_vector(31 downto 0);
	l2_miss_cnt  : out std_logic_vector(31 downto 0);
	l2_evict_cnt : out std_logic_vector(31 downto 0));
end component;
component memory
  generic (
    mem_file : string;
    num_word : integer);
  port (
    clk  : in  std_logic;
    cs   : in  std_logic;
    oe   : in  std_logic;
    we   : in  std_logic;
    addr : in  std_logic_vector(31 downto 0);
    din  : in  std_logic_vector(num_word*32-1 downto 0);
    dout : out std_logic_vector(num_word*32-1 downto 0));
end component;
component not_gate
  port (
    x   : in  std_logic;
    z   : out std_logic
  );
end component;

signal arst : std_logic;
signal done : std_logic;
signal dataFromL2 : std_logic_vector(64*8-1 downto 0);
signal addressToL2 : std_logic_vector(31 downto 0);
signal dataToL2 : std_logic_vector(64*8-1 downto 0);
signal request : std_logic;
signal L2DataWr : std_logic;
signal dataFromMem : std_logic_vector(64*8-1 downto 0);
signal addressToMem : std_logic_vector(31 downto 0);
signal dataToMem : std_logic_vector(64*8-1 downto 0);
signal cs : std_logic;
signal oe : std_logic;
signal we : std_logic;
begin  -- structural
  
  inv: not_gate
  port map(
   x => EN,
   z => arst);
  
  L1 : L1_cache 
  port map (
    arst        => arst,
    clk         => clk,
    address     => Addr,
    dataFromCPU => DataIn,
    Wr          => Wr,
    done        => done,
    dataFromL2  => dataFromL2,
    dataToCPU   => DataOut,
    ready       => ready,
    addressOut  => addressToL2,
    dataToL2    => dataToL2,
    request     => request,
    L2DataWr    => L2DataWr,
	l1_hit_cnt  => l1_hit_cnt,
	l1_miss_cnt => l1_miss_cnt,
	l1_evict_cnt => l1_evict_cnt);

  L2 : L2_cache 
  port map (
    arst       => arst,
    clk        => clk,
    addressIn  => addressToL2,
    L1_data    => dataToL2,
    request    => request,
    L2DataWr   => L2DataWr,
    mem_data   => dataFromMem,
    DataToL1   => dataFromL2,
    done       => done,
    addressOut => addressToMem,
    DataToMem  => dataToMem,
    cs         => cs,
    oe         => oe,
    we         => we,
	l2_hit_cnt  => l2_hit_cnt,
	l2_miss_cnt => l2_miss_cnt,
	l2_evict_cnt => l2_evict_cnt);

  memory_map : memory generic map (
    mem_file => mem_file,
    num_word => 16)
    port map (
      clk  => clk,
      cs   => cs,
      oe   => oe,
      we   => we,
      addr => addressToMem,
      din  => dataToMem,
      dout => dataFromMem);
	  
end structural;
