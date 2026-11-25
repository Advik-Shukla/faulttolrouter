module rr_arbiter (
    input logic clk,
    input logic rst_n, 
    input logic [4:0] req,
    output logic [4:0] grant 
);
    logic [2:0] ptr; //who currently has the highest priority
    logic [2:0] next_ptr; // who gets the highest priority next cycle 

    integer i;
    integer idx;
    logic found;

    // 1. Combinational part: pick the first requesting port starting from ptr 
    always_comb begin
        grant = 5'b00000;
        next_ptr = ptr;
        found = 1'b0;

        for ( i = 0; i<5; i = i + 1 ) begin 
        // wrap around 0..4 
        if ( ptr + i >= 5)
            idx = ptr+i -5;
        else 
            idx = ptr + i;

        if (req[idx] && !found) begin
            grant[idx] = 1'b1;
            found = 1'b1;
            next_ptr = (idx ==4) ? 3'd0 : (idx + 3'd1);
        end
    end
end

// 2. Sequential: update priority pointer on clock edge 
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        ptr <= 3'd0;
    else if (|grant) 
        ptr <= next_ptr; 
    end 
endmodule


