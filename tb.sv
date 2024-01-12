`timescale 1ns / 1ps
module tb;

localparam T_DATA_WIDTH = 8;
localparam T_QOS__WIDTH = 4;
localparam STREAM_COUNT = 3;
localparam T_ID___WIDTH = $clog2(STREAM_COUNT);
reg clk, rst_n;
integer cnt [STREAM_COUNT-1:0];

logic [T_DATA_WIDTH-1:0] stream0 [9:0];
logic [T_DATA_WIDTH-1:0] stream1 [9:0];
logic [T_DATA_WIDTH-1:0] stream2 [9:0];

logic [3:0] stream_length [STREAM_COUNT-1:0];

logic [T_DATA_WIDTH-1:0] s_data_i [STREAM_COUNT-1:0];
logic [T_QOS__WIDTH-1:0] s_qos_i  [STREAM_COUNT-1:0];
logic [STREAM_COUNT-1:0] s_last_i;
logic [STREAM_COUNT-1:0] s_valid_i;
logic [STREAM_COUNT-1:0] s_ready_o;

logic [T_DATA_WIDTH-1:0] m_data_o;
logic [T_QOS__WIDTH-1:0] m_qos_o;
logic [T_ID___WIDTH-1:0] m_id_o;
logic m_last_o;
logic m_valid_o;
logic m_ready_i;


stream_arbiter #(
    .T_DATA_WIDTH(T_DATA_WIDTH),
    .T_QOS__WIDTH(T_QOS__WIDTH),
    .STREAM_COUNT(STREAM_COUNT)
    ) 
    str(clk, rst_n, s_data_i, s_qos_i, s_last_i, s_valid_i, s_ready_o, 
        m_data_o, m_qos_o, m_id_o, m_last_o, m_valid_o, m_ready_i);

initial begin
    clk=0;
    for(int i=0; i<STREAM_COUNT; i++) cnt[i] = 0;
	 
    s_last_i = 3'b000;
    m_ready_i = 1;
	 
	 $readmemh("stream0.tv", stream0);
	 $readmemh("stream1.tv", stream1);
	 $readmemh("stream2.tv", stream2);
	 
	 $readmemh("lenghts.tv", stream_length);
    
    s_valid_i=3'b111;
    s_qos_i[0] = 2;
    s_qos_i[1] = 0;
    s_qos_i[2] = 6;
    
    s_data_i[0] = stream0[cnt[0]];
    s_data_i[1] = stream1[cnt[1]];
    s_data_i[2] = stream2[cnt[2]];
    
    rst_n=1;//симуляция нажатия кнопки сброса
    #100;
    rst_n=0;
end

always #5 clk=~clk;

always@(posedge clk) begin
    if(s_ready_o[m_id_o])begin
        cnt[m_id_o]++;
        s_data_i[0] = stream0[cnt[0]];
        s_data_i[1] = stream1[cnt[1]];
        s_data_i[2] = stream2[cnt[2]];
        if(cnt[m_id_o] == stream_length[m_id_o])begin 
            s_last_i[m_id_o] = 1;
        end
    end
end

always@(posedge m_last_o) s_valid_i[m_id_o] <= 0;

endmodule
