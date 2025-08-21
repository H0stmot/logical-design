module prioritet_shifrator // для 8 бит
    #(parameter DATA_W = 8,
    parameter POS_W = $clog2(DATA_W))
    (input wire [DATA_W-1:0] data,
    output wire [POS_W-1:0] position);

wire [POS_W-1:0] pos[DATA_W-1:0];
assign pos[0] = {POS_W{1'b0}};

genvar i;
generate
    for (i = 0; i < DATA_W; i = i + 1) begin
        assign pos[i+1] = data[i] ? i[POS_W-1:0] : pos[i];
    end
endgenerate

assign position = pos[DATA_W];
endmodule






module tb;
    reg [7:0] data;
    wire [2:0] position;
    
    prioritet_shifrator 
    #(.DATA_W(8)) dut (.data(data), .position(position));
    
    initial begin
        $monitor("%b    %b", data, position);

        data = 8'b00000000; #10;  // 000
        data = 8'b00000001; #10;  // 000
        data = 8'b00010000; #10;  // 100
        data = 8'b00100100; #10;  // 101
        data = 8'b10000000; #10;  // 111
        data = 8'b11111111; #10;  // 111
    
    end
endmodule


module prioritet_shifrator   // для 16 бит
    #(parameter DATA_W = 16,
      parameter POS_W = $clog2(DATA_W))
    (input wire [DATA_W-1:0] data,
     output wire [POS_W-1:0] position);

    wire [POS_W-1:0] pos[DATA_W:0];
    assign pos[0] = {POS_W{1'b0}};

    genvar i;
    generate
        for (i = 0; i < DATA_W; i = i + 1) begin
            assign pos[i+1] = data[i] ? i[POS_W-1:0] : pos[i];
        end
    endgenerate

    assign position = pos[DATA_W];
endmodule

module tb;
    reg [15:0] data;
    wire [3:0] position;
    
    prioritet_shifrator dut(.data(data), .position(position));
    
    initial begin
        $monitor("%b   %b", data, position);

        data = 16'b0000000000000000; #10;  // 0000
        data = 16'b0000000000000001; #10;  // 0000
        data = 16'b0000000000010000; #10;  // 0100 
        data = 16'b0000000100100000; #10;  // 1001 
        data = 16'b0001000000000000; #10;  // 1100 
        data = 16'b1000000000000000; #10;  // 1111 
        data = 16'b1111111111111111; #10;  // 1111 
        data = 16'b0010001000100010; #10;  // 1101 
        
    end
endmodule