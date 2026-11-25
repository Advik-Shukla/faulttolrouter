module noc_router #(
    parameter logic [3:0] CUR_X = 4'd0,
    parameter logic [3:0] CUR_Y = 4'd0
) ( 
    input logic clk,
    input logic rst_n, 

    // 5 Input ports ( Local, 1: North, 2: South, 3: East, 4: West)
    input logic [38:0] in_data [0:4],
    input logic [4:0] in_valid,
    output logic [4:0] in_ready, 


    //5 Output ports 
    output logic [38:0] out_data [0:4],
    output logic [4:0] out_valid, 
    input logic [4:0] out_ready,

    //ECC error flags (per input port)
    output logic [4:0] err_single,
    output logic [4:0] err_double

); 

    // Internal wires
    logic [38:0] fifo_dout [0:4];
    logic [4:0] fifo_full;
    logic [4:0] fifo_empty;
    logic [4:0] fifo_wr_en;
    logic [4:0] fifo_rd_en;

    logic [31:0] dec_data [0:4]; // To clean 32-bit data after ECC decoding 
    logic [4:0] xy_req [0:4]; //xy_req[in][out]

    logic [4:0] arb_req [0:4]; //arb_req[out][in] *transposed 
    logic [4:0] arb_grant [0:4]; // arb_grant[out][in]

    logic [31:0] xbar_data [0:4]; //Crossbar winner data per output 

    //1. Input pipelines: FIFO --> ECC Decode --> XY Toute 
    genvar i; 
    generate 
    for ( i = 0; i <5; i = i+1) begin : gen_in 
        assign in_ready[i] = ~fifo_full[i];
        assign fifo_wr_en[i] = in_valid[i] & in_ready[i];

        //pop fifo if ANY output arbiter granted this input port 
        assign fifo_rd_en[i] = arb_grant[0][i] | arb_grant[1][i] | arb_grant[2][i] | arb_grant[3][i] | arb_grant[4][i]; 

        fifo u_fifo (
            .clk (clk),
            .rst (~rst_n),
            .wr_en (fifo_wr_en[i]),
            .rd_en (fifo_rd_en[i]),
            .data_in (in_data[i]),
            .data_out (fifo_dout[i]), 
            .full (fifo_full[i]),
            .empty (fifo_empty[i])

        );
        ecc_dec u_ecc_dec (
            .code_in (fifo_dout[i]),
            .data_out (dec_data[i]),
            .sec_err (err_single[i]),
            .ded_err (err_double[i])
        );


        xy_route #(
            .CUR_X (CUR_X),
            .CUR_Y (CUR_Y)

        ) u_xy ( 
            .valid ( ~fifo_empty[i]),
            .dest_x (dec_data[i][31:28]),
            .dest_y (dec_data[i][27:24]),
            .out_port (xy_req[i])

        );
    end
endgenerate


    //2. Output Piplelines: Transpore--> Arbiter --> Cross bar --> ECC Encode 

    genvar o;
    generate 
    for ( o = 0; o < 5; o = o + 1) begin : gen_out 
        // Wire transpose + gate with out_ready ( dont grant if downstream is full)

        assign arb_req[o][0] = xy_req[0][o] & out_ready[o];
        assign arb_req[o][1] = xy_req[1][o] & out_ready[o];
        assign arb_req[o][2] = xy_req[2][o] & out_ready[o];
        assign arb_req[o][3] = xy_req[3][o] & out_ready[o];
        assign arb_req[o][4] = xy_req[4][o] & out_ready[o];

        rr_arbiter u_arb ( 
            .clk (clk), 
            .rst_n (rst_n),
            .req (arb_req[o]),
            .grant (arb_grant[o])
        );

        // 5-to-1 Mux 
        always_comb begin 
            xbar_data[o] = 32'd0;
            if (arb_grant[o][0]) xbar_data[o] = dec_data[0];
            else if (arb_grant[o][1]) xbar_data[o] = dec_data[1];
            else if (arb_grant[o][2]) xbar_data[o] = dec_data[2];
            else if (arb_grant[o][3]) xbar_data[o] = dec_data[3];
            else if (arb_grant[o][4]) xbar_data[o] = dec_data[4];
        end 

        //Output is valid whenever any input won this particular output port 
        assign out_valid[o] = | arb_grant[o];

        ecc_enc u_ecc_enc (
            .data_in (xbar_data[o]),
            .code_out (out_data[o])

        );
    end
    endgenerate
endmodule 



            










