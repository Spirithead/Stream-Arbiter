`define CALC_QOS 0
`define SELECT_STREAM 1
`define OPERATE 2

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

logic [1:0] state;
logic can_calc;
logic [T_QOS__WIDTH-1:0] qos;
logic [$clog2(STREAM_COUNT):0] index;
logic [STREAM_COUNT-1:0] served;
logic [T_ID___WIDTH-1:0] curr_stream;
logic [T_QOS__WIDTH-1:0] curr_qos;

assign m_last_o = s_last_i[curr_stream];

comparator#(T_QOS__WIDTH,STREAM_COUNT) comp(clk, rst_n, can_calc, s_qos_i, s_valid_i, served, qos, index);

always@(posedge clk, posedge rst_n) begin
    if(rst_n)begin
        served      <= 0;
        state       <= 0;
        s_ready_o   <= 0;
        m_valid_o   <= 0;
        can_calc    <= 1;
        curr_stream <= 0;
        curr_qos    <= 0;
    end
    
    else begin
        case(state)
            `CALC_QOS: begin//состояние сравнения приоритетов компаратором
                state <= `SELECT_STREAM;
                m_valid_o <= 0;//выходные данные обозначаются как недействительные
                can_calc <= 0;//компаратор больше не может сравнивать приоритеты
            end
            
            `SELECT_STREAM: begin//состояние выбора потока
                if(index != STREAM_COUNT) begin
                    if(s_valid_i[index]) begin
                        state <= `OPERATE;
                        //фиксируются номер и приоритет потока
                        curr_stream <= index;
                        curr_qos <= qos;
                    end
                    
                    else begin//выбранный поток в последний момент оказался невалидным
                        state <= `CALC_QOS;
                        can_calc <= 1;//компаратор может начать сравнивать приоритеты
                    end
                end
                
                else begin//найденный компаратором индекс оказался дефолтным,
                          //следовательно, все потоки были обслужены, а значит, их можно выбрать заново
                    state <= `CALC_QOS;
                    can_calc <= 1;//компаратор может начать сравнивать приоритеты
                    served <= 0;//все потоки заново помечаются как необслуженные
                end
            end
            
            `OPERATE: begin//состояние передачи данных
                //если принимающее устройтво готово принимать пакеты и поток валиден
                if(m_ready_i && s_valid_i[curr_stream]) begin
                    s_ready_o[curr_stream] <= 1;//устройство готово принимать пакеты с этого потока
                    m_data_o <= s_data_i[curr_stream];//на выход передаются данные с выбранного потока
                    m_valid_o <= 1;//выходные данные обозначаются как действительные
                    m_id_o <= curr_stream;
                    served[curr_stream] <= 1;//поток обозначается как обслуженный
                    m_qos_o <= curr_qos;
                    
                    if(s_last_i[curr_stream])begin
                        can_calc <= 1;//компаратор может начать сравнивать приоритеты
                        state <= `CALC_QOS;
                        s_ready_o[curr_stream] <= 0;//устройство не готово принимать пакеты с этого потока
                    end
                end
                
                //если принимающее  устройтво не готово принимать пакеты
                else begin
                    s_ready_o[curr_stream] <= 0;//устройство не готово принимать пакеты с этого потока
                    m_valid_o <= 0;//выходные данные обозначаются как недействительные
                end
            end
        endcase 
    end
end

endmodule