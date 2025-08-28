module rounding_module (
    input wire [1:0] round_mode,          // Режим округления
    input wire [TOTAL_WIDTH-1:0] input_value,  // Входное значение
    input wire sign_bit,                  // Знаковый бит (отдельный вход)
    output wire [HIGH_PART_WIDTH-1:0] rounded, // Округленное значение
    output wire precision_flag,           // Флаг точности
    output wire overflow_flag,            // Флаг переполнения
    output wire no_rounding_flag          // Флаг отсутствия округления
);

    parameter IS_DOUBLE = 0;
    parameter HIGH_PART_WIDTH = (IS_DOUBLE) ? 52 : 23;
    parameter LOW_PART_WIDTH = (IS_DOUBLE) ? 53 : 24;
    parameter TOTAL_WIDTH = (IS_DOUBLE) ? 106 : 48;
    
    wire increment_needed;                // Нужен ли инкремент
    wire [HIGH_PART_WIDTH-1:0] high_part; // Основная часть числа
    wire [LOW_PART_WIDTH-1:0] low_part;   // Младшие биты для округления
    wire [HIGH_PART_WIDTH-1:0] incremented_value; // Значение после инкремента
    wire overflow_detected;               // Обнаружено переполнение
    
    // Разделение числа на основную и дробную части
    assign high_part = input_value[TOTAL_WIDTH-1:LOW_PART_WIDTH];
    assign low_part = input_value[LOW_PART_WIDTH-1:0];
    
    // Вычисление инкремента для каждого режима округления
    wire increment_zero;      // Округление к нулю
    wire increment_pinf;      // Округление к +inf
    wire increment_ninf;      // Округление к -inf
    wire increment_nearest;   // Округление к ближайшему четному
    
    // Округление к нулю
    assign increment_zero = 1'b0;
    
    // Округление к +inf - инкремент если положительное число и есть дробная часть
    assign increment_pinf = (!sign_bit) && (|low_part);
    
    // Округление к -inf - инкремент если отрицательное число и есть дробная часть
    assign increment_ninf = sign_bit && (|low_part);
    
    // Округление к ближайшему четному

    wire msb_guard = low_part[LOW_PART_WIDTH-1];
    wire other_guard_bits = |low_part[LOW_PART_WIDTH-2:0];
    wire lsb_high = high_part[0];
    assign increment_nearest = msb_guard && (other_guard_bits || lsb_high);
    
    // Выбор инкремента на основе режима округления
    assign increment_needed = 
        (round_mode == 2'b00) ? increment_zero :
        (round_mode == 2'b01) ? increment_pinf :
        (round_mode == 2'b10) ? increment_ninf :
        increment_nearest;
    
    // Вычисление инкрементированного значения
    assign incremented_value = high_part + increment_needed;
    
    // Проверка на переполнение (все биты high_part равны 1 и есть инкремент)
    assign overflow_detected = (&high_part) && increment_needed;
    
    // Финальное округленное значение

    assign rounded = overflow_detected ? 
                     {1'b0, {(HIGH_PART_WIDTH-1){1'b1}}} : 
                     incremented_value;
    
    // Флаги
    assign precision_flag = (low_part == {LOW_PART_WIDTH{1'b0}});  // Нет дробной части
    assign overflow_flag = overflow_detected;
    assign no_rounding_flag = !increment_needed;      // Округления не было

endmodule


module rounding_module_tb;
    // Параметры для одинарной точности
    parameter IS_DOUBLE = 0;
    parameter HIGH_PART_WIDTH = (IS_DOUBLE) ? 52 : 23;
    parameter LOW_PART_WIDTH = (IS_DOUBLE) ? 53 : 24;
    parameter TOTAL_WIDTH = (IS_DOUBLE) ? 106 : 48;
    
    reg [1:0] round_mode;
    reg [TOTAL_WIDTH-1:0] input_value;
    reg sign_bit;
    wire [HIGH_PART_WIDTH-1:0] rounded;
    wire precision_flag, overflow_flag, no_rounding_flag;
    
    // Экземпляр модуля округления
    rounding_module #(
        .IS_DOUBLE(IS_DOUBLE),
        .HIGH_PART_WIDTH(HIGH_PART_WIDTH),
        .LOW_PART_WIDTH(LOW_PART_WIDTH),
        .TOTAL_WIDTH(TOTAL_WIDTH)
    ) uut (
        .round_mode(round_mode),
        .input_value(input_value),
        .sign_bit(sign_bit),
        .rounded(rounded),
        .precision_flag(precision_flag),
        .overflow_flag(overflow_flag),
        .no_rounding_flag(no_rounding_flag)
    );
    
    initial begin
        // Тестирование для одинарной точности
        $display("Testing single precision rounding...");
        
        // Тест 1: Округление к нулю
        round_mode = 2'b00;
        sign_bit = 0;
        input_value = 48'h7FFFFF800000; // Максимальное значение с дробной частью
        #10;
        $display("Zero rounding: %h -> %h", input_value, rounded);
        
        // Тест 2: Округление к +inf
        round_mode = 2'b01;
        sign_bit = 0;
        input_value = 48'h000001C00000; // Значение с дробной частью
        #10;
        $display("+Inf rounding: %h -> %h", input_value, rounded);
        
        // Тест 3: Округление к -inf
        round_mode = 2'b10;
        sign_bit = 1;
        input_value = 48'h000001C00000; // Отрицательное с дробной частью
        #10;
        $display("-Inf rounding: %h -> %h", input_value, rounded);
        
        // Тест 4: Округление к ближайшему четному
        round_mode = 2'b11;
        sign_bit = 0;
        input_value = 48'h000001600000; // Значение для проверки округления к четному
        #10;
        $display("Nearest even: %h -> %h", input_value, rounded);
        
        // Тест 5: Проверка переполнения
        round_mode = 2'b01;
        sign_bit = 0;
        input_value = {23'h7FFFFF, 25'h1FFFFFF}; // Максимальное значение + инкремент
        #10;
        $display("Overflow test: %h -> %h, overflow: %b", input_value, rounded, overflow_flag);
        
        $finish;
    end
endmodule