`include "uuu_fp18_add.v"
module accumulators(
    input clk,
    input rst_n,

    input [2:0] rx,
    input [2:0] tx,

    input accumulator_en,
    input [6*18-1:0] magnitudes,

    output os_en,
    output [6*18-1:0] accumulations
);

reg [2:0] rx_cnt;
reg [2:0] tx_cnt;

always @(posedge clk) begin 
    if(~rst_n) begin
        rx_cnt <= 0;
        tx_cnt <= 0;
    end else if(~accumulator_en) begin
    end else if(rx_cnt != rx) begin
        rx_cnt <= rx_cnt + 1;
    end else if(tx_cnt != tx) begin
        rx_cnt <= 0;
        tx_cnt <= tx_cnt + 1;
    end else begin
        rx_cnt <= 0;
        tx_cnt <= 0;
    end
end

reg accumulation_over;
reg accumulation_over_d1;
assign os_en = accumulation_over_d1;

always @(posedge clk) begin
    if(~rst_n) begin
        accumulation_over <= 0;
        accumulation_over_d1 <= 0;
    end else begin
        accumulation_over <= (rx_cnt == rx) && (tx_cnt == tx) && accumulator_en;
        accumulation_over_d1 <= accumulation_over;
    end
end

genvar index;
generate for(index = 0; index < 6; index = index + 1) begin: ACC

wire [17:0] accumulation;
assign accumulations[index*18+17:index*18] = accumulation;
wire [17:0] magnitude = magnitudes[index*18+17:index*18];

uuu_fp18_add adder (
    .clk(clk),
    .rst_n(rst_n),

    .enable(accumulator_en),
    .rst(accumulation_over_d1),

    .a(accumulation),
    .b(magnitude),
    .sum(accumulation)
);

end endgenerate

endmodule