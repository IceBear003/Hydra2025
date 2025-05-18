`include "uuu_fp19_acc.v"
module magnitude_accumulators(
    input clk,
    input rst_n,

    input [2:0] rx,
    input [2:0] tx,

    input en,
    input [9*19-1:0] magnitude_flat,

    output reg next_en,
    output [9*19-1:0] accumulation_flat
);

reg [2:0] rx_cnt;
reg [2:0] tx_cnt;

always @(posedge clk or negedge rst_n) begin 
    if(~rst_n) begin
        rx_cnt <= 0;
        tx_cnt <= 0;
    end else if(~en) begin
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

always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        next_en <= 0;
    end else begin
        next_en <= (rx_cnt == rx) && (tx_cnt == tx) && en;
    end
end

genvar i;
generate for(i = 0; i < 9; i = i + 1) begin: Accumulator
    wire [18:0] accumulation;
    wire [18:0] magnitude = magnitude_flat[i*19+18:i*19];
    assign accumulation_flat[i*19+18:i*19] = accumulation;

    uuu_fp19_acc accumulator (
        .clk(clk),
        .rst_n(rst_n),
        .clear(next_en),
        .en(en),
        .a(accumulation),
        .b(magnitude),
        .sum(accumulation)
    );
end endgenerate
endmodule