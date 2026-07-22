module uart_tx (
    input wire clk,
    input wire reset,
    input wire tx_start,
    input wire [7:0] tx_data,
    output reg tx
);

    reg [13:0] shift_reg;

    always @(posedge clk) begin
        if (reset) begin
            shift_reg <= 14'b11111111111111;
            tx <= 1'b1;  
        end else begin
            if (tx_start) begin
                // Load frame:
                //
                // [stop][data][start]
                //
                // start = 0
                // stop  = 1
                //
                shift_reg <= {1'b1, tx_data, 1'b0};
            end else begin
                // Output current LSB
                tx <= shift_reg[0];
                shift_reg <= {1'b0, shift_reg[9:1]};
            end
        end
    end
endmodule

