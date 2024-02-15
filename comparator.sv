`define STREAM_MAX 8

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
    output logic [T_QOS__WIDTH-1:0] qos,
    output logic [$clog2(STREAM_COUNT):0] index
);

wire [T_QOS__WIDTH-1:0] in_value [`STREAM_MAX-1:0];
wire [`STREAM_MAX-1:0] in_serv;
wire [`STREAM_MAX-1:0] in_valid;
wire [$clog2(STREAM_COUNT):0] indexv;
wire [$clog2(STREAM_COUNT):0] index0;
wire [T_QOS__WIDTH-1:0] max_qos;

//выводится наименьший индекс из двух полученных индексов
assign index = (indexv == STREAM_COUNT && index0 == STREAM_COUNT ? STREAM_COUNT  
    : (indexv <= index0 ? indexv : index0));

//выводится приоритет потока с наименьшим полученным индексом    
assign qos = (indexv == STREAM_COUNT && index0 == STREAM_COUNT ? 0  
    : (indexv <= index0 ? max_qos : 0));

//преобразование входных данных к формату, пригодному к этому компаратору
genvar j;
for(j=0;j<`STREAM_MAX;j++) begin
    if(j<STREAM_COUNT) begin 
        assign in_value[j] = s_qos_i[j];
        assign in_serv[j] = served[j];
        assign in_valid[j] = s_valid_i[j];
    end
    else begin 
        assign in_value[j] = 0;
        assign in_serv[j] = 1;
        assign in_valid[j] = 0;
    end
end

wire [T_QOS__WIDTH-1:0] value_l1[0:3];
wire [$clog2(STREAM_COUNT):0] index_l1[0:3];
wire [$clog2(STREAM_COUNT):0] index0_l1[0:3];

genvar i;
generate
    for (i=0;i<`STREAM_MAX;i=i+2) begin :gen_comps_l1
        comp2s#(T_QOS__WIDTH, STREAM_COUNT) cl1 
                (clk,
                 rst_n,
                 (can_calc && ~(s_valid_i == 0 || in_serv == 8'b11111111)),
                 in_valid[i],
                 in_serv[i],
                 in_valid[i+1],
                 in_serv[i+1],
                 in_value[i],
                 i,
                 in_value[i+1],
                 (i+1),
                 value_l1[i/2],
                 index_l1[i/2],
                 index0_l1[i/2]
                );
    end
endgenerate

wire [T_QOS__WIDTH-1:0] value_l2[0:1];
wire [$clog2(STREAM_COUNT):0] index_l2[0:1];
wire [$clog2(STREAM_COUNT):0] index0_l2[0:1];

generate
    for (i=0;i<`STREAM_MAX/2;i=i+2) begin :gen_comps_l2
        comp2#(T_QOS__WIDTH, STREAM_COUNT) cl2 
                (rst_n,
                 (can_calc && s_valid_i != 0 && in_serv != 8'b11111111),
                 value_l1[i],
                 index_l1[i],
                 value_l1[i+1],
                 index_l1[i+1],
                 index0_l1[i],
                 index0_l1[i+1],
                 value_l2[i/2],
                 index_l2[i/2],
                 index0_l2[i/2]
                );
    end
endgenerate

generate
    for (i=0;i<`STREAM_MAX/4;i=i+2) begin :gen_comps_l3
        comp2#(T_QOS__WIDTH, STREAM_COUNT) cl3 
                (rst_n,
                 (can_calc && s_valid_i != 0 && in_serv != 8'b11111111),
                 value_l2[i],
                 index_l2[i],
                 value_l2[i+1],
                 index_l2[i+1],
                 index0_l2[i],
                 index0_l2[i+1],
                 max_qos,
                 indexv,
                 index0
                );
    end
endgenerate

endmodule
