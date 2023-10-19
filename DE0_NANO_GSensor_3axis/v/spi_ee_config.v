// Module definition for SPI EEPROM configuration
module spi_ee_config (
    iClk50M,            // 50 MHz clock input
    iRst_n,             // System reset signal (active low)
    iG_INT2,            // Interrupt signal input
    oAccDval,           // Output data valid signal
    oAcc_X,             // X-axis acceleration data output
    oAcc_Y,             // Y-axis acceleration data output
    oAcc_Z,             // Z-axis acceleration data output
    oSensorDt,          // Output for sensing time difference
    SPI_SDIO,           // Bidirectional data line for SPI
    oSPI_CSN,           // Chip select signal for SPI
    oSPI_CLK            // Clock signal for SPI
);

//=======================================================
//  PARAMETER declarations
//=======================================================

// Include file containing SPI related parameters
`include "spi_param.h"

// Define state parameters for G-sensor
parameter GRun=0, GInit=1;

// Define clock frequencies
parameter ClkInFreq = 50_000_000;  // Input clock frequency
parameter SPIClkFreq = 2_000_000;  // SPI clock frequency

//=======================================================
//  PORT declarations
//=======================================================

// Define input ports
input iClk50M;                     // 50 MHz clock input
input iRst_n;                      // System reset signal (active low)
input iG_INT2;                     // Interrupt signal input

// Define output ports
output reg oAccDval;               // Output data valid signal
output reg [15:0] oAcc_X;          // X-axis acceleration data output
output reg [15:0] oAcc_Y;          // Y-axis acceleration data output
output reg [15:0] oAcc_Z;          // Z-axis acceleration data output
output reg [15:0] oSensorDt;        // Output for sensing time difference

// Define SPI interface signals
inout SPI_SDIO;                    // Bidirectional data line for SPI
output oSPI_CSN;                   // Chip select signal for SPI
output oSPI_CLK;                   // Clock signal for SPI

//=======================================================
//  REG/WIRE declarations
//=======================================================

// Define registers and wires for internal operations
reg [3:0] ini_index;               // Initialization index register
reg [SI_DataL-3:0]  write_data;    // Data to be written to SPI
reg [SI_DataL-1:0]  p2s_data;      // Data from processor to SPI
reg                 spi_go;        // Signal to start SPI communication
wire                spi_end;       // Signal indicating end of SPI communication
wire [SO_DataL-1:0] s2p_data;      // Data from SPI to processor
reg [2:0]           spi_state;     // SPI state register

// Define registers for reading rate and G-sensor state
reg [IDLE_MSB:0]    read_idle_count;  // Counter for reading rate
reg [1:0]           GSensorState;     // G-sensor state register
wire                s2p_dval;         // Data valid signal from SPI to processor
reg [SO_DataL-1:0]  rAccData[5:0];    // Array to save acceleration data
reg [2:0]           rAccCnt;          // Counter for acceleration data
reg [9:0]           rDtCnt;           // Counter for sensor time difference

wire                wClk2Mhz;         // Define a wire for the 2MHz clock signal
reg [10:0]  rCnt;                     // Define a register for counting and a register to indicate when to go
reg         rClkGo;
wire        wSPI_CLK, wSPI_CLK_OUT;   // Define wires for the SPI clocks
//=======================================================
//  Sub-module
//=======================================================




// Always block to generate a clock signal based on the input 50MHz clock
always@(posedge iClk50M or negedge iRst_n) begin
    if(!iRst_n)begin
        rCnt <= 0; // Reset the counter
        rClkGo <= 0; // Reset the go signal
    end else begin
        if(rCnt<1023) begin
            rCnt<= rCnt+1; // Increment the counter
            rClkGo <= 0; // Keep the go signal low
        end else begin
            rCnt <= rCnt; // Keep the counter value
            rClkGo <= 1; // Set the go signal high
        end
    end
end

// Clock divider instance to generate the SPI clock
Clkdiv #( .CLKFREQ(ClkInFreq), .EXCEPTCLK(SPIClkFreq), .multipleX(2) ) u_SPICLK
        (   
            .iClk50M(iClk50M), // Input 50MHz clock
            .iRst_n(iRst_n), // Reset signal
            .oClk(wSPI_CLK) // Output SPI clock
        );

// Another clock divider instance for SPI clock with offset
Clkdiv #( .CLKFREQ(ClkInFreq), .EXCEPTCLK(SPIClkFreq), .multipleX(2) ) u_SPICLK_OUT
        (   
            .iClk50M(iClk50M), // Input 50MHz clock
            .iRst_n(rClkGo), // Reset signal based on the generated go signal
            .oClk(wSPI_CLK_OUT) // Output SPI clock with offset
        );




// Instantiate the SPI controller module named u_spi_controller
spi_controller u_spi_controller (
                .iRst_n(iRst_n), // System reset signal input
                .iSPI_CLK(wSPI_CLK), // SPI clock input
                .iSPI_CLK_OUT(wSPI_CLK_OUT), // SPI clock input with phase offset
                .iP2S_DATA(p2s_data), // Data from processor to SPI
                .iSPI_GO(spi_go), // Signal to start SPI transmission
                .oSPI_END(spi_end), // Signal indicating end of SPI transmission
                .oS2P_DATA(s2p_data), // Data from SPI to processor
                .oS2P_Dval(s2p_dval), // Data valid signal from SPI to processor
                .SPI_SDIO(SPI_SDIO), // SPI bidirectional data line
                .oSPI_CSN(oSPI_CSN), // SPI chip select signal output
                .oSPI_CLK(oSPI_CLK) // SPI clock output
);

//=======================================================
//  Structural coding
//=======================================================
// Initial Setting Table
// This block sets the configuration data based on the initialization index.
always @ (ini_index)
    case (ini_index)
        0      : write_data = {THRESH_ACT,      8'h20}; // Set activity threshold to 64
        1      : write_data = {THRESH_INACT,    8'h03}; // Set inactivity threshold to 3
        2      : write_data = {TIME_INACT,      8'h01}; // Set inactivity time to 1
        3      : write_data = {ACT_INACT_CTL,   8'h7f}; // Set ACT to DC-coupled, INACT to AC-coupled, and enable ACT_x,y,z and INACT_x,y,z
        4      : write_data = {THRESH_FF,       8'h09};
        5      : write_data = {TIME_FF,         8'h46};
        6      : write_data = {BW_RATE,         8'h0F}; // Set output data rate to 3200 Hz
        7      : write_data = {INT_ENABLE,      8'h80};
        8      : write_data = {INT_MAP,         8'h00}; // Map Activity to trigger INT2
        9      : write_data = {DATA_FORMAT,     8'b01001000}; /* Configure the data format: SPI 3-wire mode, 
                                                                 10-bit mode, 2's complement value, 
                                                                 and use a range of +-2g */
        default: write_data = {POWER_CONTROL,   8'h08}; // Default power control setting
    endcase

// This block handles the SPI state machine for initialization and data reading operations.
reg         rReadX; // Register to indicate if data is being read
reg [2:0]   rDelayCnt; // Register for delay count


// Always block triggered on SPI clock edge or system reset
always@(posedge wSPI_CLK or negedge iRst_n)
    if(!iRst_n)begin // If system reset is active
        ini_index <= 4'b0; // Initialize index
        spi_go <= 1'b0; // Reset SPI go signal
        spi_state <= IDLE; // Set SPI state to IDLE
        read_idle_count <= 0; // Reset read idle count (only for read mode)
        GSensorState <= GInit; // Set G-sensor state to initialization
        oAccDval <= 0; // Reset accelerometer data valid signal
        // Reset accelerometer data registers
        rAccData[0] <= 0; rAccData[1] <= 0; rAccData[2] <= 0;
        rAccData[3] <= 0; rAccData[4] <= 0; rAccData[5] <= 0;
        rAccCnt <= 0; // Reset accelerometer count
        rDtCnt <= 0; // Reset sensor time difference counter
        oSensorDt <= 0; // Reset sensor time difference output

    end
    // Initial setting (write mode)
    else begin
        // Maintain current values for these registers
        ini_index <= ini_index; spi_go <= spi_go;
        spi_state <= spi_state; read_idle_count <= read_idle_count;       
        GSensorState <= GSensorState;
        oAccDval <= 0; 
        // Maintain current accelerometer data values
        rAccData[0] <= rAccData[0]; rAccData[1] <= rAccData[1]; rAccData[2] <= rAccData[2];
        rAccData[3] <= rAccData[3]; rAccData[4] <= rAccData[4]; rAccData[5] <= rAccData[5];
        rAccCnt <= rAccCnt; rDtCnt <= rDtCnt; oSensorDt <= oSensorDt;
        // State machine for G-sensor operations
        case(GSensorState) 
            GInit: begin // Initial G-sensor state
                if(ini_index < INI_NUMBER) 
                    case(spi_state)
                        IDLE : begin // Write the Initial Setting Table to p2s_data
                           p2s_data <= {WRITE_MODE, 1'b0, write_data}; 
                           spi_go <= 1'b1; // Start SPI transmission
                           spi_state <= TRANSFER; // Set SPI state to TRANSFER
                        end
                        TRANSFER : begin
                            if (spi_end) begin // If SPI transfer ends
                              ini_index <= ini_index + 4'b1; // Increment initialization index
                              spi_go <= 1'b0; // Reset SPI go signal
                              spi_state <= IDLE; // Set SPI state back to IDLE
                            end
                        end
                        default: begin // Default case
                            spi_go <= 1'b0; // Reset SPI go signal
                            spi_state <= IDLE; // Set SPI state to IDLE
                        end
                    endcase
                else begin
                    spi_go <= 1'b0; // Reset SPI go signal
                    spi_state <= IDLE; // Set SPI state to IDLE
                    GSensorState <= GRun; // Change G-sensor state to run mode
                    rDtCnt <= 0; // Reset sensor time difference counter
                end
            end // GInit end
            GRun: begin // Read data and clear interrupt (read mode)
                case(spi_state)
                    IDLE : begin
                        // Increment idle read counter
                        read_idle_count <= read_idle_count + 1;
                        rAccCnt <= 0;           // Reset accelerometer count
                        rDtCnt <= rDtCnt +1;    // Increment sensor time difference counter
                        if (iG_INT2 ) begin     // If interrupt signal is active
                            oSensorDt <= rDtCnt; // Output the sensor time difference
                            // Set data from processor to SPI for read mode and interrupt source address
                            p2s_data <= {READ_MODE, 1'b1, X_LB, 8'b0}; // MultiByte Read
                            spi_go <= 1'b1;         // Start SPI transmission
                            spi_state <= DATAREADY; // Set SPI state to DATAREADY
                        end
                    end
                    TRANSFER : begin
                        rDelayCnt <= 0; // Reset delay counter
                        read_idle_count <= 0; // Reset read idle count
                        if (spi_end) begin // If SPI transfer ends
                            spi_go <= 1'b0; // Reset SPI go signal
                            if(s2p_data[7]) begin // If the 8th bit of s2p_data is set
                                spi_state <= DATAREADY; // Set SPI state to DATAREADY
                            end else begin
                                spi_state <= IDLE; // Set SPI state to IDLE
                            end
                        end
                    end
                    DATAREADY : begin // G-sensor data ready to read
                        // Set data from processor to SPI for read mode and low byte address
                        p2s_data <= {READ_MODE, 1'b1, X_LB, 8'b0}; // MultiByte Read
                        spi_go <= 1'b1; // Start SPI transmission
                        spi_state <= READDATA; // Set SPI state to READDATA
                        rAccCnt <= 0; // Reset accelerometer count
                    end
                    READDATA : begin // Receive data from g-sensor
                        if (spi_end) begin                  // If SPI transfer ends
                            spi_go <= 1'b0;                 // Reset SPI go signal
                            spi_state <= IDLE;              // Set SPI state to IDLE
                            read_idle_count <= 0;           // Reset read idle count
                            rAccData[rAccCnt] <= s2p_data;  // Store received data
                            rAccCnt <= 0;                   // Reset accelerometer count
                            oAccDval <= 1; // Set accelerometer data valid signal
                            // Update accelerometer output data
                            oAcc_X <= {rAccData[1], rAccData[0]};
                            oAcc_Y <= {rAccData[3], rAccData[2]};
                            oAcc_Z <= {s2p_data, rAccData[4]};
                            rDtCnt <= 0;                    // Reset sensor time difference counter
                        end
                        else if (s2p_dval) begin            // If data valid signal from SPI to processor is active
                            rAccData[rAccCnt] <= s2p_data;  // Store received data
                            rAccCnt <= rAccCnt+1;           // Increment accelerometer count
                        end
                    end
                    default: begin // Default case
                        p2s_data <= 0;      // MultiByte Read
                        spi_go <= 1'b0;     // Reset SPI go signal
                        spi_state <= IDLE;  // Set SPI state to IDLE
                        rAccCnt <= 0;       // Reset accelerometer count
                    end
                endcase
            end // GRun end
        endcase // case(GSensorState) end
    end // if(!iRst_n) else end


endmodule

/*
        0      : write_data = {THRESH_ACT,      8'h20};  設定動作閾值 64 
        1      : write_data = {THRESH_INACT,    8'h03};  設定不動作閾值 3
        2      : write_data = {TIME_INACT,      8'h01};  設定不動做時間 1 
        3      : write_data = {ACT_INACT_CTL,   8'h7f}; 設定不動做時間 1 
                                                        設定ACT為DC耦合，INACT為AC耦合，
                                                        並致能ACT_x,y,z和INACT_x,y,z 
        4      : write_data = {THRESH_FF,       8'h09};
        5      : write_data = {TIME_FF,         8'h46};
        6      : write_data = {BW_RATE,         8'h0F}; // output data rate : 3200 Hz 
        7      : write_data = {INT_ENABLE,      8'h10};
        8      : write_data = {INT_MAP,         8'h00};
        9      : write_data = {DATA_FORMAT,     8'b01001011};

Register 0x1D—THRESH_TAP (讀/寫)
   THRESH_TAP 暫存器是8位元，用於保存敲擊中斷的閾值。其數據格式是無符號的，因此，敲擊事件的大小會與 THRESH_TAP 中的值進行比較，
    以進行正常的敲擊檢測。其比例因子是62.5 mg/LSB（即，0xFF = 16 g）。如果啟用單次敲擊/雙次敲擊中斷，值為0可能會導致不希望的行為。

Register 0x1E, Register 0x1F, Register 0x20—OFSX, OFSY, OFSZ (讀/寫)
   OFSX、OFSY 和 OFSZ 暫存器都是8位元，提供用戶設置的偏移調整，其格式是二補數格式，比例因子是15.6 mg/LSB（即，0x7F = 2 g）。
    存儲在偏移暫存器中的值會自動添加到加速度數據中，並將結果值存儲在輸出數據暫存器中。有關偏移校正和使用偏移暫存器的更多信息，請參考偏移校正部分。

Register 0x21—DUR (讀/寫)
   DUR 暫存器是8位元，包含一個無符號的時間值，表示一個事件必須超過 THRESH_TAP 閾值的最大時間，以符合敲擊事件的資格。
    其比例因子是625 μs/LSB。值為0會禁用單次敲擊/雙次敲擊功能。

Register 0x22—Latent (讀/寫)
   Latent 暫存器是8位元，包含一個無符號的時間值，表示從檢測到敲擊事件到開始可能檢測到第二次敲擊事件的時間窗口（由窗口註冊器定義）的等待時間。
    其比例因子是1.25 ms/LSB。值為0會禁用雙次敲擊功能。

Register 0x23—Window (讀/寫)
   Window 暫存器是8位元，包含一個無符號的時間值，表示在延遲時間過期後（由 latent 暫存器確定）期間，可以開始第二次有效敲擊的時間量。
    其比例因子是1.25 ms/LSB。值為0會禁用雙次敲擊功能。

Register 0x24—THRESH_ACT (Read/Write)
   THRESH_ACT暫存器用於設定檢測到的動作或活動的閾值。當感測器檢測到的動作或活動的幅度超過這個閾值時，它會產生一個中斷或通知。
    這個註冊器的數據格式是無符號的，這意味著它只能表示正數。每一位的增量或比例因子是62.5 mg，這意味著如果你在暫存器中設定了一個值，例如4，
    那麼實際的閾值將是250 mg（4 x 62.5 mg）。如果這個值設定為0，並且活動中斷被啟用，那麼任何微小的動作都可能觸發中斷，這可能不是使用者所期望的行為。
    因此，使用者應該根據他們的應用需求適當地設定這個閾值。
    
Register 0x25—THRESH_INACT (Read/Write)
   THRESH_INACT註冊器用於設定檢測到的不活動或靜止的閾值。當感測器檢測到的不活動或靜止的時間超過這個閾值時，它會產生一個中斷或通知。
    這個註冊器的數據格式是無符號的，這意味著它只能表示正數。每一位的增量或比例因子是62.5 mg，這意味著如果你在註冊器中設定了一個值，例如4，
    那麼實際的閾值將是250 mg（4 x 62.5 mg）。如果這個值設定為0，並且不活動中斷被啟用，那麼任何微小的不活動都可能觸發中斷，
    這可能不是使用者所期望的行為。因此，使用者應該根據他們的應用需求適當地設定這個閾值。

Register 0x2C—BW_RATE (Read/Write)
      D7 D6 D5    D4       D3-D0
       0  0  0 LOW_POWER   Rate
   LOW_POWER 位元：這是一個用於控制設備功耗模式的位元。當它被設置為0時，設備將在正常模式下運行。
                   當它被設置為1時，設備將進入低功耗模式，但這會增加噪音。
   Rate 位元：這些位元用於設定設備的頻寬和輸出數據速率。預設的輸出數據速率是100 Hz。
               使用者應該根據他們的通信協議和頻率選擇一個適當的輸出數據速率。如果選擇了一個過高的輸出數據速率，
                  但通信速度很低，那麼一些數據樣本可能會被丟棄，這不是理想的情況。

Register 0x2E—INT_ENABLE (Read/Write)
       D7         D6         D5        D4
   DATA_READY SINGLE_TAP DOUBLE_TAP Activity
       D3         D2         D1        D0
   Inactivity FREE_FALL   Watermark  Overrun
   該暫存器用於控制哪些功能可以產生中斷。當暫存器中的某一位被設置為1時，與該位相對應的功能將被允許產生中斷。
    相反，如果該位被設置為0，則該功能不會產生中斷。
    特別地，DATA_READY、watermark和overrun這三個位只控制是否允許其相應的功能產生中斷輸出，但不影響這些功能本身的啟用狀態，這些功能始終是啟用的。
   最後建議的做法是先配置中斷（即確定哪些功能應該產生中斷），然後再啟用它們的中斷輸出。這樣可以確保在中斷輸出被啟用之前，所有的配置都已正確設置。
          
Register 0x2F—INT_MAP (R/W)
        D7        D6        D5        D4
    DATA_READY SINGLE_TAP DOUBLE_TAP Activity
        D3         D2        D1        D0
    Inactivity FREE_FALL Watermark   Overrun
   該暫存器決定了中斷信號應該發送到哪個引腳。如果某一bit在這個暫存器中被設置為0，那麼與該bit相對應的中斷將被發送到INT1引腳。
    相反，如果該位被設置為1，則中斷將被發送到INT2引腳。
    如果選定了多個中斷發送到同一引腳，那麼這些中斷信號將會進行邏輯"or"操作，只要其中一個中斷被觸發，該引腳就會收到中斷信號。

Register 0x30—INT_SOURCE (Read Only)
         D7          D6          D5           D4
    DATA_READY, SINGLE_TAP, DOUBLE_TAP,   Activity
         D3         D2         D1        D0
    Inactivity, FREE_FALL, Watermark, Overrun

    DATA_READY: 這通常表示新的數據已經準備好並可以從感測器讀取。例如，當一個加速度計完成一次新的加速度測量時，
                    它可能會設置DATA_READY中斷來通知主控制器可以讀取新的數據。
    SINGLE_TAP: 這通常表示感測器已經檢測到一次短暫的、快速的動作，就像某物被輕敲一下。在加速度計的上下文中，
                    這可能意味著裝置已經受到了一次短暫的撞擊或震動。
    DOUBLE_TAP: 這表示感測器已經檢測到兩次短暫的、快速的動作，彼此之間的間隔非常短，就像某物被輕敲兩下。
                    這通常用於檢測特定的用戶輸入，例如雙擊裝置的表面。
    Activity: 這表示感測器已經檢測到一定程度的動作或運動。例如，加速度計可能會使用此中斷來指示裝置已從靜止狀態變為移動狀態。
    Inactivity: 這表示感測器在一段時間內沒有檢測到任何顯著的運動或動作。這可以用來檢測裝置是否已經放置不動一段時間，
                    可能用於進入低功耗模式或其他相關的功能。
    FREE_FALL: 這表示感測器檢測到一種特定的運動模式，這通常與自由落體相符。當裝置突然下降（例如從桌子上掉下來）時，加速度計可能會觸發此中斷。
    Watermark: 在FIFO（First In, First Out）緩衝區的上下文中，水印是一個預設的閾值，當緩衝區中的數據點數達到或超過這個值時，
                  會觸發一個中斷。這允許主控制器知道現在是時候讀取一批數據，而不是等到緩衝區滿。
    Overrun: 這表示FIFO緩衝區已滿，並且新的數據點已經開始覆蓋或丟棄最舊的數據。這是一個警告，表明主控制器沒有足夠快地讀取數據，導致數據丟失。

Register 0x31—DATA_FORMAT (Read/Write) 
    D7: self_test
    D6: SPI bit, set 1to 3 wires mode, 0 to 4 wires
    D5: Int_Invert
    D4: 0
    D3: When FULL_RES bit is set to 0, the device is in 10-bit mode,
        When FULL_RES bit is set to 1, the device is in full resoultion mode, 
    Justify Bit=0, 表示讀進來的數值是2補數數值
    range bit=2'b00, 表示是使用+-2g範圍








*/

