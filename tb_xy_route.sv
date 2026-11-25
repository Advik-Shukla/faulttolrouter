module tb_xy_route;
logic valid;
logic [3:0] dest_x;
logic [3:0] dest_y;
logic [4:0] out_port;

//Place this router at origin say (2,2)
 xy_route #(
    .CUR_X(4'd2),
    .CUR_Y(4'd2)

 ) dut ( 
    .valid (valid),
    .dest_x (dest_x),
    .dest_y (dest_y),
    .out_port (out_port)
 );

 initial begin 
    // EAST: dest_x> 2 --> expect 01000
    valid = 1; dest_x = 4'd3; dest_y = 4'd2; #5;
        $display("East  (3,2) | valid=%b | out_port=%b", valid, out_port);
    //WEST: dest_x < 2 --> expect 10000
    valid = 1; dest_x = 4'd1; dest_y = 4'd2; #5;
        $display("West  (1,2) | valid=%b | out_port=%b", valid, out_port);
    //NORTH: dest_x ==2, dest_y > 2 --> expect 00010
    valid = 1; dest_x = 4'd2; dest_y = 4'd3; #5;
        $display("North  (2,3) | valid=%b | out_port=%b", valid, out_port);
    //SOUTH: dest_x ==2, dest_y < 2 --> expect 00100
    valid = 1; dest_x = 4'd2; dest_y = 4'd1; #5;
        $display("South  (2,1) | valid=%b | out_port=%b", valid, out_port);
    //LOCAL: at origin --> expect 00001
    valid = 1; dest_x = 4'd2; dest_y = 4'd2; #5;
        $display("Local  (2,2) | valid=%b | out_port=%b", valid, out_port);
    //DIAGONAL: X goes first --> expect east (01000)
    valid = 1; dest_x = 4'd3; dest_y = 4'd3; #5;
        $display("Diagonal  (3,3) | valid=%b | out_port=%b", valid, out_port);
    //INVALID: valid == 0 --> expect 00000 regardless of dest 
    valid = 0; dest_x = 4'd3; dest_y = 4'd3; #5;
        $display("Invalid  (3,3) | valid=%b | out_port=%b", valid, out_port);

        $finish;
    end
endmodule



    

