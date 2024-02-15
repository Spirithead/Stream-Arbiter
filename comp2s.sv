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
            //если х1 больше х2 или если х1 валиден (в отличие от х2)
            if ((X1 >= X2) && (s_valid_i1 && ~in_serv1 && s_valid_i2 && ~in_serv2) 
                || ((s_valid_i1 && ~in_serv1) && (~s_valid_i2 || in_serv2))) begin
                Y = X1;
                indexY = indexX1;
            end
            
            //если х2 больше х1 или если х2 валиден (в отличие от х1)
            else if ((X1 < X2) && (s_valid_i1 && ~in_serv1 && s_valid_i2 && ~in_serv2)
                || ((s_valid_i2 && ~in_serv2) && (~s_valid_i1 || in_serv1))) begin
                Y = X2;
                indexY = indexX2;
            end
            
            //если ни один поток не валиден
            else begin
                Y = 0;
                indexY = STREAM_COUNT;
            end
            
            /////////////////////сравнение индексов нулей
            if(s_valid_i1 && ~in_serv1 && s_valid_i2 && ~in_serv2)begin//если оба потока валидны
                if(X1 == 0 && X2 == 0)begin//если оба приоритета равны нулю
                    if(indexX1 <= indexX2) index0Y = indexX1;
                    else index0Y = indexX2;
                end
                
                else begin
                    if(X1 == 0) index0Y = indexX1;//если только х1 равен нулю
                    else if(X2 == 0) index0Y = indexX2;//если только х2 равен нулю
                    else index0Y = STREAM_COUNT;//если оба приоритета ненулевые
                end
            end
            
            //если только х1 валиден и равен нулю
            else if(s_valid_i1 && ~in_serv1 && X1 == 0) index0Y = indexX1;
            //если только х2 валиден и равен нулю
            else if(s_valid_i2 && ~in_serv2 && X2 == 0) index0Y = indexX2;
            //дефолтное значение
            else index0Y = STREAM_COUNT;
        end
    end
end
    
endmodule
