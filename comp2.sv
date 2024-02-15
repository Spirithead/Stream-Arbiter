module comp2#(
    parameter T_QOS__WIDTH = 4,
              STREAM_COUNT = 2
    )(
    input logic  rst_n,
    input logic  can_calc,
    input logic  [T_QOS__WIDTH-1:0] X1,
    input logic  [$clog2(STREAM_COUNT):0] indexX1,
    input logic  [T_QOS__WIDTH-1:0] X2,
    input logic  [$clog2(STREAM_COUNT):0] indexX2,
    //������� ������� � ������� ����������� (������������ ��������)
    input logic  [$clog2(STREAM_COUNT):0] indexX01,
    input logic  [$clog2(STREAM_COUNT):0] indexX02,
    output logic [T_QOS__WIDTH-1:0] Y,
    output logic [$clog2(STREAM_COUNT):0] indexY,
    output logic [$clog2(STREAM_COUNT):0] index0Y
    );
    
always @(rst_n, X1, X2, indexX1, indexX2, indexX01, indexX02) begin
        if(rst_n) begin
            Y <= 0;
            indexY <= STREAM_COUNT;
            index0Y <= STREAM_COUNT;
        end
        
        else if(can_calc) begin
            //���� �1 ������ �2 ��� ���� �1 ������� (� ������� �� �2)
            if (X1 >= X2 && (indexX1 != STREAM_COUNT && indexX2 != STREAM_COUNT)
                || (indexX1 != STREAM_COUNT && indexX2 == STREAM_COUNT)) begin
                Y = X1;
                indexY = indexX1;
            end
            
            //���� �2 ������ �1 ��� ���� �2 ������� (� ������� �� �1)
            else if(X1 < X2 && (indexX1 != STREAM_COUNT && indexX2 != STREAM_COUNT)
                || (indexX1 == STREAM_COUNT && indexX2 != STREAM_COUNT)) begin
                Y = X2;
                indexY = indexX2;
            end
            
            //���� �� ���� ����� �� �������
            else begin
                Y = 0;
                indexY = STREAM_COUNT;
            end
            
            ////////////////////////////��������� �������� �����
            if(indexX01 != STREAM_COUNT && indexX02 != STREAM_COUNT) begin//���� ��� ������ �������
                if(indexX01 <= indexX02) index0Y = indexX01;
                else index0Y = indexX02;
            end
            
            //���� ������ ������ ����� � ������� ����������� �������
            else if(indexX01 != STREAM_COUNT) index0Y = indexX01;
            //���� ������ ������ ����� � ������� ����������� �������
            else if(indexX02 != STREAM_COUNT) index0Y = indexX02;
            else index0Y = STREAM_COUNT;
        end
    end
    
endmodule
