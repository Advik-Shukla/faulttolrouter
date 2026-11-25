module xy_route #(
    parameter logic [3:0] CUR_X = 4'd0,
    parameter logic [3:0] CUR_Y = 4'd0
) ( 
    input logic     valid, 
    input logic [3:0] dest_x,
    input logic [3:0] dest_y,
    output logic [4:0] out_port

);
    always_comb begin
        out_port = 5'b00000;
        if(valid) begin 
            if (dest_x > CUR_X)
                out_port = 5'b01000; //EAST 
            else if (dest_x < CUR_X)
                out_port = 5'b10000; //WEST
            else if (dest_y > CUR_Y) 
                out_port = 5'b00010; //NORTH 
            else if (dest_y < CUR_Y)
                out_port = 5'b00100; //SOUTH 
            else 
                out_port = 5'b00001; //LOCAL 
            end 
        end
    endmodule
     