module  DataCalcRate(
                 iClk50M,
                 iRst_n,
                 
                 iDataValid,
                 oDataRateSec,
                 
                 );

input                 iClk50M;
input                 iRst_n;
                 
input                 iDataValid;
output  [15:0]        oDataRateSec;

reg     [31:0]              rCnt1Hz;
reg                         rClk1Hz;


always@(posedge iClk50M or negedge iRst_n)begin
    if(!iRst_n) begin
        rCnt1Hz <= 0; rClk1Hz<=0;
    end else begin
        if(rCnt1Hz >= (50000000/2-1))begin
            rClk1Hz <= ~rClk1Hz;
            rCnt1Hz<= 0;
        end
        else begin
            rCnt1Hz<= rCnt1Hz+1;
            rClk1Hz <= rClk1Hz;
        end
    end
end
reg         rPreDval, rPreClk1Hz;
reg [15:0]  rCnt, rFPS;
assign oDataRateSec = rFPS;

/* 計算每秒讀取資料數 */
always@(posedge iClk50M or negedge iRst_n)begin
    if(!iRst_n) begin
        rPreDval <= 0; rPreClk1Hz<=0; rCnt <= 0; rFPS <= 0;
    end else begin
        rPreDval <= iDataValid; rPreClk1Hz <= rClk1Hz; rCnt <= rCnt; rFPS <= rFPS;
        if({rPreDval, iDataValid}==2'b01) begin
            rCnt <= rCnt+1;
        end else if({rPreClk1Hz, rClk1Hz}==2'b01)begin
            rCnt <= 0;
            rFPS <= rCnt;
        end
    end
end

endmodule
