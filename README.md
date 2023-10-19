Overview
The DE0_NANO_G_Sensor module is designed to interface with the G-sensor on the DE0 Nano board. The module reads data from the G-sensor, processes it, and provides outputs for LEDs and other peripherals. The module also interfaces with keys for reset functionality and provides SPI communication for the G-sensor.

Module Description
Inputs:
CLOCK_50: 50MHz clock input.
KEY[1:0]: Two input keys, where KEY[0] is used for reset.
G_SENSOR_INT: Interrupt signal input from the G-sensor.
Outputs:
LED[7:0]: 8-bit LED output.
G_SENSOR_CS_N: Chip select output for the G-sensor.
I2C_SCLK: SPI clock output.
I2C_SDAT: SPI bidirectional data line.
GPIO[35:0]: 36-bit general-purpose output.
Internal Modules:
DataCalcRate (u_DataCalcRate):

Calculates the data rate.
Inputs: iClk50M, iRst_n, iDataValid
Outputs: oDataRateSec
Reset Delay (u_reset_delay):

Generates a delayed reset signal.
Inputs: iRSTN, iCLK
Outputs: oRST
SPI Configuration (u_spi_ee_config):

Configures SPI and reads back data.
Inputs: iClk50M, iRst_n, iG_INT2, SPI_SDIO
Outputs: oAcc_X, oAcc_Y, oAcc_Z, oAccDval, oSPI_CSN, oSPI_CLK
LED Driver (u_led_driver):

Drives the LED display.
Inputs: iRSTN, iCLK, iDIG, iG_INT2
Outputs: oLED
G-Sensor Pose (GSensorPose):

Determines the pose or orientation based on G-sensor data.
Inputs: iClk50Mhz, iRst_n, iDataX, iDataXVal
Outputs: oPosDval, oXpos
Usage:
To use this module, connect the appropriate signals to the inputs and outputs. Ensure that the G-sensor is correctly interfaced with the DE0 Nano board. Provide a 50MHz clock signal to the CLOCK_50 input and monitor the outputs as required.

Notes:
Ensure that the G-sensor is correctly initialized before reading data.
The reset functionality is triggered by KEY[0].
The SPI communication is set up for 3-wire mode.
Future Enhancements:
Implement filtering for G-sensor data to reduce noise.
Add more functionalities like data logging or interfacing with other peripherals.
# gsensor
Maximal read gsensor data from de0-nano board
![image](https://github.com/Tkulishyhan/gsensor/assets/80139795/26d71a9c-e2fb-4234-a03d-aaabb245af35)
From the signaltap waveform, we can get the maixmal ODR is 3047.

Contributors:
Shih-An Li, from T.K.U. Taiwan.
