// 定義名為led_driver的模組，該模組負責根據輸入數據驅動LED顯示。
module led_driver (iRSTN, iCLK, iDIG, iG_INT2, oLED);

input           iRSTN;          // 系統重置信號
input           iCLK;           // 模組的時鐘信號
input   [9:0]   iDIG;           // 10位的數據輸入
input           iG_INT2;        // G感測器的中斷信號輸入
output  [7:0]   oLED;           // 8位的LED輸出

//=======================================================
//  REG/WIRE declarations
//=======================================================
wire    [4:0]   select_data;    // 選擇的數據，根據iG_INT2和iDIG選擇
wire            signed_bit;     // 符號位
wire    [3:0]   abs_select_high;// 選擇數據的絕對值
reg     [1:0]   int2_d;         // iG_INT2的延遲版本
reg     [31:0]  int2_count;     // 中斷計數器
reg             int2_count_en;  // 中斷計數器啟用信號

//=======================================================
//  Structural coding
//=======================================================
// 根據iG_INT2和iDIG選擇數據
assign select_data = iG_INT2 ? iDIG[9:5] : /* show x_data MSB 4 bit*/
                                          (iDIG[9]? (iDIG[8] ? iDIG[8:4] : 5'h10): (iDIG[8]? 5'hf: iDIG[8:4]));
                                           //          ^^iDIG[9]
                               // iDIG[9:0]=10'b00_000_0_0000
assign signed_bit = select_data[4];
assign abs_select_high = signed_bit ? ~select_data[3:0] : select_data[3:0]; 

// 根據選擇的數據驅動LED
assign oLED = int2_count_en ? ((abs_select_high[3:1] == 3'h0) ? 8'h18 : /* light middle two leds */
                                (abs_select_high[3:1] == 3'h6) ? (signed_bit? 8'h3: 8'hc0) :
                                                                 (signed_bit? 8'h1: 8'h80) ) :
                                (int2_count[10] ? 8'h0 : 8'hff); 

// 處理中斷計數器的邏輯
always@(posedge iCLK or negedge iRSTN)
    if (!iRSTN)  begin
        int2_count_en <= 1'b0;
        int2_count <= 24'h800000;
    end
    else begin
        int2_count_en <= int2_count_en;
        int2_count <= int2_count;
        
        int2_d <= {int2_d[0], iG_INT2};     /* 移位中斷訊號 */
        if (!int2_d[1] && int2_d[0])begin   /* 偵測中斷訊號上緣觸發 */
            int2_count_en <= 1'b1;
            int2_count <= 24'h0;
        end
        else if (int2_count[28]) /* 數到0x80_0000 關閉int2_count_en */
            int2_count_en <= 1'b0; 
        else
            int2_count <= int2_count + 1;
    end

endmodule
