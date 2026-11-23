module tb_hamming_4bit;
    logic [3:0] my_data_in;
    logic [7:1] packed_wires;
    logic [7:1] corrupted_wires;
    logic [3:0] clean_data_out;
    logic [2:0] broken_wire;
    logic       error_fixed;

    // Connect your Packer
    hamming_encoder_4bit packer (
        .data_in  (my_data_in),
        .code_out (packed_wires)
    );

    // Connect your Healer
    hamming_decoder_4bit healer (
        .code_in     (corrupted_wires),
        .data_out    (clean_data_out),
        .broken_wire (broken_wire),
        .error_fixed (error_fixed)
    );

    initial begin
        // Test 1: Send 1011 with NO glitch
        my_data_in = 4'b1011;
        #1;
        corrupted_wires = packed_wires;
        #1;
        $display("TEST 1 (CLEAN)  -> Sent: %b | Broken Wire: %0d | Fixed: %b | Out: %b",
                 my_data_in, broken_wire, error_fixed, clean_data_out);

        // Test 2: Zap Wire 6 (flip bit 6 using XOR)
        corrupted_wires = packed_wires ^ 7'b0100000;
        #1;
        $display("TEST 2 (ZAP #6) -> Sent: %b | Broken Wire: %0d | Fixed: %b | Out: %b",
                 my_data_in, broken_wire, error_fixed, clean_data_out);

        $finish;
    end
endmodule