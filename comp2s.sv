module comp2s#(
    parameter T_QOS__WIDTH = 4,
              STREAM_COUNT = 2
    )(
    input logic  clk,
    input logic  rst_n,
    input logic  can_calc,
    input logic  s_valid_i1,
    input logic  in_serv1,
    input logic  s_valid_i2,
    input logic  in_serv2,
    input logic  [T_QOS__WIDTH-1:0] X1,
    input logic  [$clog2(STREAM_COUNT):0] indexX1,
    input logic  [T_QOS__WIDTH-1:0] X2,
    input logic  [$clog2(STREAM_COUNT):0] indexX2,
    output logic [T_QOS__WIDTH-1:0] Y,
    output logic [$clog2(STREAM_COUNT):0] indexY,
    output logic [$clog2(STREAM_COUNT):0] index0Y
    );
    
always@(posedge clk, posedge rst_n) begin
    if(rst_n) begin
        Y <= 0;
        indexY <= STREAM_COUNT;
        index0Y <= STREAM_COUNT;
    end
    
    else begin
        if(can_calc) begin
            //���� �1 ������ �2 ��� ���� �1 ������� (� ������� �� �2)
            if ((X1 >= X2) && (s_valid_i1 && ~in_serv1 && s_valid_i2 && ~in_serv2) 
                || ((s_valid_i1 && ~in_serv1) && (~s_valid_i2 || in_serv2))) begin
                Y = X1;
                indexY = indexX1;
            end
            
            //���� �2 ������ �1 ��� ���� �2 ������� (� ������� �� �1)
            else if ((X1 < X2) && (s_valid_i1 && ~in_serv1 && s_valid_i2 && ~in_serv2)
                || ((s_valid_i2 && ~in_serv2) && (~s_valid_i1 || in_serv1))) begin
                Y = X2;
                indexY = indexX2;
            end
            
            //���� �� ���� ����� �� �������
            else begin
                Y = 0;
                indexY = STREAM_COUNT;
            end
            
            /////////////////////��������� �������� �����
            if(s_valid_i1 && ~in_serv1 && s_valid_i2 && ~in_serv2)begin//���� ��� ������ �������
                if(X1 == 0 && X2 == 0)begin//���� ��� ���������� ����� ����
                    if(indexX1 <= indexX2) index0Y = indexX1;
                    else index0Y = indexX2;
                end
                
                else begin
                    if(X1 == 0) index0Y = indexX1;//���� ������ �1 ����� ����
                    else if(X2 == 0) index0Y = indexX2;//���� ������ �2 ����� ����
                    else index0Y = STREAM_COUNT;//���� ��� ���������� ���������
                end
            end
            
            //���� ������ �1 ������� � ����� ����
            else if(s_valid_i1 && ~in_serv1 && X1 == 0) index0Y = indexX1;
            //���� ������ �2 ������� � ����� ����
            else if(s_valid_i2 && ~in_serv2 && X2 == 0) index0Y = indexX2;
            //��������� ��������
            else index0Y = STREAM_COUNT;
        end
    end
end
    
endmodule
