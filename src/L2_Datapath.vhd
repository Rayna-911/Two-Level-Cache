library ieee;
use ieee.std_logic_1164.all;
use work.eecs361_gates.all;

entity L2_datapath is

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

end L2_datapath;

architecture structural of L2_datapath is
component L2_main_unit
  
  port (
    arst        : in  std_logic;
    addr_tag    : in  std_logic_vector(21 downto 0);--tag:32-2-4-2-2=22bit
    addr_index  : in  std_logic_vector(1 downto 0);--index:4 lines=2 bit
    addr_offset : in  std_logic_vector(1 downto 0);--block offset:4 subset:2 bit
    mem_data    : in  std_logic_vector(511 downto 0);
    L1_data     : in  std_logic_vector(511 downto 0);
    max_tag     : in  std_logic_vector(21 downto 0);
    clk         : in  std_logic;
    read_cache  : in  std_logic;
    checkback   : in  std_logic;
    WrData      : in  std_logic;
    L2DataWr    : in  std_logic;
    rec_status  : in  std_logic;
    dataSrc     : in  std_logic;
    global_hit  : in  std_logic;
    max_from_lower : in std_logic;
    max_to_upper : out std_logic;
    hit         : out std_logic;
    data        : out std_logic_vector(511 downto 0);
    tag_count   : out std_logic_vector(53 downto 0);--the combine of tag and count=22+32=54bit
    evict       : out std_logic;
		valid       :out std_logic
    );
end component;

component n_or
  generic (
    n           : integer;
    block_width : integer);
  port (
    data : in  std_logic_vector(n*block_width-1 downto 0);
    dout : out std_logic_vector(block_width-1 downto 0));
end component;

component or_gate_n 
  generic (
    n   : integer
  );
  port (
    x   : in  std_logic_vector(n-1 downto 0);
    y   : in  std_logic_vector(n-1 downto 0);
    z   : out std_logic_vector(n-1 downto 0)
  );
end component or_gate_n;

component maxtag_select is
port (
    din     : in  std_logic_vector(215 downto 0);--The combine of 4 sets tag+counter 
    max_tag : out std_logic_vector(21 downto 0));--the tag with max counter
end component maxtag_select;


component mux_n
  generic (
    n : integer);
  port (
    sel  : in  std_logic;
    src0 : in  std_logic_vector(n-1 downto 0);
    src1 : in  std_logic_vector(n-1 downto 0);
    z    : out std_logic_vector(n-1 downto 0));
end component;
component register_n
  generic (
    n : integer);
  port (
    clk      : in  std_logic;
    arst     : in  std_logic;
    regWrt   : in  std_logic;
    data_in  : in  std_logic_vector(n-1 downto 0);
    data_out : out std_logic_vector(n-1 downto 0));
end component;
signal hit_arr : std_logic_vector(3 downto 0);
signal data_arr : std_logic_vector(2047 downto 0);
signal tag_count_arr : std_logic_vector(215 downto 0);--FOR TAG+COUNT FOR 4 SETS 54*4-1=215
signal max_arr : std_logic_vector(3 downto 0);
signal hit_inter : std_logic_vector(1 downto 0);--internal hit 
signal hit_combined : std_logic;
signal data_combined : std_logic_vector(511 downto 0);
signal max_tag : std_logic_vector(21 downto 0);
signal data_recorded : std_logic_vector(511 downto 0);
signal evict0,evict1,evict2,evict3,evict01,evict23:std_logic;
signal valid0,valid1,valid2,valid3,valid01,valid23,valid_bit:std_logic;
begin  -- structural
--dataout to memory: write through    
  DataToMem <= L1_data;
--address output when miss
  addressOut <= addressIn;
--4-way-associative with 4 L2_main_unit   
Sub_set0 : L2_main_unit 
           port map (
                arst       => arst,
                addr_tag   => addressIn(31 downto 10),
                addr_index => addressIn(9 downto 8),
                addr_offset => addressIn(7 downto 6),
                mem_data   => mem_data,
                L1_data    => L1_data,
                max_tag    => max_tag,
                clk        => clk,
                read_cache => read_cache,
                checkback  => checkback,
                WrData     => WrData,
                L2DataWr   => L2DataWr,
                rec_status => rec_status,
                dataSrc    => dataSrc,
                global_hit => hit_combined,
                max_from_lower => '0',
                max_to_upper => max_arr(0),
                hit        => hit_arr(0),
                data       => data_arr(511 downto 0),--set0 data from 511-0
                tag_count  => tag_count_arr(53 downto 0),--set0 tag_count from 53-0(22+32=54)
                evict      => evict0,
				valid => valid0
				);
Sub_set1 : L2_main_unit 
           port map (
                arst       => arst,
                addr_tag   => addressIn(31 downto 10),
                addr_index => addressIn(9 downto 8),
                addr_offset => addressIn(7 downto 6),
                mem_data   => mem_data,
                L1_data    => L1_data,
                max_tag    => max_tag,
                clk        => clk,
                read_cache => read_cache,
                checkback  => checkback,
                WrData     => WrData,
                L2DataWr   => L2DataWr,
                rec_status => rec_status,
                dataSrc    => dataSrc,
                global_hit => hit_combined,
                max_from_lower => max_arr(0),
                max_to_upper => max_arr(1),
                hit        => hit_arr(1),
                data       => data_arr(1023 downto 512),--set1 data from 1023-512
                tag_count  => tag_count_arr(107 downto 54),--set1 tag_count from 107-54(22+32=54)
                evict      => evict1,
				valid => valid1
                );
Sub_set2 : L2_main_unit 
           port map (
                arst       => arst,
                addr_tag   => addressIn(31 downto 10),
                addr_index => addressIn(9 downto 8),
                addr_offset => addressIn(7 downto 6),
                mem_data   => mem_data,
                L1_data    => L1_data,
                max_tag    => max_tag,
                clk        => clk,
                read_cache => read_cache,
                checkback  => checkback,
                WrData     => WrData,
                L2DataWr   => L2DataWr,
                rec_status => rec_status,
                dataSrc    => dataSrc,
                global_hit => hit_combined,
                max_from_lower => max_arr(1),
                max_to_upper => max_arr(2),
                hit        => hit_arr(2),
                data       => data_arr(1535 downto 1024),--set2 data from 1535-1024
                tag_count  => tag_count_arr(161 downto 108),--set2 tag_count from 161-108
                evict      => evict2,
				valid => valid2
                );
Sub_set3 : L2_main_unit 
           port map (
                arst       => arst,
                addr_tag   => addressIn(31 downto 10),
                addr_index => addressIn(9 downto 8),
                addr_offset => addressIn(7 downto 6),
                mem_data   => mem_data,
                L1_data    => L1_data,
                max_tag    => max_tag,
                clk        => clk,
                read_cache => read_cache,
                checkback  => checkback,
                WrData     => WrData,
                L2DataWr   => L2DataWr,
                rec_status => rec_status,
                dataSrc    => dataSrc,
                global_hit => hit_combined,
                max_from_lower => max_arr(2),
                max_to_upper => max_arr(3),
                hit        => hit_arr(3),
                data       => data_arr(2047 downto 1536),--set3 data from 2047-1536
                tag_count  => tag_count_arr(215 downto 162),--set1 tag_count from 215-162
                evict      => evict3,
				valid => valid3
                ); 
     v01_map:and_gate port map (valid0,valid1,valid01);
	 v23_map:and_gate port map (valid2,valid3,valid23);
	 valid_map:and_gate port map (valid01,valid23,valid);
	-- valid_map:and_gate port map (valid01,valid23,valid_bit);
	-- evict_map:not_gate port map (hit_combined,evict0);
	-- evict_gen_map:and_gate port map(evict0,valid_bit,evict);
	
  evict01_map: or_gate port map(evict0,evict1,evict01);  
  evict23_map: or_gate port map(evict2,evict3,evict23);  
  evict_map  : or_gate port map(evict01,evict23,evict);  
  
  inter_hit_map: or_gate_n  generic map(n => 2) port map( hit_arr(3 downto 2),hit_arr(1 downto 0), hit_inter );
  hit_map      : or_gate port map(hit_inter(1),hit_inter(0),hit_combined);--generate hit
  hit <= hit_combined;
--generate data for output
  combine_map2 : n_or generic map (n => 4,block_width => 512)
                            port map (data_arr,data_combined);--select which to out put

--get the tag with max counter to replaced based on LRU
  MAX_TAG_map : maxtag_select port map (tag_count_arr,max_tag);

--DATA buffer for data output
  data_register : register_n generic map (n => 512)
                             port map (clk,arst,rec_status,data_combined,data_recorded);
      
--select the source for data write to L1
  data_to_L1 : mux_n generic map (n => 512)
                     port map (DataInSrc,data_recorded,mem_data,DataToL1);

 

  

end structural;


