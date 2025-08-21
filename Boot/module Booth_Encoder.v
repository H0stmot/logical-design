module Booth_Encoder #(
    parameter WIDTH = 8
)(
    input  wire [WIDTH-1 : 0] multiplicand,
    input  wire [WIDTH-1 : 0] multiplier,
    output wire [WIDTH-1 : 0] valid_bit,
    output wire [WIDTH-1 : 0] sign_bit
);
    wire [WIDTH : 0] multiplier_extended = {multiplier, 1'b0};
    
    genvar index;

    generate
        for(index = WIDTH - 1; index > 0; index = index - 1)
        begin: encoder_loop
            assign valid_bit[index] = multiplier_extended[index] ^ multiplier_extended[index-1];
            assign sign_bit[index]  = multiplier_extended[index];
        end
    endgenerate

endmodule

module multiplier #(
    parameter WIDTH = 8
)(
    input  wire [WIDTH-1:0] operand_a,
    input  wire [WIDTH-1:0] operand_b,
    output wire [2*WIDTH-1:0] product_result
);
    wire [WIDTH-1:0] partial_valid;
    wire [WIDTH-1:0] partial_sign;

    Booth_Encoder #(.WIDTH(WIDTH)) booth_encoder_instance (
        .multiplicand(operand_a),
        .multiplier(operand_b),
        .valid_bit(partial_valid),
        .sign_bit(partial_sign)
    );

    wire [2*WIDTH-1:0] partial_product [0:WIDTH - 1]; 
    
    genvar idx;
    generate 
        for(idx = WIDTH-1; idx > 0; idx = idx - 1) begin: product_generation_loop
            assign partial_product[idx] = partial_valid[idx] ? 
                                         ({2*WIDTH{partial_sign[idx]}} ^ operand_a) + partial_sign[idx] << idx 
                                         : {2*WIDTH{1'b0}};
        end
    endgenerate
    
    wire [2*WIDTH-1:0] csa_input_a [0:5];
    wire [2*WIDTH-1:0] csa_input_b [0:5];
    wire [2*WIDTH-1:0] csa_input_c [0:5];
    wire [2*WIDTH-1:0] csa_output_sum [0:5];
    wire [2*WIDTH-1:0] csa_output_carry [0:5];

    // Подключения между Carry save adder блоками
    assign csa_input_a[0] = partial_product[0];
    assign csa_input_b[0] = partial_product[1];
    assign csa_input_c[0] = partial_product[2];
    
    assign csa_input_a[1] = partial_product[3];
    assign csa_input_b[1] = partial_product[4];
    assign csa_input_c[1] = partial_product[5];
    
    assign csa_input_a[2] = csa_output_sum[0];
    assign csa_input_b[2] = csa_output_carry[0];
    assign csa_input_c[2] = csa_output_sum[1];
    
    assign csa_input_a[3] = partial_product[6];
    assign csa_input_b[3] = partial_product[7];
    assign csa_input_c[3] = csa_output_carry[1];
    
    assign csa_input_a[4] = csa_output_sum[2];
    assign csa_input_b[4] = csa_output_carry[2];
    assign csa_input_c[4] = csa_output_sum[3];
    
    assign csa_input_a[5] = csa_output_sum[4];
    assign csa_input_b[5] = csa_output_carry[4];
    assign csa_input_c[5] = csa_output_carry[3];
    
    generate 
        for (idx = 0; idx < 6; idx = idx + 1) begin: csa_loop
            assign csa_output_sum[idx] = csa_input_a[idx] ^ csa_input_b[idx] ^ csa_input_c[idx];
            assign csa_output_carry[idx] = (csa_input_a[idx] & csa_input_b[idx] |
                                          csa_input_b[idx] & csa_input_c[idx] |
                                          csa_input_a[idx] & csa_input_c[idx]) << 1;
        end
    endgenerate

    // конечная сумма
    assign product_result = csa_output_sum[5] + csa_output_carry[5];
endmodule