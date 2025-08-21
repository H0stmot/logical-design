module algoritm_Boota (
    input clk,
    input rst,
    input signed [7:0] x, //множимое
    input signed [7:0] y, // множитель
    output signed [15:0] M // произведение
);

  reg signed [7:0] A_reg; // Частичные произведения
  reg signed [7:0] Q_reg; 
  reg Q_minus_1;          
  reg [3:0] counter;      

  // Регистр для хранения промежуточного значения M перед присвоением
  reg signed [16:0] temp_M;

  always @(posedge clk or posedge rst) begin
    if (rst) begin
      A_reg <= 0;
      Q_reg <= y;
      Q_minus_1 <= 0;
      counter <= 8; // Для 8-битного множителя нужно 8 итераций
    end else begin
      if (counter > 0) begin
        
        case ({Q_reg[0], Q_minus_1})
          2'b01: A_reg <= A_reg + x; // M = M + x
          2'b10: A_reg <= A_reg - x; // M = M - x
          default: A_reg <= A_reg;   // M = M (для 00 и 11)
        endcase

        // После выполнения операции, объединяем A_reg, Q_reg и Q_minus_1 для сдвига
        temp_M = {A_reg, Q_reg, Q_minus_1};

 
        temp_M = temp_M >>> 1; // Арифметический сдвиг вправо

        // Обновление регистров после сдвига
        A_reg <= temp_M[16:9];   
        Q_reg <= temp_M[8:1];   
        Q_minus_1 <= temp_M[0];  

     
        counter <= counter - 1;
      end
    end
  end

  assign M = {A_reg, Q_reg};

endmodule