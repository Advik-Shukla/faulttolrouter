module tb_fifo;
    logic       clk;
    logic       rst;
    logic       wr_en;
    logic       rd_en;
    logic [38:0] data_in;
    logic [38:0] data_out;
    logic       full;
    logic       empty;

    integer i;

    // Connect your FIFO
    fifo #(.WIDTH(39), .DEPTH(4)) dut (
        .clk      (clk),
        .rst      (rst),
        .wr_en    (wr_en),
        .rd_en    (rd_en),
        .data_in  (data_in),
        .data_out (data_out),
        .full     (full),
        .empty    (empty)
    );

    // Metronome: flip clk every 5ns (10ns full cycle)
    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        // 1. Reset the FIFO
        rst = 1; wr_en = 0; rd_en = 0; data_in = '0;
        @(posedge clk); #1;
        $display("RESET  | full=%b empty=%b", full, empty);

        @(negedge clk);
        rst = 0;

        // 2. Push 4 packets (values 1, 2, 3, 4) into the FIFO
        for (i = 1; i <= 4; i = i + 1) begin
            @(negedge clk);
            wr_en   = 1;
            data_in = 39'h5A_0000_0000 + i;
            @(posedge clk); #1;
            $display("PUSH %0d | full=%b empty=%b | front=%h", i, full, empty, data_out);
        end

        @(negedge clk);
        wr_en = 0;

        // 3. Pop all 4 packets back out
        for (i = 1; i <= 4; i = i + 1) begin
            @(negedge clk);
            rd_en = 1;
            #1;
            $display("POP  %0d | got=%h", i, data_out);
            @(posedge clk); #1;
        end

        @(negedge clk);
        rd_en = 0;
        $display("DONE   | full=%b empty=%b", full, empty);

        $finish;
    end
endmodule
