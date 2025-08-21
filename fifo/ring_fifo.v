module ring_fifo #(
    parameter DEPTH = 16,              
    parameter DATA_WIDTH = 8           
) (
    input wire clk,
    input wire reset,
    input wire write,
    input wire [DATA_WIDTH-1:0] datain,
    input wire read,
    output wire [DATA_WIDTH-1:0] dataout,
    output wire val,
    output wire full
);
     localparam size = $clog2(DEPTH); 
    reg [size - 1:0] wr_ptr;                                                // такая разрядность, тк это указатель на индекс элемента в буфере(Элементов DEPTH)
    reg [size - 1:0] rd_ptr;
    reg [DATA_WIDTH-1:0] buffer [0:DEPTH-1];
    reg lst_op = 0;                                                         //Регистр для запоминания последней операции(1 при записи, 0 при чтении)
    wire empty = (wr_ptr == rd_ptr) & !lst_op;                              // при lst_op = 0, утстанавливаем empty 1
    assign full = (wr_ptr == rd_ptr) & lst_op;                              // при lst_op = 1, утстанавливаем full 1
    assign dataout = buffer[rd_ptr]; 
    assign val = ~empty;
    
    always @(posedge clk) begin                                             //Синхронный reset 
        if (reset) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
        end else begin
            if (write && !full) begin
                wr_ptr <= (wr_ptr == DEPTH-1) ? 0 : wr_ptr + 1;             //Увеличиваем на 1 после чтения указатель на элемент который будет считан на следующем такте
                lst_op <= 1'b1; 
            end
            else if (read && !empty) begin
                rd_ptr <= (rd_ptr == DEPTH-1) ? 0 : rd_ptr + 1;             //Увеличиваем на 1 после записи указатель на элемент в который будет записаны данные на следующем такте
                lst_op <= 1'b0;
            end
            else if (read && !empty && write) begin                         // не меняем lst op, так как по факту ничего не поменялось относительно места в буфере
                rd_ptr <= (rd_ptr == DEPTH-1) ? 0 : rd_ptr + 1;
                wr_ptr <= (wr_ptr == DEPTH-1) ? 0 : wr_ptr + 1;
            end
        end
    end
    always @(posedge clk) begin                                             //запись данных в буфер
        buffer[wr_ptr] <= write & (!full | read)  ? datain  :  buffer[wr_ptr];
    end
endmodule