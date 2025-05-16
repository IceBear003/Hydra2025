module diff(
    input clk,
    input rst_n,

    input en,
    input rst,

    input [6*18-1:0] rank_3s,

    output reg summation_en,
    output [3*19-1:0] differences
);

reg stage_2_en;
reg stage_3_en;

always @(posedge clk) begin
    if(~rst_n) begin
        stage_2_en <= 0;
        stage_3_en <= 0;
        summation_en <= 0;
    end else begin
        stage_2_en <= en;
        stage_3_en <= stage_2_en;
        summation_en <= stage_3_en;
    end
end

wire [14:0] stage_1_sums [4:0];

genvar index_1;
generate for(index_1 = 0; index_1 < 5; index_1 = index_1 + 1) begin: Stage_1_Adders
uuu_fp18_add adder(
    .clk(clk),
    .rst_n(rst_n),

    .en(en),

    .a(rank_3s[index_1*18+17:index_1*18]),
    .b(rank_3s[index_1*18+35:index_1*18+18]),
    .sum(stage_1_sums[index_1])
);
end endgenerate

wire [14:0] stage_2_sums [2:0];

genvar index_2;
generate for(index_2 = 0; index_2 < 3; index_2 = index_2 + 1) begin: Stage_2_Adders
uuu_fp18_add adder(
    .clk(clk),
    .rst_n(rst_n),

    .en(stage_2_en),

    .a(stage_1_sums[index_2]),
    .b(stage_1_sums[index_2+2]),
    .sum(stage_2_sums[index_2])
);
end endgenerate

genvar index_3;
generate for(index_3 = 0; index_3 < 3; index_3 = index_3 + 1) begin: Stage_3_Subtracters

reg [17:0] old_sum;

always @(posedge clk) begin
    if(~rst_n) begin
        old_sum <= 18'b0;
    end else if(stage_3_en) begin
        old_sum <= stage_2_sums[index_3];
    end
end

uus_fp18_sub subtracter(
    .clk(clk),
    .rst_n(rst_n),

    .en(stage_3_en),

    .a(stage_2_sums[index_3]),
    .b(old_sum),
    .diff(differences[index_3*19+18:index_3*19])
);
end endgenerate
endmodule