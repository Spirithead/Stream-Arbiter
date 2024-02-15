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
    //индексы потоков с нулевым приоритетом (сравниваются отдельно)
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
            //если х1 больше х2 или если х1 валиден (в отличие от х2)
            if (X1 >= X2 && (indexX1 != STREAM_COUNT && indexX2 != STREAM_COUNT)
                || (indexX1 != STREAM_COUNT && indexX2 == STREAM_COUNT)) begin
                Y = X1;
                indexY = indexX1;
            end
            
            //если х2 больше х1 или если х2 валиден (в отличие от х1)
            else if(X1 < X2 && (indexX1 != STREAM_COUNT && indexX2 != STREAM_COUNT)
                || (indexX1 == STREAM_COUNT && indexX2 != STREAM_COUNT)) begin
                Y = X2;
                indexY = indexX2;
            end
            
            //если ни один поток не валиден
            else begin
                Y = 0;
                indexY = STREAM_COUNT;
            end
            
            ////////////////////////////сравнение индексов нулей
            if(indexX01 != STREAM_COUNT && indexX02 != STREAM_COUNT) begin//если оба потока валидны
                if(indexX01 <= indexX02) index0Y = indexX01;
                else index0Y = indexX02;
            end
            
            //если только первый поток с нулевым приоритетом валиден
            else if(indexX01 != STREAM_COUNT) index0Y = indexX01;
            //если только второй поток с нулевым приоритетом валиден
            else if(indexX02 != STREAM_COUNT) index0Y = indexX02;
            else index0Y = STREAM_COUNT;
        end
    end
    
endmodule
