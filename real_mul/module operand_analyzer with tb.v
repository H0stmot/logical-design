module operand_analyzer (
    input [31:0] operand,
    output is_zero,
    output is_normalized,
    output is_denormalized,
    output is_infinity,
    output is_nan,
    output is_snan,      // Signaling NaN
    output is_qnan,      // Quiet NaN
    output sign          
);


    wire sign_bit = operand[31];
    wire [7:0] exponent = operand[30:23];
    wire [22:0] mantissa = operand[22:0];
    
    // Флаги для специальных случаев экспоненты
    wire exponent_all_zero = (exponent == 8'h00);
    wire exponent_all_one = (exponent == 8'hFF);
    wire exponent_normal = !exponent_all_zero && !exponent_all_one;
    
    // Флаги для мантиссы
    wire mantissa_all_zero = (mantissa == 23'h000000);
    wire mantissa_not_zero = (mantissa != 23'h000000);
    
    // Определение типов операндов
    assign is_zero = exponent_all_zero && mantissa_all_zero;
    assign is_denormalized = exponent_all_zero && mantissa_not_zero;
    assign is_normalized = exponent_normal;
    assign is_infinity = exponent_all_one && mantissa_all_zero;
    assign is_nan = exponent_all_one && mantissa_not_zero;
    
    // Определение типа NaN
    assign is_snan = is_nan && !mantissa[22];  // SNAN: старший бит мантиссы = 0
    assign is_qnan = is_nan && mantissa[22];   // QNAN: старший бит мантиссы = 1
    
    // Знак числа
    assign sign = sign_bit;

endmodule

module operand_analyzer_tb;
    reg [31:0] operand;
    wire is_zero, is_normalized, is_denormalized;
    wire is_infinity, is_nan, is_snan, is_qnan, sign;
    
    operand_analyzer uut (
        .operand(operand),
        .is_zero(is_zero),
        .is_normalized(is_normalized),
        .is_denormalized(is_denormalized),
        .is_infinity(is_infinity),
        .is_nan(is_nan),
        .is_snan(is_snan),
        .is_qnan(is_qnan),
        .sign(sign)
    );
    
    initial begin
        $display("Тестирование модуля анализа операндов");

        
        // Тест 1: Положительный ноль
        operand = 32'h00000000;
        #10;
        $display("+0: zero=%b, norm=%b, denorm=%b, inf=%b, nan=%b, sign=%b", 
                 is_zero, is_normalized, is_denormalized, is_infinity, is_nan, sign);
        
        // Тест 2: Отрицательный ноль
        operand = 32'h80000000;
        #10;
        $display("-0: zero=%b, norm=%b, denorm=%b, inf=%b, nan=%b, sign=%b", 
                 is_zero, is_normalized, is_denormalized, is_infinity, is_nan, sign);
        
        // Тест 3: Денормализованное число
        operand = 32'h00400000; // +1.17549435e-38 (денормализованное)
        #10;
        $display("Denorm: zero=%b, norm=%b, denorm=%b, inf=%b, nan=%b, sign=%b", 
                 is_zero, is_normalized, is_denormalized, is_infinity, is_nan, sign);
        
        // Тест 4: Нормализованное число
        operand = 32'h3F800000; // +1.0
        #10;
        $display("+1.0: zero=%b, norm=%b, denorm=%b, inf=%b, nan=%b, sign=%b", 
                 is_zero, is_normalized, is_denormalized, is_infinity, is_nan, sign);
        
        // Тест 5: Положительная бесконечность
        operand = 32'h7F800000;
        #10;
        $display("+Inf: zero=%b, norm=%b, denorm=%b, inf=%b, nan=%b, sign=%b", 
                 is_zero, is_normalized, is_denormalized, is_infinity, is_nan, sign);
        
        // Тест 6: Отрицательная бесконечность
        operand = 32'hFF800000;
        #10;
        $display("-Inf: zero=%b, norm=%b, denorm=%b, inf=%b, nan=%b, sign=%b", 
                 is_zero, is_normalized, is_denormalized, is_infinity, is_nan, sign);
        
        // Тест 7: Signaling NaN
        operand = 32'h7F800001; // SNaN
        #10;
        $display("SNaN: zero=%b, norm=%b, denorm=%b, inf=%b, nan=%b, snan=%b, qnan=%b", 
                 is_zero, is_normalized, is_denormalized, is_infinity, is_nan, is_snan, is_qnan);
        
        // Тест 8: Quiet NaN
        operand = 32'h7FC00000; // QNaN
        #10;
        $display("QNaN: zero=%b, norm=%b, denorm=%b, inf=%b, nan=%b, snan=%b, qnan=%b", 
                 is_zero, is_normalized, is_denormalized, is_infinity, is_nan, is_snan, is_qnan);
        
        $finish;
    end
endmodule