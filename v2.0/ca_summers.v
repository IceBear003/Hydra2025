`include "uuu_fp19_add.v"
module ca_summers(
    input clk,
    input rst_n,

    input clear,
    input en,

    input [6*19-1:0] rank_3_flat,

    output reg next_clear,
    output reg next_en,
    output [3*19-1:0] summation_flat
);

reg en_d1;
reg clear_d1;

always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        en_d1 <= 0;
        next_en <= 0;
        clear_d1 <= 0;
        next_clear <= 0;
    end else begin
        en_d1 <= en;
        next_en <= en_d1;
        clear_d1 <= clear;
        next_clear <= clear_d1;
    end
end

wire [18:0] stage_1_sums [4:0];

genvar i1;
generate for(i1 = 0; i1 < 5; i1 = i1 + 1) begin: Stage_1_Adder
    uuu_fp19_add adder(
        .clk(clk),
        .rst_n(rst_n),
        .en(en),
        .a(rank_3_flat[i1*19+18:i1*19]),
        .b(rank_3_flat[i1*19+37:i1*19+19]),
        .sum(stage_1_sums[i1])
    );
end endgenerate

genvar i2;
generate for(i2 = 0; i2 < 3; i2 = i2 + 1) begin: Stage_2_Adder
    wire [18:0] summation;
    assign summation_flat[i2*19+18:i2*19] = summation;

    uuu_fp19_add adder(
        .clk(clk),
        .rst_n(rst_n),
        .en(en_d1),
        .a(stage_1_sums[i2]),
        .b(stage_1_sums[i2+2]),
        .sum(summation)
    );
end endgenerate
endmodule