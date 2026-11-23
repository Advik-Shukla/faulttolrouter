module ecc_dec (
    input logic [38:0] code_in,
    output logic [31:0] data_out,
    output logic        sec_err,
    output logic        ded_err

);

    integer i;
    integer d_idx;
    logic [5:0] syn;
    logic       overall_p;
    logic [38:0] fixed;

    always_comb begin
        syn = '0;
        fixed = code_in;
        sec_err = 1'b0;
        ded_err = 1'b0;
        d_idx = 0;
        data_out = '0;

        // 1. Recompute 6-bit syndrome across positions 1 to 38
        for ( i = 1; i <=38; i = i+1) begin
            if (i[0]) syn[0] = syn[0] ^ code_in[i];
            if (i[1]) syn[1] = syn[1] ^ code_in[i];
            if (i[2]) syn[2] = syn[2] ^ code_in[i];
            if (i[3]) syn[3] = syn[3] ^ code_in[i];
            if (i[4]) syn[4] = syn[4] ^ code_in[i];
            if (i[5]) syn[5] = syn[5] ^ code_in[i];
        end

        // 2. Overall parity across all 39 bits ( which includes po)
        overall_p = ^code_in; 

        // 3. SECDED error correction and identification
        if ( syn!= 6'd0 && overall_p == 1'b1) begin 
            // Single-bit error in bit positions 1..38
            sec_err = 1'b1;
            if (syn <= 6'd38) begin
                fixed[syn] = ~fixed[syn];
            end
        end else if ( syn ==6'd0 && overall_p == 1'b1) begin
            // Single-bit error in bit 0
            sec_err = 1'b1;
        end else if ( syn !=6'd0 && overall_p == 1'b0) begin
            // dounle-bit error ( uncorrectable)
            ded_err = 1'b1;
        end 

        // 4. Extract the 32 data bits from non power of 2 positions 
        for (i=1; i<= 38; i = i +1) begin
            if((i &(i-1)) != 0) begin
                data_out[d_idx] = fixed[i];
                d_idx = d_idx +1;
            end
        end
    end 
endmodule 



    
