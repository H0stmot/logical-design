module real_mul_tb;

    // Тактовый сигнал и сброс
    reg clock;
    reg rst;

    // Счетчик тестов
    integer test_counter;
    integer error_count;

    // ================== FP16 (half) ==================
    // Для half precision в Verilog нет системных функций конверсии
    // (аналогов $bitstoshortreal), поэтому эталонные значения заданы
    // вручную в hex, т.к. тестовые числа (1.0, 2.0, 1.5, 3.0, 4.0)
    // точно представимы в fp16.
    reg  [63:0] op_a_h, op_b_h;
    wire [63:0] res_h;
    reg  [15:0] exp_h;

    real_mul #(.FORMAT(0)) dut_half (
        .clk(clock), .rst(rst),
        .op1(op_a_h), .op2(op_b_h),
        .result(res_h)
    );

    // ================== FP32 (single) ==================
    reg  [63:0] op_a_s, op_b_s;
    wire [63:0] res_s;
    real real_a_s, real_b_s, real_res_s;
    reg  [63:0] exp_s;

    real_mul #(.FORMAT(1)) dut_single (
        .clk(clock), .rst(rst),
        .op1(op_a_s), .op2(op_b_s),
        .result(res_s)
    );

    always @(*) begin
        real_a_s   = $bitstoshortreal(op_a_s[31:0]);
        real_b_s   = $bitstoshortreal(op_b_s[31:0]);
        real_res_s = real_a_s * real_b_s;
        exp_s      = {32'b0, $shortrealtobits(real_res_s)};
    end

    // ================== FP64 (double) ==================
    reg  [63:0] op_a_d, op_b_d;
    wire [63:0] res_d;
    real real_a_d, real_b_d, real_res_d;
    reg  [63:0] exp_d;

    real_mul #(.FORMAT(2)) dut_double (
        .clk(clock), .rst(rst),
        .op1(op_a_d), .op2(op_b_d),
        .result(res_d)
    );

    always @(*) begin
        real_a_d   = $bitstoreal(op_a_d);
        real_b_d   = $bitstoreal(op_b_d);
        real_res_d = real_a_d * real_b_d;
        exp_d      = $realtobits(real_res_d);
    end

    // Генерация тактового сигнала
    initial begin
        clock = 0;
        forever #10 clock = ~clock;
    end

    // Инициализация и стимулы
    initial begin
        rst = 1;
        test_counter = 0;
        error_count  = 0;

        op_a_h = 64'b0; op_b_h = 64'b0; exp_h = 16'b0;
        op_a_s = 64'b0; op_b_s = 64'b0;
        op_a_d = 64'b0; op_b_d = 64'b0;

        #25 rst = 0;

        // Тест 1: 1.0 * 1.0 = 1.0
        #20;
        exp_h  = 16'h3C00;                    // 1.0 в fp16
        op_a_h = {48'b0, 16'h3C00};
        op_b_h = {48'b0, 16'h3C00};
        op_a_s = {32'b0, 32'h3F800000};        // 1.0 в float
        op_b_s = {32'b0, 32'h3F800000};
        op_a_d = 64'h3FF0000000000000;         // 1.0 в double
        op_b_d = 64'h3FF0000000000000;
        test_counter = 1;

        // Тест 2: 2.0 * 2.0 = 4.0
        #40;
        exp_h  = 16'h4400;                    // 4.0 в fp16
        op_a_h = {48'b0, 16'h4000};            // 2.0 в fp16
        op_b_h = {48'b0, 16'h4000};
        op_a_s = {32'b0, 32'h40000000};        // 2.0 в float
        op_b_s = {32'b0, 32'h40000000};
        op_a_d = 64'h4000000000000000;         // 2.0 в double
        op_b_d = 64'h4000000000000000;
        test_counter = 2;

        // Тест 3: 1.5 * 2.0 = 3.0
        #40;
        exp_h  = 16'h4200;                    // 3.0 в fp16
        op_a_h = {48'b0, 16'h3E00};            // 1.5 в fp16
        op_b_h = {48'b0, 16'h4000};            // 2.0 в fp16
        op_a_s = {32'b0, 32'h3FC00000};        // 1.5 в float
        op_b_s = {32'b0, 32'h40000000};        // 2.0 в float
        op_a_d = 64'h3FF8000000000000;         // 1.5 в double
        op_b_d = 64'h4000000000000000;         // 2.0 в double
        test_counter = 3;

        #60;
        if (error_count == 0) begin
            $display("All tests PASSED!");
        end else begin
            $display("Tests completed with %0d errors", error_count);
        end
        $finish;
    end

    // Задержанные эталоны (учет задержки конвейера при проверке,
    // как и в исходном тестбенче)
    reg [63:0] exp_h_delayed, exp_s_delayed, exp_d_delayed;
    always @(posedge clock) begin
        exp_h_delayed <= {48'b0, exp_h};
        exp_s_delayed <= exp_s;
        exp_d_delayed <= exp_d;
    end

    // Проверка результатов
    always @(posedge clock) begin
        if (rst == 0 && test_counter > 0) begin
            #1; // небольшая задержка для стабилизации

            // ---- FP16 ----
            if (res_h !== exp_h_delayed && exp_h_delayed !== 64'b0) begin
                $display("ERROR (half) Test %0d:", test_counter);
                $display("  Input A: %h", op_a_h[15:0]);
                $display("  Input B: %h", op_b_h[15:0]);
                $display("  Expected: %h", exp_h_delayed[15:0]);
                $display("  Got:      %h", res_h[15:0]);
                error_count = error_count + 1;
            end else if (res_h === exp_h_delayed && exp_h_delayed !== 64'b0) begin
                $display("PASS (half) Test %0d: %h * %h = %h", test_counter, op_a_h[15:0], op_b_h[15:0], res_h[15:0]);
            end

            // ---- FP32 ----
            if (res_s !== exp_s_delayed && exp_s_delayed !== 64'b0) begin
                $display("ERROR (single) Test %0d:", test_counter);
                $display("  Input A: %h (%.6f)", op_a_s[31:0], real_a_s);
                $display("  Input B: %h (%.6f)", op_b_s[31:0], real_b_s);
                $display("  Expected: %h (%.6f)", exp_s_delayed[31:0], real_res_s);
                $display("  Got:      %h", res_s[31:0]);
                error_count = error_count + 1;
            end else if (res_s === exp_s_delayed && exp_s_delayed !== 64'b0) begin
                $display("PASS (single) Test %0d: %.1f * %.1f = %.1f", test_counter, real_a_s, real_b_s, real_res_s);
            end

            // ---- FP64 ----
            if (res_d !== exp_d_delayed && exp_d_delayed !== 64'b0) begin
                $display("ERROR (double) Test %0d:", test_counter);
                $display("  Input A: %h (%.6f)", op_a_d, real_a_d);
                $display("  Input B: %h (%.6f)", op_b_d, real_b_d);
                $display("  Expected: %h (%.6f)", exp_d_delayed, real_res_d);
                $display("  Got:      %h", res_d);
                error_count = error_count + 1;
            end else if (res_d === exp_d_delayed && exp_d_delayed !== 64'b0) begin
                $display("PASS (double) Test %0d: %.1f * %.1f = %.1f", test_counter, real_a_d, real_b_d, real_res_d);
            end
        end
    end

endmodule
