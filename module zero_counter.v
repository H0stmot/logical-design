module zero_counter
    #(parameter DATA_W = 8,
      parameter COUNT_W = 4
    )(
      input wire [DATA_W-1:0] data,
      output wire [COUNT_W-1:0] count
    );

// Флаг первая 1
wire found_one [0:DATA_W];
assign found_one[0] = 1'b0; 

wire [COUNT_W-1:0] cnt [0:DATA_W];
assign cnt[0] = 0;

genvar i;
generate
    for (i = 0; i < DATA_W; i = i + 1) begin
       
        assign found_one[i+1] = found_one[i] | (data[DATA_W-1 - i] == 1'b1);
        

        assign cnt[i+1] = (found_one[i] == 1'b0) ? 
                         (data[DATA_W-1 - i] == 0 ? cnt[i] + 1 : cnt[i]) : 
                         cnt[i];
    end
endgenerate

assign count = cnt[DATA_W];
endmodule
module tb;
    reg [7:0] data;
    wire [3:0] count;

    zero_counter dut (.data(data), .count(count));

    initial begin
        $monitor("data = %b | zeros = %0d", data, count);


        data = 8'b00000000; #10;  // 8
        data = 8'b00000001; #10;  // 7 
        data = 8'b00010000; #10;  // 3 
        data = 8'b00100100; #10;  // 2
        data = 8'b10000000; #10;  // 0 
        data = 8'b11111111; #10;  // 0 
        data = 8'b00000111; #10;  // 5 
        data = 8'b01000000; #10;  // 1 
        data = 8'b00100010; #10;  // 2
    end
endmodule