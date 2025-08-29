module real_mul_tb;

    // Тактовый сигнал и сброс
    reg clock;
    reg rst;

    // Операнды и результаты
    reg [63:0] op_a;
    reg [63:0] op_b;
    wire [63:0] res_hw;

    // Ожидаемый результат
    reg [63:0] res_eth;
    real real_a, real_b, real_res;

    // Счетчик тестов
    integer test_counter;
    integer error_count;

    // Генерация тактового сигнала
    initial begin
        clock = 0;
        forever #10 clock = ~clock;
    end

    // Инициализация
    initial begin
        rst = 1;
        test_counter = 0;
        error_count = 0;
        op_a = 64'b0;
        op_b = 64'b0;
        res_eth = 64'b0;
        
        #25 rst = 0;
        
        // Тест 1: 1.0 * 1.0 = 1.0 (single precision)
        #20;
        op_a = 64'h000000003F800000; // 1.0 в float
        op_b = 64'h000000003F800000; // 1.0 в float
        test_counter = 1;
        
        // Тест 2: 2.0 * 2.0 = 4.0 (single precision)
        #40;
        op_a = 64'h0000000040000000; // 2.0 в float
        op_b = 64'h0000000040000000; // 2.0 в float
        test_counter = 2;
        
        // Тест 3: 1.5 * 2.0 = 3.0 (single precision)
        #40;
        op_a = 64'h000000003FC00000; // 1.5 в float
        op_b = 64'h0000000040000000; // 2.0 в float
        test_counter = 3;
        
        // Тест 4: Double precision (если поддерживается)
        #40;
        op_a = 64'h3FF0000000000000; // 1.0 в double
        op_b = 64'h3FF0000000000000; // 1.0 в double
        test_counter = 4;
        
        #60;
        if (error_count == 0) begin
            $display("All tests PASSED!");
        end else begin
            $display("Tests completed with %d errors", error_count);
        end
        $finish;
    end

    // Подключение тестируемого модуля (single precision по умолчанию)
    real_mul #(
        .IS_DOUBLE(0)  
    ) dut (
        .clk(clock),
        .rst(rst),
        .op1(op_a),
        .op2(op_b),
        .result(res_hw)
    );

    // Вычисление ожидаемого результата
    always @(*) begin
        // Для single precision используем младшие 32 бита
        real_a = $bitstoshortreal(op_a[31:0]);
        real_b = $bitstoshortreal(op_b[31:0]);
        real_res = real_a * real_b;
        res_eth = {32'b0, $shortrealtobits(real_res)};
    end

    // Проверка результатов с учетом задержки конвейера
    reg [63:0] res_eth_delayed;
    always @(posedge clock) begin
        res_eth_delayed <= res_eth;
    end

    // Проверка результатов
    always @(posedge clock) begin
        if (rst == 0 && test_counter > 0) begin
            #1; // небольшая задержка для стабилизации
            
            if (res_hw !== res_eth_delayed && res_eth_delayed !== 64'b0) begin
                $display("ERROR Test %d:", test_counter);
                $display("  Input A: %h (%.6f)", op_a[31:0], real_a);
                $display("  Input B: %h (%.6f)", op_b[31:0], real_b);
                $display("  Expected: %h (%.6f)", res_eth_delayed[31:0], real_res);
                $display("  Got:      %h", res_hw[31:0]);
                error_count = error_count + 1;
            end else if (res_hw === res_eth_delayed && res_eth_delayed !== 64'b0) begin
                $display("PASS Test %d: %.1f * %.1f = %.1f", test_counter, real_a, real_b, real_res);
            end
        end
    end

endmodule