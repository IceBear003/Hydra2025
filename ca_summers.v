`include "usu_fp18_acc.v"
module ca_summers(
    input clk,
    input rst_n,

    input clear,
    input en,

    input [3*19-1:0] subtraction_flat,

    output reg next_en,
    output [3*18-1:0] summation_flat
);

always @(posedge clk) begin
    if(~rst_n) begin
        next_en <= 0;
    end else begin
        next_en <= en;
    end
end

genvar i;
generate for(i = 0; i < 3; i = i + 1) begin: Summer
    wire [18:0] subtraction = subtraction_flat[i*19+18:i*19];
    wire [17:0] summation;
    assign summation_flat[i*18+17:i*18] = summation;
        
    usu_fp18_acc summer(
        .clk(clk),
        .rst_n(rst_n),
        .en(en),
        .clear(clear),
        .a(summation),
        .b(subtraction),
        .sum(summation)
    );
end endgenerate
endmodule