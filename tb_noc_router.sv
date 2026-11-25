`timescale 1ns/1ps

module tb_noc_router;

    // 1. Wires to connect to the router
    logic        clk = 0;
    logic        rst_n = 0;
    logic [38:0] in_data  [0:4];
    logic [4:0]  in_valid;
    logic [4:0]  in_ready;
    logic [38:0] out_data [0:4];
    logic [4:0]  out_valid;
    logic [4:0]  out_ready;
    logic [4:0]  err_single;
    logic [4:0]  err_double;

    // Clock ticks every 10ns
    always #5 clk = ~clk;

    // 2. Your router, sitting at grid spot (2, 2)
    noc_router #(.CUR_X(4'd2), .CUR_Y(4'd2)) dut (
        .clk(clk), .rst_n(rst_n),
        .in_data(in_data), .in_valid(in_valid), .in_ready(in_ready),
        .out_data(out_data), .out_valid(out_valid), .out_ready(out_ready),
        .err_single(err_single), .err_double(err_double)
    );

    // 3. Spare encoder/decoder 
    logic [31:0] pack_in;
    logic [38:0] pack_out;
    ecc_enc make_pkt (.data_in(pack_in), .code_out(pack_out));

    logic [38:0] check_in;
    logic [31:0] check_out;
    logic        unused_s, unused_d;
    ecc_dec read_pkt (.code_in(check_in), .data_out(check_out), .sec_err(unused_s), .ded_err(unused_d));

    // 4. The actual tests
    initial begin
        $dumpfile("router.vcd");
        $dumpvars(0, tb_noc_router);

        // Start clean: reset ON, all inputs 0, all outputs ready
        in_valid  = 5'b00000;
        out_ready = 5'b11111;
        for (int i = 0; i < 5; i++) in_data[i] = 0;

        rst_n = 0;
        @(posedge clk);
        @(posedge clk);
        rst_n = 1;
        @(posedge clk);

        // test 1: Normal packet (Local 0 -> East 3) 
        pack_in = {4'd3, 4'd2, 24'hCAFE01}; // dest (3,2) = East
        #1;
        in_data[0]  = pack_out;
        in_valid[0] = 1;
        @(posedge clk);
        in_valid[0] = 0;

        #1;
        check_in = out_data[3]; // read East output
        #1;
        $display("test1 (Routing):  out_valid[3]=%b | data=0x%h (expect CAFE01)", out_valid[3], check_out[23:0]);
        @(posedge clk);

        // test 2: 1-bit flip (West 4 --> Local 0) 
        pack_in = {4'd2, 4'd2, 24'hBEEF02}; // dest (2,2) = Local
        #1;
        in_data[4]    = pack_out;
        in_data[4][4] = ~in_data[4][4];     //  flip 1 bit
        in_valid[4]   = 1;
        @(posedge clk);
        in_valid[4]   = 0;

        #1;
        check_in = out_data[0]; // read Local output
        #1;
        $display("test2 (1-bit fix): err_single[4]=%b | data=0x%h (expect BEEF02)", err_single[4], check_out[23:0]);
        @(posedge clk);

        // test 3: 2-bit flip (North 1 -> South 2) 
        pack_in = {4'd2, 4'd1, 24'hDEAD03}; // dest (2,1) = South
        #1;
        in_data[1]    = pack_out;
        in_data[1][4] = ~in_data[1][4];     // flip bit 4
        in_data[1][5] = ~in_data[1][5];     // flip bit 5
        in_valid[1]   = 1;
        @(posedge clk);
        in_valid[1]   = 0;

        #1;
        $display("test 3 (2-bit det): err_double[1]=%b (expect 1)", err_double[1]);
        @(posedge clk);

        // test4: Collision (Local 0 & West 4 both -> East 3)
        pack_in = {4'd3, 4'd2, 24'h111111}; #1;
        in_data[0] = pack_out; in_valid[0] = 1;

        pack_in = {4'd3, 4'd2, 24'h222222}; #1;
        in_data[4] = pack_out; in_valid[4] = 1;

        @(posedge clk);
        in_valid = 5'b00000;

        #1; check_in = out_data[3]; #1;
        $display("test4 (Cycle 1):  East out_valid=%b | data=0x%h", out_valid[3], check_out[23:0]);

        @(posedge clk);
        #1; check_in = out_data[3]; #1;
        $display("test4 (Cycle 2):  East out_valid=%b | data=0x%h", out_valid[3], check_out[23:0]);

        @(posedge clk);
        $finish;
    end

endmodule