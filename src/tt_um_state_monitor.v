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

    
    assign uo_out[7:1] = 0;

    // use bidirectionals as inputs
    assign uio_oe = 8'b0000_1111;
    assign uio_out = 8'b0;

    // external inputs setup the delay value of state transients
    wire [3:0] compare = uio_in[7:3];


    state_monitor state_monitor(
        .resetn(resetn),
        .i_clk(clk),
        .i_signal(ui_in[0]),
        .i_polarity(ui_in[4]),
        .o_valid(uo_out[0]),
        .i_compare(compare)
    );

endmodule


module state_monitor(
    input wire i_reset,  //active high
    input wire i_clk,
    input wire i_signal,
    input wire i_polarity,
    output wire o_valid,
    input wire [3:0] i_compare
);

    // external clock is 10kHz, so need 16 bit counter to count to 160.000. (16s delay of transients)
    reg [15:0] r_counter;

    reg r_buf_signal;

    localparam STATE_IDLE = 0;
    localparam STATE_TRANSIENT = 1;
    reg [1:0] r_state;


    wire w_invalid_detected = (i_polarity) ? (r_buf_signal != i_signal) &&  (i_signal == 1'b0) :
                                             (r_buf_signal != i_signal) &&  (i_signal == 1'b1) ;



    always @(posedge i_clk) begin
        // if reset, set counter to 0
        if (i_reset) begin
            r_counter <= 0;
            r_state <= 0;
            r_buf_signal <= 0;
        end else begin
            r_buf_signal <= i_signal;

            case (r_state)
                STATE_IDLE: begin
                r_counter <= 10000 * i_compare;
                r_state <= (w_invalid_detected) ? STATE_TRANSIENT : STATE_IDLE;
                end
                STATE_TRANSIENT: begin
                    r_counter <= r_counter - 1;
                    r_state <= (r_counter == 0)&&(~w_invalid_detected) ? STATE_IDLE : STATE_TRANSIENT;
                end
            endcase
        end 
    end

endmodule