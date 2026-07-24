module uart_tx #(parameter MAX = 13'd10416)(
    input wire clk,
    input wire reset,
    input wire tx_start,
    input wire [7:0] tx_data,
    output reg tx
);

    localparam IDLE = 1'b0;
    localparam SEND = 1'b1;

    reg state;

    reg [9:0] shift_reg;   // 1 start + 8 data + 1 stop
    reg [13:0] baud;       // cycle counter
    reg [3:0] bit_count;   // counts up to 10 bits

    always @(posedge clk) begin
        if (reset) begin
            state <= IDLE;
            shift_reg <= 10'b1111111111;
            tx <= 1'b1;
            baud <= 0;
            bit_count <= 0;

        end else begin
            case (state)

                IDLE: begin
                    tx <= 1'b1;

                    if (tx_start) begin
                        shift_reg <= {1'b1, tx_data, 1'b0};
                        baud <= 0;
                        bit_count <= 0;
                        state <= SEND;
                    end
                end
                SEND: begin
                    if (baud == MAX) begin
                        baud <= 0;

                        tx <= shift_reg[0];

                        shift_reg <= {1'b1, shift_reg[9:1]};

                        bit_count <= bit_count + 1'b1;

                        if (bit_count == 4'd9) begin
                            state <= IDLE;
                        end
                    end else begin
                        baud <= baud + 1'b1;
                    end
                end
            endcase
        end
    end
endmodule

