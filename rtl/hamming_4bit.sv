module hamming_encoder_4bit (
    input  logic [3:0] data_in, // 4 wires going IN ( numbered 3,2,1,0)
    output logic [7:1] code_out // 7 wires going OUT ( numbered 7,6,5,4,3,2,1)
);

    // First, Connect the 4 incoming data wires to output wires 3,5,6, 7 
        assign code_out[3] = data_in[0];
        assign code_out[5] = data_in[1];
        assign code_out[6] = data_in[2];
        assign code_out[7] = data_in[3];

    // Connect the 3 helper wires (1,2,4) via XOR gates 
        assign code_out[1] = data_in[0] ^ data_in[1] ^ data_in[3]; // XOR wires 3,5,7 
        assign code_out[2] = data_in[0] ^ data_in[2] ^ data_in[3]; //XOR wires 3,6,7
        assign code_out[4] = data_in[1] ^ data_in[2] ^ data_in[3]; // XOR wires 5,6,7 

endmodule

module hamming_decoder_4bit (
    input logic [7:1] code_in, // 7 wires coming IN from memory 
    output logic [3:0] data_out, // 4 clean, healed data bits going out 
    output logic [2:0] broken_wire, // 3-bit number telling the user which wire is broken ( 0 = none are broken )
    output logic       error_fixed // 1-bit alert flag: 1 if glitch was caught and fixed 

);

    // Internal wires inside the box 
    logic   c1, c2, c4; 
    logic [7:1] healed_code; 

    // This is used to run the 3 XOR check gates on the 7 incoming wires 
    assign c1 = code_in[1] ^ code_in[3] ^ code_in[5]^ code_in[7]; // Checks 1,3,5,7 
    assign c2 = code_in[2] ^ code_in[3] ^ code_in[6] ^ code_in[7]; // checks 2,3,6,7 
    assign c4 = code_in[4] ^ code_in[5] ^ code_in[6] ^ code_in[7]; //checks 4,5,6,7 

    // Tape {c4, c2, c1} side by side to spell the 3-bit broken wire number 
    assign broken_wire = {c4, c2, c1};

    // Turn on the alert flag if broken_wire is not 0 
    assign error_fixed = (broken_wire != 3'b000);

    // Heal the broken wire using combinational logic 
    always_comb begin
    healed_code = code_in; // Start by copying all 7 incoming wires 
    if ( broken_wire != 3'b000) begin
            healed_code[broken_wire] = ~code_in[broken_wire]; // Flip only the broken wire 
    end 
end 

// pull the 4 clean data bits back off wires 3,5,6,7 
assign data_out[0] = healed_code[3];
assign data_out[1] = healed_code[5];
assign data_out[2] = healed_code[6];
assign data_out[3] = healed_code[7];

endmodule

