module tb_rr_arbiter_2port;
    logic       clk;
    logic       rst;
    logic [1:0] req;
    logic [1:0] grant;

    int i;

    rr_arbiter_2port dut (
        .clk   (clk),
        .rst   (rst),
        .req   (req),
        .grant (grant)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        rst = 1;
        req = 2'b00;
        @(posedge clk); #1;
        $display("rst   | req=%b grant=%b", req, grant);

        @(negedge clk);
        rst = 0;

        // single requests
        req = 2'b10;
        #1;
        $display("req1  | req=%b grant=%b", req, grant);
        @(posedge clk);

        @(negedge clk);
        req = 2'b01;
        #1;
        $display("req0  | req=%b grant=%b", req, grant);
        @(posedge clk);

        // both requesting, should alternate
        for (i = 0; i < 4; i++) begin
            @(negedge clk);
            req = 2'b11;
            #1;
            $display("both%0d | req=%b grant=%b", i, req, grant);
            @(posedge clk);
        end

        @(negedge clk);
        req = 2'b00;
        #1;
        $display("idle  | req=%b grant=%b", req, grant);
        @(posedge clk);

        $finish;
    end
endmodule


