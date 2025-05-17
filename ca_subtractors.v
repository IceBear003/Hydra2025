`include "uuu_fp18_add.v"
`include "uus_fp18_sub.v"
module ca_subtractors(
    input clk,
    input rst_n,

    input clear,
    input en,

    input [6*18-1:0] rank_3_flat,

    output reg next_clear,
    output reg next_en,
    output [3*19-1:0] subtraction_flat
);

reg en_d1;
reg en_d2;
reg clear_d1;
reg clear_d2;

always @(posedge clk) begin
    if(~rst_n) begin
        en_d1 <= 0;
        en_d2 <= 0;
        next_en <= 0;
        clear_d1 <= 0;
        clear_d2 <= 0;
        next_clear <= 0;
    end else begin
        en_d1 <= en;
        en_d2 <= en_d1;
        next_en <= en_d2;
        clear_d1 <= clear;
        clear_d2 <= clear_d1;
        next_clear <= clear_d2;
    end
end

wire [17:0] stage_1_sums [4:0];

genvar i1;
generate for(i1 = 0; i1 < 5; i1 = i1 + 1) begin: Stage_1_Adder
    uuu_fp18_add adder(
        .clk(clk),
        .rst_n(rst_n),
        .en(en),
        .a(rank_3_flat[i1*18+17:i1*18]),
        .b(rank_3_flat[i1*18+35:i1*18+18]),
        .sum(stage_1_sums[i1])
    );
end endgenerate

wire [17:0] stage_2_sums [2:0];

genvar i2;
generate for(i2 = 0; i2 < 3; i2 = i2 + 1) begin: Stage_2_Adder
    uuu_fp18_add adder(
        .clk(clk),
        .rst_n(rst_n),
        .en(en_d1),
        .a(stage_1_sums[i2]),
        .b(stage_1_sums[i2+2]),
        .sum(stage_2_sums[i2])
    );
end endgenerate

genvar i3;
generate for(i3 = 0; i3 < 3; i3 = i3 + 1) begin: Stage_3_Subtracter
    reg [17:0] old_sum;
    
    always @(posedge clk) begin
        if(~rst_n) begin
            old_sum <= 18'b0;
        end else if(en_d2) begin
            old_sum <= stage_2_sums[i3];
        end
    end

    uus_fp18_sub subtracter(
        .clk(clk),
        .rst_n(rst_n),
        .en(en_d2),
        .a(stage_2_sums[i3]),
        .b(old_sum),
        .diff(subtraction_flat[i3*19+18:i3*19])
    );
end endgenerate
endmodule