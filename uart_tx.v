module uart_tx #(parameter MAX = 13'd10416)(
    input wire clk,
    input wire reset,
    input wire tx_start,
    input wire [7:0] tx_data,
    output reg tx
);

    reg [9:0] shift_reg;
    reg [13:0] baud;

    always @(posedge clk) begin
        if (reset) begin
            shift_reg <= 10'b1111111111;
            tx <= 1'b1;
            baud <= 14'd0;
        end else begin

            if (baud == MAX) begin
                baud <= 14'd0;

                tx <= shift_reg[0];
                shift_reg <= {1'b1, shift_reg[9:1]};

            end else begin
                baud <= baud + 1'b1;
            end

            if (tx_start) begin
                shift_reg <= {1'b1, tx_data, 1'b0};
            end

        end
    end

endmodule

