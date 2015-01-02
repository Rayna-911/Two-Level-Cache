Two Level Cache

Description:

Written in VHDL structural style. Only basic gates are allowed to use behavioral style.

The properties of these caches are as follows:
1KB L1 with 64B linesize (i.e., 16 cache lines), directmapped, writeback, write noallocate
4KB L2 with 256 linesize (i.e., 16 cache lines), 4way setassociative, LRU replacement, writethrough, write allocate with 64byte sub blocks (specifically, in case of write misses, the 64B subblock is fetched from memory, while in case of a read miss, the whole 256B line is fetched into the cache)

1. L1 Cache:
Opcode	hit_inc	miss_inc	cs	oe	we	is_dirty	enable_replace	record_Data
0100000	1	0	1	1	0	0	0	1
0000000	0	1	1	1	0	0	0	1
0010000	0	1	1	1	0	0	0	1
1100000	1	0	1	1	0	0	0	1
1000000	0	1	1	1	0	0	0	1
1010000	0	1	1	1	0	0	0	1
0000001	0	0	1	1	0	0	0	0
0001001	0	0	1	0	1	0	0	0
0000010	0	0	1	1	0	0	0	0
0001010	0	0	1	1	0	0	0	0
0000011	0	0	1	0	1	1	1	0
0001011	0	0	1	0	1	1	1	0
0000100	0	0	1	1	0	1	1	0
0001100	0	0	1	0	1	1	1	0
0000101	0	0	1	1	0	0	0	0
0001101	0	0	1	1	0	0	0	0

Opcode	DataSrc	DataInSrc	TagSrc	L2DataWr	request	ready	Next State
0100000	0	0	0	0	0	1	000
0000000	0	0	0	0	0	0	001
0010000	0	0	0	0	0	0	010
1100000	0	0	0	0	0	0	011
1000000	0	0	0	0	0	0	100
1010000	0	0	0	0	0	0	101
0000001	1	1	0	0	1	0	001
0001001	1	1	0	0	1	1	000
0000010	0	0	1	1	1	0	010
0001010	0	0	1	1	1	0	001
0000011	0	0	0	0	0	1	000
0001011	0	0	0	0	0	1	000
0000100	1	0	0	0	1	0	100
0001100	1	0	0	0	1	1	000
0000101	0	0	1	1	1	0	101
0001101	0	0	1	1	1	0	100


L1 cache has control unit, datapath unit, and a counter.

According to the current state, Wr, hit, dirty and done signal, we can analyze the other control signals and make them a truth table for the control signals. Then the control signals are inputs to the Datapath unit, where it can generate hit, dirty, Output data to CPU or L2 cache and address to L2 cache. Then Datapath inputs certain signals to Control to generate new control signals.

As requested, we need a counter to count the number of hit, miss and evict. For L1 cache, the original write hit and read hit are hits. And original write miss and read miss are misses. As for evict, it is ‘1’ only when there is a miss and the original data and address are not null, which are valid. 

For L1, there are 6 conditions. And different conditions have different control signals and next state.
Condition 0: read hit. Remain in state 0.
Condition 1: read miss (clean). Go to state 1.
Condition 2: read miss (dirty). Go to state 2.
Condition 3: write hit. Go to state 3.
Condition 4: write miss (clean). Go to state 4.
Condition 5: write miss (dirty). Go to sate 5.

State 0: Nothing to do.
State 1: Load data from L2 and output to CPU. Return state 0.
State 2: Write back to L2 then return state 1.
State 3: Update data and return state 0.
State 4: Load data from L2 and write data. Return state 0.
State 5: Write back to L2 and return state 4.
	
Input: 
Opcode(5): Wr or ’0’, depends on the state.
Opcode(4): hit or ‘0’ depends on the state
Opcode(3): dirty or ‘0’ depends on whether it is a hit, and on the state.
Opcode(2 down to 0): next state

2. L2 Cache:
L2 Control:
opcode	hit_inc	miss_inc	cs	oe	we	WrData
000000	0	0	1	0	0	0
101000	1	0	1	0	0	0
100000	0	1	1	1	0	0
111000	1	0	1	0	1	0
110000	0	1	1	0	1	0
000001	0	0	1	0	0	0
000010	0	0	1	1	0	1
000011	0	0	1	0	1	1
000100	0	0	1	0	1	0

Opcode	read_cache	checkback	rec_status	DataSrc	DataInSrc	done	Next state
000000	1	0	1	0	0	0	000
101000	1	0	1	0	0	0	001
100000	1	0	1	0	0	0	010
111000	1	0	1	0	0	0	011
110000	1	0	1	0	0	0	100
000001	0	1	0	0	0	1	000
000010	0	0	0	0	1	1	000
000011	0	0	0	1	0	1	000
000100	0	0	0	0	0	1	000


We divide the design into data path and control unit. Based on the properties above we divide the data path of second Level cache into basic unit for each set, LRU implementation, hit generation data output generation. For the basic unit for each set, we have RAM (sync_csram) for basic memory, tag compare for hit and LRU implement, write block for rebuild the data in a line. The basic structure of second level L2 is shown as following.

For the LRU implement, we add 32 bit as a counter to a line of the cache to store the number which is used to trace the times that a certain block did not been operated. Each time we read or write a line, we clear the counter to 0 and when we have a request while not touch a line, we will add 1 to the counter. In this way, a line with the largest counter is the line least recently used and there for we can evict it when we need to replace a line.

3. Memory:
The memory has a syn_cram, full_adder and a checker component.
To avoid x in the result, we use a checker to set 0 if the corresponding address has x value.