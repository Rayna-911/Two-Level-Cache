library ieee;
use ieee.std_logic_1164.all;
use work.eecs361_gates.all;

entity L2_Write is
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

end L2_Write;

architecture structural of L2_Write is
  
component fulladder_n is
  generic (
    n : integer);
  port (
    cin  : in  std_logic;
    x    : in  std_logic_vector(n-1 downto 0);
    y    : in  std_logic_vector(n-1 downto 0);
    cout : out std_logic;
    z    : out std_logic_vector(n-1 downto 0));
end component;

component mux_n is
  generic (
    n : integer);
  port (
    sel  : in  std_logic;
    src0 : in  std_logic_vector(n-1 downto 0);
    src1 : in  std_logic_vector(n-1 downto 0);
    z    : out std_logic_vector(n-1 downto 0));
end component;

component mux is
  port (
    sel : in std_logic;
    src0 : in std_logic;
    src1 : in std_logic;
    z : out std_logic);
end component;

component mux_4to1 is
  port (
       sel0,sel1 : in std_logic;
       src0,src1,src2,src3:	in	std_logic;
	   z	 : out std_logic
      );
end component mux_4to1;

component counter_sel is
  
  port (
    same   : in  std_logic;
    hit    : in  std_logic;
    is_max : in  std_logic;
    L2Wr   : in  std_logic;
    crst   : out std_logic);

end component counter_sel;

component Rebuild_data is
   port (
    base   : in  std_logic_vector(2051 downto 0);--original block data (64*8+1)*4=2052
    data   : in  std_logic_vector(512 downto 0);--data for replacement 64*8+1=513
    offset : in  std_logic_vector(1 downto 0);--sub block offest
    enable : in  std_logic;
    dout   : out std_logic_vector(2051 downto 0));

end component Rebuild_data;

signal c_1 : std_logic_vector(31 downto 0) := (0=>'1', others=>'0');--1 for counter+1
signal inc_counter : std_logic_vector(31 downto 0);
signal null_cout : std_logic;
signal count_reset : std_logic_vector(31 downto 0) := (others=>'0');
signal final_count : std_logic_vector(31 downto 0);
signal crst : std_logic;
signal tag_Src : std_logic;--select which tag to use
-- signal final_tag : std_logic_vector(tag_width-1 downto 0);
signal data_clear : std_logic_vector(2051 downto 0) := (others=>'0');--evict
signal base_data : std_logic_vector(2051 downto 0);
signal v_subblock : std_logic_vector(512 downto 0);--64*8+1=513
signal evict_tmp : std_logic;
signal enable_rebuild: std_logic;
signal replace_tmp : std_logic;

--signal for tag_Src generate
signal not_max : std_logic;
signal same_or_not_max : std_logic;
--signal for evict_tmp
signal not_same : std_logic;
signal valid_bit,evict_tmp2,evict_tmp3:std_logic;

begin  
  --tag assembler
    --tag_Src generate
    not_max_map        : not_gate port map ( is_max,not_max);
    or1_map            : or_gate port map (same,not_max,same_or_not_max);
    or2_map            : or_gate port map (same_or_not_max,L2Wr,tag_Src);
    --select tag
    tag_mux_map : mux_n generic map (n => 22) port map (tag_Src,addr_tag,cache_tag,dout(2105 downto 2084));

 --counter assembler
    --crst generate
    crst_map           : counter_sel port map (same,hit,is_max,L2Wr,crst);
    --counter+1
    adder_map          : fulladder_n generic map (n => 32) port map ('0',count,c_1,null_cout,inc_counter);
    --select counter
    counter_select_map : mux_n generic map (n => 32) port map (crst,inc_counter,count_reset,final_count);
    --output counter  
    dout(2083 downto 2052) <= final_count;

--data assembler
  --generate clear data signal evict_tmp
  inv_map : not_gate port map (same,not_same);
  and_map : and_gate port map (not_same,is_max,evict_tmp);
  --generate evict signal
  valid_bit_map: mux_4to1 port map ( blk_offset(0),blk_offset(1),cache_data(512),cache_data(1025),cache_data(1538),cache_data(2051),valid_bit);

  and_map1: and_gate port map (evict_tmp,enable_rebuild,evict_tmp2);
  evict_tmp3_map: and_gate port map (evict_tmp2,crst,evict);
  --evict_sign_map: and_gate port map (evict_tmp3,valid_bit,evict);
 --output evict
  --evict <= enable_rebuild;
  --evict block select
  evict_data_map : mux_n generic map (n => 2052) port map (evict_tmp,cache_data,data_clear,base_data);
  --data source select
  data_src_map : mux_n generic map (n => 512) port map (dataSrc,mem_data,L1_data,v_subblock(511 downto 0));
  --add valid data
  v_subblock(512) <= '1';
  --get rebuild enable
  rebuild_logic_mux : mux port map (same,is_max,'1',replace_tmp);
  enable_map        : and_gate port map (replace_tmp,WrData,enable_rebuild);
  rebuild_map : Rebuild_data port map (base_data,v_subblock,blk_offset,enable_rebuild,dout(2051 downto 0));
   

end structural;


