module tb_fifo_4bit;
    logic       clk;
    logic       rst;
    logic       wr_en;
    logic       rd_en;
    logic [7:1] data_in;
    logic [7:1] data_out;
    logic       full;
    logic       empty;

    integer i;

    // Connect your FIFO
    fifo_4bit dut (
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
        rst = 1; wr_en = 0; rd_en = 0; data_in = 7'd0;
        @(posedge clk); #1;
        $display("RESET  | full=%b empty=%b", full, empty);

        @(negedge clk);
        rst = 0;

        // 2. Push 4 packets (values 1, 2, 3, 4) into the FIFO
        for (i = 1; i <= 4; i = i + 1) begin
            @(negedge clk);
            wr_en   = 1;
            data_in = i[6:0];
            @(posedge clk); #1;
            $display("PUSH %0d | full=%b empty=%b | front=%0d", i, full, empty, data_out);
        end

        @(negedge clk);
        wr_en = 0;

        // 3. Pop all 4 packets back out
        for (i = 1; i <= 4; i = i + 1) begin
            @(negedge clk);
            rd_en = 1;
            #1;
            $display("POP  %0d | got=%0d", i, data_out);
            @(posedge clk); #1;
        end

        @(negedge clk);
        rd_en = 0;
        $display("DONE   | full=%b empty=%b", full, empty);

        $finish;
    end
endmodule
