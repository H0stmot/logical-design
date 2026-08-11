`include "operand_analyzer.v"
`include "pre_res.v"
`include "rounding_module.v"
`include "exp_corr.v"

module real_mul #(
    // 0 = half (fp16, 1-5-10), 1 = single (fp32, 1-8-23), 2 = double (fp64, 1-11-52)
    parameter FORMAT = 0
)(
    input  wire        clk,
    input  wire        rst,
    input  wire [63:0] op1,
    input  wire [63:0] op2,
    output wire [63:0] result
);

    localparam EXP_W  = (FORMAT == 2) ? 11 : (FORMAT == 0) ? 5  : 8;
    localparam MANT_W = (FORMAT == 2) ? 52 : (FORMAT == 0) ? 10 : 23;
    localparam WIDTH  = EXP_W + MANT_W + 1;

    // Операнд каждого формата лежит в младших WIDTH битах шины
    wire [WIDTH-1:0] op_a = op1[WIDTH-1:0];
    wire [WIDTH-1:0] op_b = op2[WIDTH-1:0];

    // Проводники для специальных случаев
    wire [3:0] special_case;

    // Проводники для нормализованных операндов
    wire sign_a, sign_b;
    wire [EXP_W-1:0]  exp_a, exp_b;
    wire [MANT_W-1:0] mant_a, mant_b;

    // Проводники для умножения мантисс
    wire [2*MANT_W+1:0] mantissa_product;
    wire [MANT_W:0]      normalized_mant;
    wire [EXP_W-1:0]      product_exp;

    // Проводники для округления
    wire [MANT_W-1:0] rounded_mant;
    wire rounding_overflow, rounding_precision, rounding_no_rounding;

    // Анализ операндов и специальных случаев
    operation_analyzer #(
        .EXP_W(EXP_W),
        .MANT_W(MANT_W)
    ) analyzer (
        .op_a(op_a),
        .op_b(op_b),
        .special_case(special_case)
    );

    // Обработка специальных случаев
    wire [WIDTH-1:0] result_special;
    pre_res #(
        .EXP_W(EXP_W),
        .MANT_W(MANT_W)
    ) pre_result (
        .op_a(op_a),
        .op_b(op_b),
        .special_case(special_case),
        .result(result_special)
    );

    // Если есть специальный случай, используем результат из pre_res
    wire has_special_case = |special_case;

    // Извлечение компонентов для нормальных чисел
    assign sign_a = op_a[WIDTH-1];
    assign sign_b = op_b[WIDTH-1];
    assign exp_a  = op_a[WIDTH-2 -: EXP_W];
    assign exp_b  = op_b[WIDTH-2 -: EXP_W];
    assign mant_a = op_a[MANT_W-1:0];
    assign mant_b = op_b[MANT_W-1:0];

    // Добавление скрытых битов для нормализованных чисел
    wire a_is_normalized = (exp_a != 0);
    wire b_is_normalized = (exp_b != 0);

    wire [MANT_W:0] extended_mant_a = {a_is_normalized, mant_a};
    wire [MANT_W:0] extended_mant_b = {b_is_normalized, mant_b};

    // Умножение мантисс
    assign mantissa_product = extended_mant_a * extended_mant_b;

    wire need_normalization = mantissa_product[2*MANT_W+1];

    assign normalized_mant = need_normalization ?
                              mantissa_product[2*MANT_W+1:MANT_W+1] :
                              mantissa_product[2*MANT_W:MANT_W];

    // Коррекция экспоненты
    exp_corr #(
        .EXP_WIDTH(EXP_W),
        .MANT_WIDTH(MANT_W)
    ) exp_corrector (
        .overflow_flag(1'b0), // Пока не используется
        .mantissa_product(mantissa_product),
        .exponent_a(exp_a),
        .exponent_b(exp_b),
        .exponent_corrected(product_exp)
    );


    wire [MANT_W:0] remainder_bits = need_normalization ?
                                      mantissa_product[MANT_W:0] :
                                      {mantissa_product[MANT_W-1:0], 1'b0};

    wire [2*MANT_W+1:0] rounding_input;
    assign rounding_input = {normalized_mant, remainder_bits};

    // Округление
    rounding_module #(
        .MANT_W(MANT_W)
    ) rounder (
        .round_mode(2'b11), // Округление к ближайшему четному по умолчанию
        .input_value(rounding_input),
        .sign_bit(sign_a ^ sign_b),
        .rounded(rounded_mant),
        .precision_flag(rounding_precision),
        .overflow_flag(rounding_overflow),
        .no_rounding_flag(rounding_no_rounding)
    );

    // Формирование окончательного результата
    wire [WIDTH-1:0] normal_result = {
        sign_a ^ sign_b,    // Знак результата
        product_exp,        // Экспонента
        rounded_mant        // Мантисса
    };

    // Выбор результата: специальный случай или нормальный результат
    wire [WIDTH-1:0] single_result = has_special_case ? result_special : normal_result;

    assign result = {{(64-WIDTH){1'b0}}, single_result};

endmodule
