module rr_arbiter_2port (
    input logic clk, //System clock 
    input logic rst, //Active-high synchronous reset 
    input logic [1:0] req, //Request lines: req[0] = Lane 0, req[1] = Lane 1 
    output logic [1:0] grant // One-hot grant: grant[0] = Lane 0 wins, grant [1] = Lane 1 wins 

);

//1-bit state register: 0 = Lane 0 has prioerity, 1 = Lane 1 has priority 
logic turn;


// Combinational grant logic: decide winner immediately based on req and turn 
always_comb begin
    grant = 2'b00; // Default: nobody wins 

    if (req == 2'b01) begin 
        grant = 2'b01; //Only Lane 0 is asking --> Lane 0 wins 
    end else if (req == 2'b10) begin 
        grant = 2'b10; //Only Lane 1 is asking --> Lane 1 wins 
    end else if (req == 2'b11) begin
        // Both lanes are asking so break the tie using turn 
        if (turn ==1'b0) begin 
            grant = 2'b01; //Lane 0's turn so Lane 0 wins 
        end else begin 
            grant = 2'b10; //Lane 1's turn so Lane 1 wins 
        end
    end
end 

//Synchronous state update: whoever just won has to give up priority for the next cycle 
always_ff @(posedge clk) begin
    if (rst) begin 
        turn <= 1'b0; //Default priority to Lane 0 on reset 
    end else begin 
        if (grant[0]) begin 
            turn <= 1'b1; //Lane 0 just went --> Lane 1 gets priority 
        end else if (grant[1]) begin 
            turn <= 1'b0; //Lane 1 just went --> Lane 0 gets priority 
        end 
    end 
end 

endmodule
