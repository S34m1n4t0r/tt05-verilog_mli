`default_nettype none

module tt_um_state_monitor #( parameter MAX_COUNT = 24'd10_000_000 ) (
    input  wire [7:0] ui_in,    // Dedicated inputs 
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Bidirectional Input path
    output wire [7:0] uio_out,  // IOs: Bidirectional Output path
    output wire [7:0] uio_oe,   // IOs: Bidirectional Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // will go high when the design is enabled
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

    wire reset = ! rst_n;
    wire [7:0] led_out;
    wire       led_state_change;
    wire       polarity;
    wire [3:0] delay_cnt;

    
    assign uo_out[6:0] = (r_state== STATE_TRANSIENT) ? 7'b1111111 : 0;
    assign uo_out[7] = 1'b0;

    // use bidirectionals as inputs
    assign uio_oe = 8'b11111111;
    assign uio_out = 8'b0;

    // external clock is 10kHz, so need 16 bit counter to count to 160.000. (16s delay of transients)
    reg [15:0] r_counter;

    reg [7:0] r_input_buffer;

    // external inputs setup the delay value of state transients
    wire [3:0] compare = uio_in[7:3];

    localparam STATE_IDLE = 0;
    localparam STATE_TRANSIENT = 1;
    reg [1:0] r_state;


    always @(posedge clk) begin
        // if reset, set counter to 0
        if (reset) begin
            r_counter <= 0;
            r_input_buffer <= 0;
            r_state <= 0;
        end else begin
            r_input_buffer <= ui_in;

            case (r_state)
                STATE_IDLE: begin
                r_counter <= 10000 * compare;
                r_state <= (r_input_buffer != ui_in) ? STATE_TRANSIENT : STATE_IDLE;
                end
                STATE_TRANSIENT: begin
                    r_counter <= r_counter - 1;
                    r_state <= (r_counter == 0) ? STATE_IDLE : STATE_TRANSIENT;
                end
            endcase
        end 
    end
endmodule
