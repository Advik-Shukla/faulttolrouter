module fifo_4bit (
    input logic clk,
    input logic rst, //reset button: clears all pointers back to 0 
    input logic wr_en, // write enable
    input logic rd_en, // read enable
    input logic [7:1] data_in, //7-wire bundle coming IN from the packer 
    output logic [7:1] data_out, //7-wire bundle going OUT to the healer 
    output logic full, // if 1  that means FIFO is full 
    output logic empty // 1 = FIF0 is empty 
);

    // 1. Storage array: 4 entries x 7 bits 
    logic [7:1] mem [0:3];

    //Circular buffer read/writepointers ( 2-bit counter wraps)
    logic [1:0] wr_ptr;
    logic [1:0] rd_ptr;

    // Occupancy counter (0..4)
    logic [2:0] count;

    //Status Flags 
    assign full = (count == 3'd4);
    assign empty = (count == 3'd0);

    //Gated write/read strobes to prevent overflow and underflow
    logic do_write, do_read;
    assign do_write = wr_en && !full;
    assign do_read = rd_en && !empty;

    // First-word fall through (FWFT): present oldest entry on data_out 
    assign data_out = mem[rd_ptr];

    // Synchronising pointer, memory and occupancy updates through clock 
    always_ff @(posedge clk) begin 
        if (rst) begin 
            wr_ptr <= 2'd0;
            rd_ptr <= 2'd0;
            count <= 3'd0;
        end else begin
            if (do_write) begin 
            mem[wr_ptr] <= data_in;
            wr_ptr <= wr_ptr + 2'd1;
            end 

            if (do_read) begin 
            rd_ptr <= rd_ptr + 2'd1;

            end 
            
            case ({do_write, do_read})
            2'b10: count<= count + 3'd1; // Write only 
            2'b01: count <= count -3'd1; //Read only
            default: count <= count; //idle or R/W together 

            endcase 
        end 
    end 
endmodule 

    

