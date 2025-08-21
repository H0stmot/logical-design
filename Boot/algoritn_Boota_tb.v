`include "algoritm_Boota.v" 

module booth_multiplier_testbench;

  // --- Параметры тестируемого устройства (DUT) ---
  localparam DATA_WIDTH = 8;
  localparam PRODUCT_WIDTH = 2 * DATA_WIDTH;
  localparam NUM_RANDOM_TESTS = 100;

  // --- Сигналы тестбенча ---
  reg clk;
  reg rst;
  reg signed [DATA_WIDTH-1:0] multiplicand;
  reg signed [DATA_WIDTH-1:0] multiplier;

  wire signed [PRODUCT_WIDTH-1:0] product;

  // --- Переменные для проверки ---
  // ИСПРАВЛЕНИЕ №1: Переменные объявлены в области видимости модуля,
  // чтобы избежать проблем с синтаксическим анализом в некоторых симуляторах.
  integer test_count;
  integer expected_product;

  // --- Генерация тактового сигнала ---
  always #1 clk = ~clk;

  // --- Инициализация и завершение симуляции ---
  initial begin
    clk <= 1'b0;
    rst <= 1'b1;
    multiplicand <= 0;
    multiplier <= 0;
    test_count = 0;

    repeat (5) @(posedge clk);
    rst <= 1'b0; 

    $display("--- Starting Booth Multiplier Random Test ---");
    $display("Time | Test # | Multiplicand | Multiplier | Expected Product | Actual Product | Status");
    $display("-----------------------------------------------------------------------------------------");

    // Ждем завершения всех тестов
    wait (test_count >= NUM_RANDOM_TESTS);

    $display("-----------------------------------------------------------------------------------------");
    $display("--- All %0d Random Booth Multiplier Tests Completed Successfully ---", NUM_RANDOM_TESTS);
    #100;
    $finish(); 
  end

  // --- Генерация случайных входных данных ---
  // Новые значения генерируются ТОЛЬКО тогда, когда умножение завершено (dut.counter == 0).
  always @(posedge clk) begin
    if (!rst && dut.counter == 0) begin
      multiplicand <= $signed($random);
      multiplier   <= $signed($random);
    end
  end

  // --- Экземпляр тестируемого устройства (DUT) ---
  // ИСПРАВЛЕНИЕ №2: Возвращены исходные имена портов (.x, .y, .M), 
  // так как они вероятнее всего соответствуют вашему модулю.
  algoritm_Boota #(
    .DATA_WIDTH(DATA_WIDTH) // Передача параметров в DUT
  )
  (
    .clk(clk),
    .rst(rst),
    .x(multiplicand), // Подключение к порту 'x' DUT
    .y(multiplier),   // Подключение к порту 'y' DUT
    .M(product)       // Подключение к порту 'M' DUT
  );

  // --- Проверка результата ---
  always @(negedge clk) begin
    // Проверяем результат только когда сброс неактивен и DUT сообщает о завершении.
    if (!rst && dut.counter == 0) begin
      // Используем $past(), чтобы получить значения, которые были ДО последнего такта,
      // так как именно с ними DUT завершил вычисление.
      expected_product = $past(multiplicand) * $past(multiplier);
      
      // Увеличиваем счетчик завершенных тестов.
      test_count = test_count + 1;

      $display("%4t | %6d | %12d | %10d | %16d | %14d | %s",
               $time,
               test_count,
               $past(multiplicand),
               $past(multiplier),
               expected_product,
               product,
               (product == expected_product) ? "PASS" : "FAIL");

      if (product !== expected_product) begin
        $display("ERROR: Mismatch found! Expected %d, got %d", expected_product, product);
        // Завершаем симуляцию с кодом ошибки.
        $finish(2);
      end
    end
  end

endmodule