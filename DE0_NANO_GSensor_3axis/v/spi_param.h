// Data MSB Bit
parameter   IDLE_MSB        =   14;          // 最大閒置時間的MSB位
parameter   SI_DataL        =   16;          // SPI輸入數據的長度
parameter   SO_DataL        =   8;           // SPI輸出數據的長度

parameter   MI_DataL        =   56;          // SPI multi-byte data length


// Write/Read Mode 
parameter   WRITE_MODE      =   1'b0;       // 寫模式的編碼
parameter   READ_MODE       =   1'b1;       // 讀模式的編碼

// Initial Reg Number 
parameter   INI_NUMBER      =   4'd11;       // 初始化寄存器的數量

// SPI State 
parameter   IDLE            =   3'b000;        // SPI閒置狀態
parameter   TRANSFER        =   3'b001;        // SPI傳輸狀態
parameter   DATAREADY       =   3'b010;        // SPI閒置狀態
parameter   READDATA        =   3'b011;        // SPI傳輸狀態
parameter   DELAYCNT        =   3'b100;        // SPI傳輸狀態

// Write Reg Address 
// 以下是寫操作時使用的寄存器地址
parameter   BW_RATE	        =   6'h2c;      // 帶寬率寄存器地址
parameter   POWER_CONTROL   =   6'h2d;       // 電源控制寄存器地址
parameter   DATA_FORMAT     =   6'h31;       /* Register 0x31—DATA_FORMAT (Read/Write) 
                                                D7: SELF_TEST  D5 D4 D3 D2 
                                                D6: SPI 
																D5: INT_INVERT 
																D4: 0
															   D3: FULL_RES
															   D2: Justify 
																[D1,D0]: Range bit, These bits set the g range */
parameter   INT_ENABLE      =   6'h2E;       // 中斷啟用寄存器地址
parameter   INT_MAP         =   6'h2F;       // 中斷映射寄存器地址
parameter   THRESH_ACT      =   6'h24;       // 活動閾值寄存器地址
            /* Register 0x24—THRESH_ACT (Read/Write):
                功能: 此暫存器用於設定和讀取檢測活動的閾值。
                數據格式: 數據是無符號的，這意味著當感測器檢測到的動作的幅度與此暫存器中的值進行比較時，只考慮其大小，而不考慮其方向。
                比例因子: 62.5 mg/LSB。這意味著每增加1的LSB（最小有效位），閾值將增加62.5 mg。
                注意: 如果設置的值為0，並且啟用了活動中斷，則可能會產生不希望的行為。 */
parameter   THRESH_INACT    =   6'h25;       // 非活動閾值寄存器地址
            /* 功能: 此暫存器用於設定和讀取檢測非活動（或靜止）的閾值。
                數據格式: 數據是無符號的，這意味著當感測器檢測到的靜止的幅度與此暫存器中的值進行比較時，只考慮其大小，而不考慮其方向。
                比例因子: 62.5 mg/LSB。這意味著每增加1的LSB，閾值將增加62.5 mg。
                注意: 如果設置的值為0，並且啟用了非活動中斷，則可能會產生不希望的行為。 */
parameter   TIME_INACT      =   6'h26;       // 非活動時間寄存器地址
            /* 功能: 此暫存器包含一個無符號的時間值，表示加速度必須低於THRESH_INACT暫存器中的值的時間長度，以便宣告為非活動。
                數據格式: 數據是無符號的，代表時間值。
                比例因子: 1 sec/LSB。這意味著每增加1的LSB（最小有效位），時間閾值將增加1秒。
                數據過濾: 與其他使用未過濾數據的中斷功能不同，非活動功能使用過濾的輸出數據。
                這意味著在觸發非活動中斷之前，至少必須生成一個輸出樣本。
                注意: 如果TIME_INACT暫存器的值設定得小於輸出數據速率的時間常數，則此功能可能會看起來沒有反應。
                當輸出數據小於THRESH_INACT暫存器中的值時，設置為0的值會產生中斷。
                總之，此暫存器用於設定和讀取非活動的時間閾值。當感測器檢測到的靜止時間超過此時間閾值時，它可能會產生相應的中斷或其他行為。*/
parameter   ACT_INACT_CTL   =   6'h27;       // 活動/非活動控制寄存器地址
                /* ACT AC/DC 和 INACT AC/DC bit :
                DC耦合操作: 當設置為0時，選擇直流耦合操作。在此模式下，當前的加速度大小直接與THRESH_ACT和THRESH_INACT進行比較，以確定是否檢測到活動或非活動。
                AC耦合操作: 當設置為1時，啟用交流耦合操作。
                活動檢測: 開始活動檢測時的加速度值被視為參考值。新的加速度樣本與此參考值進行比較，如果差值的大小超過THRESH_ACT值，則設備觸發活動中斷。
                非活動檢測: 用於比較的參考值在設備超過非活動閾值時更新。選擇參考值後，設備比較參考值與當前加速度之間的差值的大小與THRESH_INACT。如果差值小於TIME_INACT中的時間的THRESH_INACT值，則認為設備是非活動的，並觸發非活動中斷。
                ACT_x enable bit 和 INACT_x enable bit:
                這些位決定哪些軸（x、y或z）參與檢測活動或非活動。
                啟用: 當設置為1時，x、y或z軸參與檢測活動或非活動。
                禁用: 當設置為0時，所選軸不參與檢測。如果所有軸都被排除，則該功能被禁用。
                活動檢測: 所有參與的軸在邏輯上被OR'ed，這意味著當任何軸檢測到活動時，活動功能都會被觸發。*/

parameter   THRESH_FF       =   6'h28;       // 自由落體閾值寄存器地址
            /* 功能: 此暫存器用於設定和讀取自由下落檢測的閾值。
                數據格式: 數據是無符號的，這意味著當感測器檢測到的所有軸的加速度與此暫存器中的值進行比較時，
                只考慮其大小，而不考慮其方向。
                比例因子: 62.5 mg/LSB。這意味著每增加1的LSB（最小有效位），閾值將增加62.5 mg。
                注意: 如果設置的值為0 mg，並且啟用了自由下落中斷，則可能會產生不希望的行為。
                建議的值範圍是300 mg到600 mg（0x05到0x09）。 */ 

parameter   TIME_FF         =   6'h29;       // 自由落體時間寄存器地址
            /* 功能: 此暫存器存儲一個無符號的時間值，表示所有軸的值必須低於THRESH_FF的最小時間，以產生自由下落中斷。
                數據格式: 數據是無符號的，代表時間值。
                比例因子: 5 ms/LSB。這意味著每增加1的LSB，時間閾值將增加5毫秒。
                注意: 如果設置的值為0，並且啟用了自由下落中斷，則可能會產生不希望的行為。建議的值範圍是100 ms到350 ms（0x14到0x46）。 */

// Read Reg Address
// 以下是讀操作時使用的寄存器地址
parameter   INT_SOURCE      =   6'h30;       // 中斷狀態寄存器地址
        /* 來源中斷暫存器，該暫存器用於指示是否有特定的事件發生。以下是對這段描述的詳細說明和註解：
            事件指示: 在此暫存器中，設置為1的位表示其相應的功能已觸發一個事件。相反，值為0表示相應的事件尚未發生。
            DATA_READY, watermark, 和 overrun 事件:
            無論INT_ENABLE暫存器的設置如何，只要相應的事件發生，這些位就始終被設置。
            這些位可以通過從DATAX, DATAY, 和 DATAZ暫存器讀取數據來清除。
            特別地，DATA_READY和watermark位可能需要多次讀取才能被清除，這在FIFO部分的FIFO模式描述中有所指出。
            其他事件:
            其他的位和相應的中斷可以通過讀取INT_SOURCE暫存器來清除。
            總之，這個暫存器提供了一個方法來快速檢查哪些事件已經發生，並提供了清除這些事件的方法，以便暫存器可以繼續監控新的事件。 */
parameter   X_LB            =   6'h32;       // X軸低位元組寄存器地址
parameter   X_HB            =   6'h33;       // X軸高位元組寄存器地址
parameter   Y_LB            =   6'h34;       // Y軸低位元組寄存器地址
parameter   Y_HB            =   6'h35;       // Y軸高位元組寄存器地址
parameter   Z_LB            =   6'h36;       // Z軸低位元組寄存器地址
parameter   Z_HB            =   6'h37;       // Z軸高位元組寄存器地址
