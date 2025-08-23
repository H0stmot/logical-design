module Booth_Encoder #(
    parameter WIDTH = 8
)(
    input  wire [WIDTH-1:0] multiplier,
    output wire [WIDTH/2:0] valid,  
    output wire [WIDTH/2:0] negative,
    output wire [WIDTH/2:0] twice
);

    wire [WIDTH:0] mult_ext = {multiplier, 1'b0};

    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 2) begin : encoder_block
            wire [2:0] bits_group = mult_ext[i+2:i];
            
            // Кодирование по алгоритму Бута
            assign valid[i/2] = (bits_group == 3'b000 || bits_group == 3'b111) ? 1'b0 : 1'b1;
            assign negative[i/2] = bits_group[2];
            assign twice[i/2] = (bits_group == 3'b011 || bits_group == 3'b100);
        end
    endgenerate

endmodule

module Booth_Multiplier #(
    parameter WIDTH = 8
)(
    input  wire [WIDTH-1:0] multiplicand,
    input  wire [WIDTH-1:0] multiplier,
    output wire [2*WIDTH-1:0] product
);
    assign product = multiplicand * multiplier;
endmodule

module tb_Booth_Encoder;
    parameter WIDTH = 8;
    
    reg [WIDTH-1:0] mult_in;
    wire [WIDTH/2:0] valid_out;
    wire [WIDTH/2:0] neg_out;
    wire [WIDTH/2:0] twice_out;
    
    Booth_Encoder #(.WIDTH(WIDTH)) encoder (
        .multiplier(mult_in),
        .valid(valid_out),
        .negative(neg_out),
        .twice(twice_out)
    );
    
    initial begin



        mult_in = 8'b00000000;
        #10;
        $display( mult_in, valid_out, neg_out, twice_out);
        

        mult_in = 8'b00000011;
        #10;
        $display(mult_in, valid_out, neg_out, twice_out);
        

        mult_in = 8'b00001100;
        #10;
        $display(mult_in, valid_out, neg_out, twice_out);
        

        mult_in = 8'b00100100;
        #10;
        $display(mult_in, valid_out, neg_out, twice_out);
        
        mult_in = 8'b10000001;
        #10;
        $display(mult_in, valid_out, neg_out, twice_out);
        
        $finish;
    end
endmodule

module tb_Booth_Multiplier;
    parameter WIDTH = 8;
    
    reg [WIDTH-1:0] mcand;
    reg [WIDTH-1:0] mplier;
    wire [2*WIDTH-1:0] prod;
    
    Booth_Multiplier #(.WIDTH(WIDTH)) multiplier (
        .multiplicand(mcand),
        .multiplier(mplier),
        .product(prod)
    );
    
    initial begin

        $display("mcand | mplier | product | expected");

        

        mcand = 5; mplier = 3;
        #10;
        $display(mcand, mplier, prod, 15);
        
        mcand = 10; mplier = 10;
        #10;
        $display(mcand, mplier, prod, 100);
        
        mcand = 0; mplier = 255;
        #10;
        $display(mcand, mplier, prod, 0);
        
        mcand = 1; mplier = 127;
        #10;
        $display(mcand, mplier, prod, 127);
        
        $finish;
    end
endmodule