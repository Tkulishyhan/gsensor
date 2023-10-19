// This module defines an SPI controller.
module spi_controller (
                            iRst_n,
                            iSPI_CLK,
                            iSPI_CLK_OUT,
                            iP2S_DATA,
                            iSPI_GO,
                            iMultiBytes, // Enable Multi-Bytes when set to 1
                            oSPI_END,
                            oS2P_DATA,   // Data read from SPI
                            oS2P_Dval,   // Data valid signal for oS2P_DATA
                            // SPI 3-wire interface
                            SPI_SDIO,
                            oSPI_CSN,   
                            oSPI_CLK);

// Include SPI related parameter definitions
`include "spi_param.h"	

//=======================================================
//  PORT declarations
//=======================================================
// Host Side Interface
input                       iRst_n;          // System reset signal
input                       iSPI_CLK;        // SPI clock input
input                       iSPI_CLK_OUT;    // SPI clock input with phase offset
input       [SI_DataL-1:0]  iP2S_DATA;       // Data input from host to slave
input                       iSPI_GO;         // Signal to start SPI transfer
output                      oSPI_END;        // Signal indicating end of SPI transfer
output  reg [SO_DataL-1:0]  oS2P_DATA;       // SPI read data output
output  reg                 oS2P_Dval;       // Data valid signal for oS2P_DATA
input                       iMultiBytes;     // Enable multi-byte mode when set to 1

// SPI Interface
inout                       SPI_SDIO;        // SPI bidirectional data line
output                      oSPI_CSN;        // SPI chip select signal
output                      oSPI_CLK;        // SPI clock output signal

//=======================================================
//  REG/WIRE declarations
//=======================================================
wire           read_mode;       // Indicates if the operation is in read mode
wire           write_address;   // Address for write operation
reg            spi_count_en;    // Enable signal for SPI counter
reg     [5:0]  spi_count;       // 6-bit counter for SPI operations
wire           wMultiByte;      // Wire for multi-byte mode
reg            rMultiByte;      // Register for multi-byte mode

//=======================================================
//  Structural coding
//=======================================================
// Assignments for determining the mode of operation and other control signals
assign read_mode = iP2S_DATA[SI_DataL-1];   // Extract the read mode bit from the data input
assign wMultiByte = iP2S_DATA[SI_DataL-2];  // Extract the multi-byte mode bit from the data input
assign write_address = spi_count[3];        // Extract the write address from the SPI count
assign oSPI_END = ~|spi_count;              // SPI end signal is active when all bits of spi_count are zero
assign oSPI_CSN = ~iSPI_GO;                 // SPI chip select is the negation of the SPI go signal
assign oSPI_CLK = spi_count_en ? iSPI_CLK_OUT : 1'b1; // SPI clock is determined by the enable signal and the input clock

// Determine the SPI data line value based on various conditions
assign SPI_SDIO = spi_count_en && // Check if SPI count is enabled
                  (!read_mode ||  // Check if it's not a read operation
                   (wMultiByte ?  // If in multi-byte mode
                    ((spi_count < 49) ? 0 : 1) :  // Determine condition based on SPI count
                    ((spi_count < 9) ? 0 : 1)))  // Determine condition based on SPI count for non-multi-byte mode
                  ? iP2S_DATA[rDataCnt]  // Drive data onto SPI_SDIO line
                  : 1'bz;  // Otherwise, set to high-impedance state

// Register to keep track of data count
reg [3:0]  rDataCnt;

// Sequential logic for SPI controller operation
always @ (posedge iSPI_CLK or negedge iRst_n)begin
   if (!iRst_n) begin
        // Reset all registers to their default states when reset is active
        spi_count_en <= 1'b0;       // Disable SPI count
        spi_count <= 6'h3f;          // Reset SPI count to maximum value
        rDataCnt <=  4'hf;          // Reset data count to maximum value
        oS2P_Dval <= 0;             // Reset data valid signal
        oS2P_DATA <= 0;             // Clear SPI read data
        rMultiByte <= 0;            // Reset multi-byte mode flag
   end
   else begin
        // Default assignments (maintain previous states)
        oS2P_Dval <= oS2P_Dval; oS2P_DATA <= oS2P_DATA;
        rMultiByte <= rMultiByte;

        // Control logic for SPI count enable
        if (oSPI_END)
            spi_count_en <= 1'b0;   // Disable SPI count when SPI operation ends
        else if (iSPI_GO) 
            spi_count_en <= 1'b1;   // Enable SPI count when SPI operation starts
        else
            spi_count_en <= spi_count_en; // Maintain previous state otherwise

        // Control logic for data count and SPI count
        if (!spi_count_en) begin
            rDataCnt <= 4'hf;       // Reset data count
            oS2P_Dval <= 0;         // Reset data valid signal
            rMultiByte <= wMultiByte; // Update multi-byte mode flag based on input
            spi_count <= wMultiByte ? 6'd56 : 6'd16; // Determine SPI count based on multi-byte mode
        end	
        else begin
            spi_count <= spi_count - 6'b1; // Decrement SPI count
            rDataCnt <= rDataCnt - 1;      // Decrement data count
        end

        // Logic for reading data from SPI
        if (read_mode) begin
            case(rMultiByte)
                0: begin
                    if(spi_count < 9) 
                        oS2P_DATA <= {oS2P_DATA[SO_DataL-1:0], SPI_SDIO}; // Update data based on SPI data line

                    if(spi_count == 6'd1)
                        oS2P_Dval <= 1; // Set data valid signal when data is ready
                end
                1: begin
                    if(spi_count < 49) 
                        oS2P_DATA <= {oS2P_DATA[SO_DataL-1:0], SPI_SDIO}; // Update data based on SPI data line

                    // Set data valid signal at specific counts
                    if((spi_count == 6'd41) || (spi_count == 6'd33) || (spi_count == 6'd25) || (spi_count == 6'd17) || (spi_count == 6'd9) || (spi_count == 6'd1))
                        oS2P_Dval <= 1; // Set data valid signal when data is ready
                    else
                        oS2P_Dval <= 0; // Reset data valid signal otherwise
                end
            endcase
        end
   end
end



endmodule