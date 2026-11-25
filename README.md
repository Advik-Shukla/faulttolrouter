Fault-Tolerant 5-Port NOC Router
A network-on-chip router in SystemVerilog that fixes a flipped bit while a packet is in flight, and flags it when two bits flip, Packets are routed with XY Routing, collisions are settled by round-robin arbiters, and every packet carries a Hamming(39,32) SECDED code.

I'm a first-year ECE student at UIUC. Everything simulates in Icarus Verilog, and every block has its own testbench.

Workings:
--> Routes packets between 5 ports (Local, North, South, East, West) using XY routing
--> Heals any single flipped bit and raises err_single. All 39 bit positions are tested.
--> Flags any double flip with err_double 
--> Settles collisions fairly when two inputs want the same output
--> Supports backpressure with balid/ready: in_ready drops when a FIFO is full, and an output holds its packet when the neighbor isn't ready.

Why I built it:
Chips are full of tiny wires and memory cells, and sometimes a bit just flips. Noise, a particle strike etc can cause this. On a network-on-chip it matters more than one would initially think, because if the flipped bit lands in a packet's header, the packet goes to the wrong place. Server memory and caches deal with this using ECC. I wanted to build that idea into a router myself. 

How a packet moves:
A packet arrives on one of the five input ports as a 39-bit codeword and goes straight into that port’s FIFO, a small buffer that holds up to 4 packets, still encoded. When the packet reaches the front of the FIFO, the ECC decoder checks it. If one bit flipped, the decoder flips it back. If two flipped, it leaves the data alone and raises a flag. Either way, what comes out is the plain 32-bit packet.

The XY router then reads the destination coordinates from that decoded packet, compares them to the router’s own position, and decides which output port the packet wants. That request goes to the arbiter for that output port. Every output has its own arbiter, and if several inputs want the same output on the same cycle, the round-robin arbiter picks one and the rest wait in their FIFOs for another turn.
The winner’s packet goes through the crossbar, which is a 5-to-1 mux per output that connects the winning input to that output. Then the ECC encoder turns the 32-bit packet back into a fresh 39-bit codeword and it leaves the router, and the packet is removed from its FIFO.



All of this is stamped out five times once per input and once per output, so five packets headed for five different outputs can cross in the same cycle. 

Ports:
Local; Index 0; XY output code: 00001
North; Index 1; XY output code: 00010
South; Index 2; XY output code: 00100
East; Index 3; XY output code: 01000
West; Index 4; XY output code: 10000

The router sits at a coordinate set by the parameters CUR_X and CUR_Y. A packet goes East or West until its X matches, then North or South until its Y matches, then out the Local port. 

Packet format: 
Each packet is 32 bits, and the ECC encoder turns it into a 39-bit codeword with 32 data bits, 6 Hamming parity bits, 1 overall parity bit. 

Bits [31:28] correspond to dest_x which refers to the target X coordinate 
Bits [27:24] correspond to dest_y which refers to the target Y coordinate
Bits [23:0] correspond to payload which refers to the Data

Design Choices:
The decoder sits after the FIFO: The packet waits in the buffer as a full 39-bit codeword, so a flip that happens while it’s sitting there gets caught too, not just flips on the wire. On the way out it gets re-encoded, so the next router receives a fresh, valid codeword.

The destination is inside the protected word. Basically, a flipped bit in dest_x or dest_y is fixed before the reader reads it so that it doesn't send a packet the wrong way. 

SECDED instead of plain Hamming: Plain Hamming fixes one flipped bit, but if two bits flip it will "fix" the wrong bit and hand the user bad data with no warning. The extra overall parity bit lets the decoder tell the difference and flag the double error instead. 

XY Routing: It never turns from Y back to X, so it cannot create the circular waits that cause deadlocks. 

Round-Robin Arbiter, one per output: After a port 'wins', the priority pointer moves to the port right after it. No input is starved since every requester gets a turn within one full rotation. Giving each output its own arbiter is what lets different outputs move at the same time. 

Backpressure on both sides: As discussed earlier, in_ready tells the sender when the FIFO has room, and requestes to an output are muted when out_ready is low, so nothing gets sent into a full neighbor. 

## RTL Verification
'tb_noc_router.sv' tests the full router at '(2,2)' across 4 end-to-end scenarios: 
1. XY Routing: Sends OxCAFE01 from local -> East '(3,2)' and verifies clean exit on port 3 
2. Mid-Flight 1-Bit healing: Injects a single bit flip on West to Local. The router asserts 'err_single[4]' and still delivers the data completely intact.
3. 2-bit fault detection: Injects a double bit flip on North to South. The router immediately flags 'err_double[1]' 
4. Simultaneous port Collision: Slams 0x111111 (Local) and 0x222222 (West) into East on the exact same clock edge. The round-robin arbiter resolves the collision cleanly and outputs back-tback with zero drops. 

see docs/waveform.png for testbench results

other than this, each part has its own testbench as well
tb_arbiter.sv
tb_ecc.sv
tb_fifo.sv
tb_xy_route.sv


## SECDED Fault-Tolerance Analysis 
To map out where Hamming (39,32) shines and where it breaks down, 'scripts/ecc_analysis.py' runs a Monte Carlo sweep of 10,000 30-bit flits per Bit Error Rate (BER)
BER (%)    Clean (%)  1-bit heal   2-bit heal   3+ Uncorr 
0.1        9623       370.0        7            0         
0.5        8269       1559.0       166          6         
1.0        6743       2673.0       513          71        
2.0        4553       3634.0       1370         443       
3.0        3057       3713.0       2095         1135      
5.0        1422       2770.0       2758         3050      
Plot saved as 'docs/ecc_ber_curve.png'

At 1% BER, about 32% of words take atleast 1 hit. With SECDED, 6743 arrive clean, 2673 are healed, and 513 are flagged instead of passed along wrong. Only the 71 words with 3 or more flips are outside what the code can handle. At 5% BER, the 3+ bucket is the biggest one, which is the point where a stronger code (BCH, for example) would be worth. 

What this does and doesn't show. The script is a statistical model of how many bits flip. It does not run my RTL. The hardware side of the claim is tb_ecc.sv, which flips all 39 positions one at a time and checks each one heals. 

Run It: 
A user who wants to run this repo needs Icarus Verilog (I used 13.0). For the analysis script you also need Python 3 and matplotlib
# full router, end to end (writes router.vcd for a waveform viewer)
iverilog -g2012 -o sim_router.out rtl/fifo.sv rtl/ecc_enc.sv rtl/ecc_dec.sv rtl/rr_arbiter.sv rtl/xy_route.sv rtl/noc_router.sv tb_noc_router.sv && vvp sim_router.out

# individual blocks
iverilog -g2012 -o ecc_sim.out rtl/ecc_enc.sv rtl/ecc_dec.sv tb_ecc.sv && vvp ecc_sim.out
iverilog -g2012 -o fifo_sim.out rtl/fifo.sv tb_fifo.sv && vvp fifo_sim.out
iverilog -g2012 -o arb_sim.out rtl/rr_arbiter.sv tb_arbiter.sv && vvp arb_sim.out
iverilog -g2012 -o xy_sim.out rtl/xy_route.sv tb_xy_route.sv && vvp xy_sim.out

# noise analysis
pip3 install matplotlib
python3 scripts/ecc_analysis.py

Icarus prints some sorry: constant selects in always_* warnings. But they are harmless and do not affect the simulation. 

Extensions of this project: 

No Synthesis: I have yet to run this through Yosys or Vivado, so I have no area or click-speed numbers. Everything between the FIFO and the output is combinational, so one pipeline register before the encoder is the first thing I'd try. 
No built-in self test: An on-chip FSM that injects known faults at startup is in progress and will be implemented soon
No retransmit: A double error is flagged, but nothing resends the packet. This could also be a possible extension that would live a layer above the router. 

Hurdles:
My first ECC testbench printed PASS while reading x values. At time zero the encoder hasn't settled yet, and != treats an x comparison as false, so the check never fired. Switchign to !=== and adding a #1 fixed the issye. 

The FIFO uses an active-high reset and the router uses an active-low reset, so the FIFO gets .rst(~rst_n). Port names that didn't match across my older modules also took a few rounds of compile errors to sort out. 






----------------------------------------------------------Built By Advik Shukla, Computer Engineer @ UIUC-------------------------------------------------------------------------------------------


