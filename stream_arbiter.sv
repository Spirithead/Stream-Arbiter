`define CALC_QOS 0
`define OPERATE 1

module stream_arbiter #(
  parameter  T_DATA_WIDTH = 8,
             T_QOS__WIDTH = 4,
             STREAM_COUNT = 2,
  localparam T_ID___WIDTH = $clog2(STREAM_COUNT)
  
)(
  input logic clk,
  input logic rst_n,
  // input streams
  input logic  [T_DATA_WIDTH-1:0] s_data_i [STREAM_COUNT-1:0],
  input logic  [T_QOS__WIDTH-1:0] s_qos_i  [STREAM_COUNT-1:0],
  input logic  [STREAM_COUNT-1:0] s_last_i ,
  input logic  [STREAM_COUNT-1:0] s_valid_i,
  output logic [STREAM_COUNT-1:0] s_ready_o,
  // output stream
  output logic [T_DATA_WIDTH-1:0] m_data_o,
  output logic [T_QOS__WIDTH-1:0] m_qos_o,
  output logic [T_ID___WIDTH-1:0] m_id_o,
  output logic m_last_o,
  output logic m_valid_o,
  input logic m_ready_i
);



logic state;//состояние автомата
logic locked;//флаг фиксации потока до завершения транзакции
logic can_calc;//флаг, разрешающий пересчёт максимального приоритета
logic [T_QOS__WIDTH-1:0] max_qos;//максимальный приоритет
logic [STREAM_COUNT-1:0] served;//массив флагов, обозначающих, был ли обслужен какой-либо поток
logic [T_ID___WIDTH-1:0] curr_stream;//индекс потока, выбранного для вывода данных
 
assign m_last_o = s_last_i[curr_stream];
assign m_qos_o = s_qos_i[curr_stream];

comparator#(T_QOS__WIDTH,STREAM_COUNT) comp(clk, rst_n, can_calc, s_qos_i, s_valid_i, served, max_qos);

always@(posedge clk, posedge rst_n) begin
    if(rst_n)begin
        locked      <= 0;
        served      <= 0;
        state       <= 0;
        s_ready_o   <= 0;
        m_valid_o   <= 0;
        can_calc    <= 1;
    end
    
    else begin
        case(state)
            `CALC_QOS: begin
                state 		<= 1;
                m_valid_o 	<= 0;//выходные данные обозначаются как недействительные
                can_calc 	<= 0;
            end
            
            `OPERATE: begin
                if(!locked)begin//выбор потока может быть произведён только вне передачи транзакции
                    for(int i=0; i<STREAM_COUNT; i++)begin
                        if(s_valid_i[i] & !served[i] & ((s_qos_i[i] == max_qos) | (s_qos_i[i] == 0)))begin
                            m_id_o      <= i;
                            curr_stream <= i;
                            m_data_o    <= s_data_i[i];
                            locked      <= 1;
                            m_valid_o   <= 1;//выходные данные обозначаются как действительные
                            s_ready_o[i]<= 1;//устройство готово принимать пакеты с этого потока
                            served[i]   <= 1;//поток обозначается как обслуженный
                            break;
                        end
                    end
                end
                
                else begin
                    m_data_o <= s_data_i[curr_stream];
                    if(s_last_i[curr_stream])begin
                        locked <= 0;//транзакция передана и блокировка снята
                        s_ready_o[curr_stream] <= 0;//устройство не готово принимать пакеты с этого потока
                        can_calc <= 1;
                        state <= `CALC_QOS;
                        if(s_valid_i ^ served == 0) served <= 0;
								//если все потоки, передающие данные, уже были обслужены, цикл выбора потоков сбрасывается
								//и потоки могут быть выбраны заново
                    end
                    
                    else begin
                        for(int j=0; j<STREAM_COUNT; j++) begin
                            if(!s_valid_i[j]) served[j] <= 0;
									 //если данные с потока больше не поступают, он обозначается как необслуженный
                        end 
                    end
                end
            end
        endcase 
    end
end

endmodule