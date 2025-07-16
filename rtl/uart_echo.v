// uart_echo.v
// Simple UART echo transceiver
// 1 start, 8 data, 1 stop bit
// Parameters: CLK_FREQ (Hz) and BAUD_RATE

module uart_echo #(
    parameter integer CLK_FREQ  = 50_000_000,
    parameter integer BAUD_RATE = 115_200
)(
    input  wire clk,
    input  wire rst,
    input  wire rx,
    output reg  tx
);

    localparam integer CLKS_PER_BIT = CLK_FREQ / BAUD_RATE;

    // RX signals
    reg [3:0]  rx_state   = 0;
    reg [31:0] rx_clk_cnt = 0;
    reg [2:0]  rx_bit_idx = 0;
    reg [7:0]  rx_byte    = 0;
    reg        rx_done    = 0;

    // TX signals
    reg [3:0]  tx_state   = 0;
    reg [31:0] tx_clk_cnt = 0;
    reg [2:0]  tx_bit_idx = 0;
    reg [7:0]  tx_byte    = 0;
    reg        tx_active  = 0;

    // TX line idle high
    initial tx = 1;

    // Main FSM
    always @(posedge clk) begin
        if (rst) begin
            rx_state  <= 0;
            rx_done   <= 0;
            tx_state  <= 0;
            tx_active <= 0;
            tx        <= 1;
        end else begin
            //------------------------------------------------------------------
            // RX logic
            //------------------------------------------------------------------
            case (rx_state)
                0: begin  // Idle, wait for start bit
                    if (rx == 0) begin
                        rx_clk_cnt <= 0;
                        rx_state   <= 1;
                    end
                end
                1: begin  // Start bit (middle sample)
                    if (rx_clk_cnt == (CLKS_PER_BIT/2)) begin
                        rx_clk_cnt <= 0;
                        rx_bit_idx <= 0;
                        rx_state   <= 2;
                    end else
                        rx_clk_cnt <= rx_clk_cnt + 1;
                end
                2: begin  // Data bits
                    if (rx_clk_cnt == CLKS_PER_BIT-1) begin
                        rx_clk_cnt          <= 0;
                        rx_byte[rx_bit_idx] <= rx;
                        if (rx_bit_idx == 7)
                            rx_state <= 3;
                        else
                            rx_bit_idx <= rx_bit_idx + 1;
                    end else
                        rx_clk_cnt <= rx_clk_cnt + 1;
                end
                3: begin  // Stop bit
                    if (rx_clk_cnt == CLKS_PER_BIT-1) begin
                        rx_done <= 1;
                        rx_state <= 0;
                    end else
                        rx_clk_cnt <= rx_clk_cnt + 1;
                end
            endcase

            //------------------------------------------------------------------
            // TX logic
            //------------------------------------------------------------------
            if (rx_done && !tx_active) begin
                tx_byte   <= rx_byte;
                tx_active <= 1;
                tx_state  <= 0;
                rx_done   <= 0;
            end

            if (tx_active) begin
                case (tx_state)
                    0: begin  // Start bit
                        tx <= 0;
                        if (tx_clk_cnt == CLKS_PER_BIT-1) begin
                            tx_clk_cnt <= 0;
                            tx_bit_idx <= 0;
                            tx_state   <= 1;
                        end else
                            tx_clk_cnt <= tx_clk_cnt + 1;
                    end
                    1: begin  // Data bits
                        tx <= tx_byte[tx_bit_idx];
                        if (tx_clk_cnt == CLKS_PER_BIT-1) begin
                            tx_clk_cnt <= 0;
                            if (tx_bit_idx == 7)
                                tx_state <= 2;
                            else
                                tx_bit_idx <= tx_bit_idx + 1;
                        end else
                            tx_clk_cnt <= tx_clk_cnt + 1;
                    end
                    2: begin  // Stop bit
                        tx <= 1;
                        if (tx_clk_cnt == CLKS_PER_BIT-1) begin
                            tx_active <= 0;        // done with this byte
                            tx_state  <= 0;        // <-- back to idle
                            tx_clk_cnt <= 0;       // (optional house-keeping)
                        end else
                            tx_clk_cnt <= tx_clk_cnt + 1;
                    end
                endcase
            end
        end
    end
endmodule
