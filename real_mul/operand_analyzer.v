module operand_analyzer #(
    parameter EXP_W  = 8,
    parameter MANT_W = 23
)(
    input  wire [EXP_W+MANT_W:0] operand,
    output wire                  is_zero,
    output wire                  is_normalized,
    output wire                  is_denormalized,
    output wire                  is_infinity,
    output wire                  is_nan,
    output wire                  is_snan,      // Signaling NaN
    output wire                  is_qnan,      // Quiet NaN
    output wire                  sign
);

    localparam WIDTH = EXP_W + MANT_W + 1;

    wire                sign_bit = operand[WIDTH-1];
    wire [EXP_W-1:0]    exponent = operand[WIDTH-2 -: EXP_W];
    wire [MANT_W-1:0]   mantissa = operand[MANT_W-1:0];

    // Флаги для специальных случаев экспоненты
    wire exponent_all_zero = (exponent == {EXP_W{1'b0}});
    wire exponent_all_one  = (exponent == {EXP_W{1'b1}});
    wire exponent_normal   = !exponent_all_zero && !exponent_all_one;

    // Флаги для мантиссы
    wire mantissa_all_zero = (mantissa == {MANT_W{1'b0}});
    wire mantissa_not_zero = (mantissa != {MANT_W{1'b0}});

    // Определение типов операндов
    assign is_zero         = exponent_all_zero && mantissa_all_zero;
    assign is_denormalized = exponent_all_zero && mantissa_not_zero;
    assign is_normalized   = exponent_normal;
    assign is_infinity     = exponent_all_one && mantissa_all_zero;
    assign is_nan          = exponent_all_one && mantissa_not_zero;

    // Определение типа NaN
    assign is_snan = is_nan && !mantissa[MANT_W-1]; // SNaN: старший бит мантиссы = 0
    assign is_qnan = is_nan &&  mantissa[MANT_W-1]; // QNaN: старший бит мантиссы = 1

    // Знак числа
    assign sign = sign_bit;

endmodule


// Модуль для анализа ДВУХ операндов и определения специальных случаев
module operation_analyzer #(
    parameter EXP_W  = 8,
    parameter MANT_W = 23
)(
    input  wire [EXP_W+MANT_W:0] op_a,
    input  wire [EXP_W+MANT_W:0] op_b,
    output wire [3:0]            special_case // [3]:NaN, [2]:0*inf, [1]:0*num, [0]:inf*num
);

    // Анализ операнда A
    wire a_zero, a_normalized, a_denormalized, a_infinity, a_nan, a_snan, a_qnan, a_sign;
    operand_analyzer #(
        .EXP_W(EXP_W),
        .MANT_W(MANT_W)
    ) analyzer_a (
        .operand(op_a),
        .is_zero(a_zero),
        .is_normalized(a_normalized),
        .is_denormalized(a_denormalized),
        .is_infinity(a_infinity),
        .is_nan(a_nan),
        .is_snan(a_snan),
        .is_qnan(a_qnan),
        .sign(a_sign)
    );

    // Анализ операнда B
    wire b_zero, b_normalized, b_denormalized, b_infinity, b_nan, b_snan, b_qnan, b_sign;
    operand_analyzer #(
        .EXP_W(EXP_W),
        .MANT_W(MANT_W)
    ) analyzer_b (
        .operand(op_b),
        .is_zero(b_zero),
        .is_normalized(b_normalized),
        .is_denormalized(b_denormalized),
        .is_infinity(b_infinity),
        .is_nan(b_nan),
        .is_snan(b_snan),
        .is_qnan(b_qnan),
        .sign(b_sign)
    );

    // Проверка на ноль (включая денормализованные нули)
    wire a_is_zero = a_zero || a_denormalized;
    wire b_is_zero = b_zero || b_denormalized;
    wire any_zero  = a_is_zero || b_is_zero;

    // Проверка на бесконечность
    wire any_infinity = a_infinity || b_infinity;

    // Проверка на NaN
    wire any_nan = a_nan || b_nan;

    // Определение специальных случаев
    assign special_case[3] = any_nan;                              // Case 1: NaN
    assign special_case[2] = any_zero && any_infinity && !any_nan;  // Case 2: 0 * inf
    assign special_case[1] = any_zero && !any_infinity && !any_nan; // Case 3: 0 * число
    assign special_case[0] = any_infinity && !any_zero && !any_nan; // Case 4: inf * число

endmodule
