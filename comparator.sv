module comparator#(
    parameter T_QOS__WIDTH = 4,
              STREAM_COUNT = 2
    )(
    input logic  clk,
    input logic  rst_n,
    input logic  can_calc,
    input logic  [T_QOS__WIDTH-1:0] s_qos_i  [STREAM_COUNT-1:0],
    input logic  [STREAM_COUNT-1:0] s_valid_i,
    input logic  [STREAM_COUNT-1:0] served,
    output logic [T_QOS__WIDTH-1:0] max_qos
);
reg[T_QOS__WIDTH-1:0] max;
assign max_qos = max;

always@(posedge clk, posedge rst_n) begin
    if(rst_n) max <= 0;
    
    else begin
        if(can_calc)begin
            max = 0;
            for(int i=0; i<STREAM_COUNT; i++)begin
                if(s_valid_i[i] & !served[i] & s_qos_i[i] > max) max = s_qos_i[i];
					 //если поток ещё не был обслужен и его данные действительны, его приоритет может
					 //быть выбран как максимальный
            end
        end
    end
end
endmodule
