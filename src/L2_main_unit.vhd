library ieee;
use ieee.std_logic_1164.all;
use work.eecs361_gates.all;

entity L2_main_unit is
  port (
    arst        : in  std_logic;
    addr_tag    : in  std_logic_vector(21 downto 0);--tag:22
    addr_index  : in  std_logic_vector(1 downto 0);--index for 4 line:2
    addr_offset : in  std_logic_vector(1 downto 0);--block offset for 4 sub block:2
    mem_data    : in  std_logic_vector(511 downto 0);--data from memory
    L1_data     : in  std_logic_vector(511 downto 0);--data from L1
    max_tag     : in  std_logic_vector(21 downto 0);--the max tag
    clk         : in  std_logic;
    read_cache  : in  std_logic;
    checkback   : in  std_logic;
    WrData      : in  std_logic;
    L2DataWr    : in  std_logic;
    rec_status  : in  std_logic;
    dataSrc     : in  std_logic;
    global_hit  : in  std_logic;
    max_from_lower : in  std_logic;
    max_to_upper : out std_logic;
    hit         : out std_logic;
    data        : out std_logic_vector(511 downto 0);--output data
    tag_count   : out std_logic_vector(53 downto 0);--tag+counter:22+32=54
    evict       : out std_logic;
	valid       :out std_logic
    );

end L2_main_unit;

architecture structural of L2_main_unit is
  
component sync_csram is --main component for memory
  generic (
    INDEX_WIDTH : integer;
    BIT_WIDTH   : integer);
  port (
    clk   : in  std_logic;
    cs    : in  std_logic;
    oe    : in  std_logic;
    we    : in  std_logic;
    index : in  std_logic_vector(INDEX_WIDTH-1 downto 0);
    din   : in  std_logic_vector(BIT_WIDTH-1 downto 0);
    dout  : out std_logic_vector(BIT_WIDTH-1 downto 0));
end component;

component L2_Write is
 port (
    addr_tag   : in std_logic_vector(21 downto 0);
    cache_tag  : in std_logic_vector(21 downto 0);
    count      : in std_logic_vector(31 downto 0);
    cache_data : in std_logic_vector(2051 downto 0);--(64*8+1)*4
    mem_data   : in std_logic_vector(511 downto 0);--mememory write to L2
    L1_data    : in std_logic_vector(511 downto 0);--L1 write L2
    blk_offset : in std_logic_vector(1 downto 0);--4 subset, 2bit block offset
    same       : in std_logic;
    hit        : in std_logic;
    is_max     : in std_logic;
    L2Wr       : in std_logic;
    dataSrc    : in std_logic;
    WrData     : in std_logic;
    dout        : out std_logic_vector(2105 downto 0);
    evict      : out std_logic
    );
end component L2_Write;

component L2_LogicOfState is
  
  port (
    addr_tag  : in  std_logic_vector(21 downto 0);
    cache_tag : in  std_logic_vector(21 downto 0);
    max_tag   : in  std_logic_vector(21 downto 0);
    valid     : in  std_logic;
    same      : out std_logic;
    hit       : out std_logic;
    is_max    : out std_logic);

end component L2_LogicOfState;

component mux513_4to1 is
  port (
  data :in  std_logic_vector(2051 downto 0);--the combine of vb+data from 4 sets
	sel    : in  std_logic_vector(1 downto 0);--sel of offset
	z	    : out std_logic_vector(512 downto 0)
  );
end component mux513_4to1;

component All_and_x is
  generic (
    n : integer);
  port (
    data : in  std_logic_vector(n-1 downto 0);
    x    : in  std_logic;
    dout : out std_logic_vector(n-1 downto 0));

end component All_and_x;

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

component mux is 
    port (
    sel : in std_logic;
    src0 : in std_logic;
    src1 : in std_logic;
    z : out std_logic);
end component;


signal write_cache : std_logic;
signal sram_din : std_logic_vector(2105 downto 0);--write to L2 Rebuilded data back into L2 mem
signal cache_line : std_logic_vector(2105 downto 0);--Output from L2 mem
signal cache_line_recorded : std_logic_vector(2105 downto 0);--output from mem register
signal status : std_logic_vector(2 downto 0);  -- status :2-same, 1-hit, 0-is_max
signal real_max : std_logic;--check if it is the max
signal masked_max : std_logic;
signal max_from_lower_invert : std_logic;
-- signal replace_tmp : std_logic;
-- signal enable_replace : std_logic;
signal status_recorded : std_logic_vector(2 downto 0);
signal raw_block : std_logic_vector(512 downto 0);  -- a subblock od vb+data =513, for compare

signal valid_01,valid_23,miss,evict_null,evict_tmp:std_logic;

begin  -- structural
--5:31 evict -validbit
--valid_01_map: and_gate port map (cache_line(512),cache_line(1025),valid_01);
--valid_23_map: and_gate port map (cache_line(1538),cache_line(2051),valid_23);
--valid_output_map: and_gate port map (valid_01,valid_23,valid);
    
  invert_lower_max : not_gate port map (
    x => max_from_lower,
    z => max_from_lower_invert);

  set_real_max : and_gate port map (
    x => status_recorded(0),
    y => max_from_lower_invert,
    z => real_max);
    
  mask_max : mux port map (
    sel => global_hit,
    src0 => real_max,
    src1 => '0',
    z => masked_max);
    
  max_to_upper <= status_recorded(0);
--write data rebuild
  write_map : L2_Write 
               port map (
              addr_tag   => addr_tag,
              cache_tag  => cache_line_recorded(2105 downto 2084),
              count      => cache_line_recorded(2083 downto 2052),
              cache_data => cache_line_recorded(2051 downto 0),
              mem_data   => mem_data,
              L1_data    => L1_data,
              blk_offset => addr_offset,
              same       => status_recorded(2),
              hit        => status_recorded(1),
              is_max     => masked_max,
              L2Wr       => L2DataWr,
              dataSrc    => dataSrc,
              WrData     => WrData,
              dout       => sram_din,
			 -- evict      => evict_null);
              evict      => evict);
--generate write enable to write L2 mem
  or_map : or_gate port map (WrData,checkback,write_cache);

  synccsram_map : sync_csram generic map (INDEX_WIDTH => 2,BIT_WIDTH   => 2106)
                         port map (clk,'1',read_cache,write_cache,addr_index,sram_din,cache_line);
  cache_register_map : register_n generic map (n => 2106)port map (clk,arst,rec_status,cache_line, cache_line_recorded);

  tag_count <= cache_line(2105 downto 2052);


--select which subblock to operate
select_subblock_map : mux513_4to1 
    port map (
      data => cache_line(2051 downto 0),
      sel  => addr_offset,
      z    => raw_block);
      
  state_map : L2_LogicOfState 
    port map (
      addr_tag  => addr_tag,
      cache_tag => cache_line(2105 downto 2084),
      max_tag   => max_tag,--compare with max tag
      valid     => raw_block(512),--the valid bit
      same      => status(2),
      hit       => status(1),
      is_max    => status(0));
	  
--evict try
--miss_map:not_gate port map (status(1),miss);
--evict_gen_map:and_gate port map (raw_block(512),miss,evict_tmp);
--evict_f_map:and_gate port map (raw_block(512),evict_null,evict);
valid <= raw_block(512);
--output or not by hit type
  dataoutput_map : All_and_x generic map ( n => 512) port map (raw_block(511 downto 0),status(1),data);

  state_register_map : register_n generic map (n => 3)port map (clk,arst,rec_status,status,status_recorded);

        
  hit <= status(1);
  
end structural;

