module tb_arbiter;
logic   clk;
logic   rst_n;
logic [4:0] req;
logic [4:0] grant;


rr_arbiter dut (
    .clk (clk),
    .rst_n (rst_n),
    .req (req),
    .grant (grant)

);

always #5 clk = ~clk;

initial begin 

    rst_n=0; 
    clk=0; 
    req = 5'b00000;

    #12;
    rst_n = 1;

    //test1: all 5 ports requesting 
    req = 5'b11111;
    repeat (6) begin 
        #1;
        $display ("req = %b | grant = %b", req, grant); 
        @(posedge clk);
     end 


    //test2: ports 1 and 3 requesting 
    req = 5'b01010;
    repeat (4) begin 
         #1;
         $display ("req = %b | grant = %b", req, grant); 
        @(posedge clk);
     end 

    //test3: no requests 
    req = 5'b00000;
    repeat (1) begin 
        #1;
        $display ("req = %b | grant = %b", req, grant); 
        @(posedge clk);
     end 

     $finish;
end
endmodule







