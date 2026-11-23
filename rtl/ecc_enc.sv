module ecc_enc (
    input logic [31:0] data_in,
    output logic [38:0] code_out

);
    integer i;
    integer d_idx;
    logic [38:0] cw;

    always_comb begin
        cw = '0;
        d_idx = 0;

        // mapping the 32 bits into non-power-of-2 positions 
        for (i = 1; i<=38; i = i+1) begin
            if ((i&(i-1)) != 0) begin
                cw[i] = data_in[d_idx];
                d_idx = d_idx+ 1;
            end
        end
     

        // hamming parity bits at powers of 2 
        for (i = 1; i<= 38; i = i + 1) begin 
            if (i[0]) cw[1] = cw[1] ^ cw[i];
            if (i[1]) cw[2] = cw[2] ^ cw[i];
            if (i[2]) cw[4] = cw[4] ^ cw[i];
            if (i[3]) cw[8] = cw[8] ^ cw[i];
            if (i[4]) cw[16] = cw[16] ^ cw[i];
            if (i[5]) cw[32] = cw[32] ^ cw[i];
        end
    

        //overall parity bit 
        cw[0] = ^cw[38:1];

        code_out = cw;
    end
endmodule 
