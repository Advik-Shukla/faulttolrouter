module fifo #(
    parameter WIDTH = 39,
    parameter DEPTH = 4
) (
    input logic clk,
    input logic rst, //reset button: clears all pointers back to 0 
    input logic wr_en, // write enable
    input logic rd_en, // read enable
    input logic [WIDTH-1:0] data_in, //wire bundle coming IN from the packer 
    output logic [WIDTH-1:0] data_out, //wire bundle going OUT to the healer 
    output logic full, // if 1  that means FIFO is full 
    output logic empty // 1 = FIF0 is empty 
);
    localparam PTR_W = $clog2(DEPTH);

    // 1. Storage array: DEPTH X WIDTH 
    logic [WIDTH-1:0] mem [0: DEPTH-1];

    //Circular buffer read/writepointers 0..DEPTH
    logic [PTR_W-1:0] wr_ptr;
    logic [PTR_W-1:0] rd_ptr;

    // Occupancy counter (0..4)
    logic [PTR_W:0] count;

    //Status Flags 
    assign full = (count == DEPTH);
    assign empty = (count == 0);

    //Gated write/read strobes to prevent overflow and underflow
    logic do_write, do_read;
    assign do_write = wr_en && !full;
    assign do_read = rd_en && !empty;

    // First-word fall through (FWFT): present oldest entry on data_out 
    assign data_out = mem[rd_ptr];

    // Synchronising pointer, memory and occupancy updates through clock 
    always_ff @(posedge clk) begin 
        if (rst) begin 
            wr_ptr <= '0;
            rd_ptr <= '0;
            count <= '0;
        end else begin
            if (do_write) begin 
            mem[wr_ptr] <= data_in;
            wr_ptr <= wr_ptr + 1'b1;
            end 

            if (do_read) begin 
            rd_ptr <= rd_ptr + 1'b1;

            end 
            
            case ({do_write, do_read})
            2'b10: count<= count + 1'b1; // Write only 
            2'b01: count <= count -1'b1; //Read only
            default: count <= count; //idle or R/W together 

            endcase 
        end 
    end 
endmodule 

    

