module x_movement_calculation (
    input clk,             // Clock signal
    input rst_n,           // Active-low reset
    input signed [15:0] acc_x_raw,    // Raw 16-bit 2's complement acceleration data on X-axis
    input [15:0] dt,       // Time step in some unit (e.g., milliseconds)
    input data_valid,      // Signal to indicate valid acceleration data
    output reg signed [31:0] displacement, // 32-bit displacement value
    output reg output_valid // Signal to indicate valid displacement data
);

// Subtracting gravitational acceleration from raw acceleration
wire signed [15:0] acc_x; 

// Assuming a 16-bit 2's complement representation for acceleration
reg signed [31:0] velocity = 32'sd0; // Integrated acceleration -> velocity
reg signed [31:0] prev_velocity = 32'sd0; // Previous velocity value for trapezoidal integration

parameter IDLE=0, CALC_VELOCITY=1, CALC_DISPLACEMENT=2, STORE_VELOCITY=3;
reg [1:0] current_state = IDLE;
reg [1:0] next_state = IDLE;

assign acc_x = acc_x_raw - 16'sd1000;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        velocity <= 32'sd0;
        displacement <= 32'sd0;
        output_valid <= 1'b0;
        current_state <= IDLE;
    end else begin
        current_state <= next_state;
        case (current_state)
            IDLE: begin
                if (data_valid) begin
                    next_state <= CALC_VELOCITY;
                end else begin
                    next_state <= IDLE;
                end
            end

            CALC_VELOCITY: begin
                velocity <= velocity + (acc_x * dt);
                next_state <= CALC_DISPLACEMENT;
            end

            CALC_DISPLACEMENT: begin
                displacement <= displacement + ((velocity + prev_velocity) >> 1) * dt;
                next_state <= STORE_VELOCITY;
            end

            STORE_VELOCITY: begin
                prev_velocity <= velocity;
                output_valid <= 1'b1;
                next_state <= IDLE;
            end
        endcase
    end
end

endmodule
